import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/app_permission_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final AppPermissionService _permissionService = const AppPermissionService();

  int _pageIndex = 0;
  bool _requestingPermissions = false;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.calendar_month_rounded,
      title: 'Plan your week',
      description:
          'Create routines for each training day and keep your calendar aligned with the workouts you actually do.',
    ),
    _OnboardingPageData(
      icon: Icons.timer_outlined,
      title: 'Track active workouts',
      description:
          'Run live sessions, follow rest timers and keep workout notifications visible while the app is in the background.',
    ),
    _OnboardingPageData(
      icon: Icons.analytics_outlined,
      title: 'Read your progress',
      description:
          'See body progress, session trends, body composition and more realistic 1RM estimates from your logged sets.',
    ),
    _OnboardingPageData(
      icon: Icons.security_outlined,
      title: 'Protect your data',
      description:
          'Backup and restore your training data, then choose whether you want the free build, Premium or the Pro app.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_requestingPermissions) {
      return;
    }

    setState(() => _requestingPermissions = true);
    try {
      final result = await _permissionService.requestInitialPermissions();
      if (!mounted) {
        return;
      }

      final permanentlyDenied = [
        result.notification,
        result.storage,
      ].contains(PermissionRequestState.permanentlyDenied);

      if (permanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Some permissions were permanently denied. You can enable them later in system settings.',
            ),
            action: SnackBarAction(
              label: 'Open settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }

      await widget.onComplete();
    } finally {
      if (mounted) {
        setState(() => _requestingPermissions = false);
      }
    }
  }

  Future<void> _skip() => widget.onComplete();

  Future<void> _nextPage() async {
    if (_pageIndex == _pages.length - 1) {
      await _finish();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _pageIndex == _pages.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  Text(
                    '${_pageIndex + 1}/${_pages.length}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _pageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return _OnboardingPage(
                      data: page,
                      isLastPage: index == _pages.length - 1,
                    );
                  },
                ),
              ),
              Row(
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == _pageIndex ? 26 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: index == _pageIndex
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_pageIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _requestingPermissions ? null : _nextPage,
                      child: Text(
                        isLastPage
                            ? (_requestingPermissions
                                ? 'Requesting permissions...'
                                : 'Get Started')
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.isLastPage,
  });

  final _OnboardingPageData data;
  final bool isLastPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.18),
                theme.colorScheme.secondary.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  data.icon,
                  size: 34,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                data.title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                data.description,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLastPage ? 'What happens next' : 'What you can do here',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ...data.bullets.map(
                  (bullet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            bullet,
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 14,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  List<String> get bullets {
    switch (title) {
      case 'Plan your week':
        return const [
          'Create workout routines for specific days.',
          'See upcoming training days inside the dashboard calendar.',
        ];
      case 'Track active workouts':
        return const [
          'Keep elapsed workout time running across screens.',
          'Rest timer notifications stay visible while you switch apps.',
        ];
      case 'Read your progress':
        return const [
          'Review volume, session history and body progress.',
          'See body fat and lean mass when measurements are complete.',
        ];
      default:
        return const [
          'Notification permission helps the workout timer stay visible.',
          'Storage access is requested only on Android versions that still need it.',
        ];
    }
  }
}
