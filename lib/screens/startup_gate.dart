import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../monetization/app_flavor.dart';
import '../providers/monetization_provider.dart';
import '../services/startup_flow_service.dart';
import '../widgets/startup_offer_sheet.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'paywall_screen.dart';

class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  final StartupFlowService _startupFlowService = const StartupFlowService();

  bool _isLoading = true;
  bool _showOnboarding = false;
  int _launchCount = 0;
  bool _neverShowStartupOffer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prepare();
    });
  }

  Future<void> _prepare() async {
    final snapshot = await _startupFlowService.prepare();
    if (!mounted) {
      return;
    }

    setState(() {
      _launchCount = snapshot.launchCount;
      _neverShowStartupOffer = snapshot.neverShowStartupOffer;
      _showOnboarding = !snapshot.hasSeenOnboarding;
      _isLoading = false;
    });

    if (!_showOnboarding) {
      await _showStartupOfferIfNeeded();
    }
  }

  Future<void> _completeOnboarding() async {
    await _startupFlowService.markOnboardingSeen();
    if (!mounted) {
      return;
    }
    setState(() => _showOnboarding = false);
    await _showStartupOfferIfNeeded();
  }

  Future<void> _showStartupOfferIfNeeded() async {
    final monetization = context.read<MonetizationProvider>();
    if (monetization.isSoftOpenMode) {
      return;
    }

    for (var i = 0; i < 15 && !monetization.initialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) {
        return;
      }
    }

    final isPremiumUnlocked =
        monetization.isPremiumUnlocked ||
        monetization.flavor == AppFlavor.pro ||
        monetization.isProBuild;

    if (!_startupFlowService.shouldShowStartupOffer(
      launchCount: _launchCount,
      isPremiumUnlocked: isPremiumUnlocked,
      neverShowStartupOffer: _neverShowStartupOffer,
    )) {
      return;
    }

    if (!mounted) {
      return;
    }

    final result = await showStartupOfferSheet(context);
    if (result == null || !mounted) {
      return;
    }

    if (result.neverShowAgain) {
      await _startupFlowService.setNeverShowStartupOffer(true);
      _neverShowStartupOffer = true;
    }

    if (!mounted) {
      return;
    }

    if (result.openPremium) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PaywallScreen(
            reason:
                'Unlock Premium to remove ads, create unlimited routines, and access advanced statistics.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    return const HomeScreen();
  }
}
