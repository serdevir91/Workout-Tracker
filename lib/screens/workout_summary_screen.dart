import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/formatters.dart';
import '../providers/settings_provider.dart';
import '../l10n/translations.dart';
import '../services/startup_flow_service.dart';
import '../services/store_launcher.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final String name;
  final int duration;
  final int setsCompleted;
  final double volume;
  final int calories;
  final double completionPercentage;
  final bool showRateReviewPrompt;

  const WorkoutSummaryScreen({
    super.key,
    required this.name,
    required this.duration,
    required this.setsCompleted,
    required this.volume,
    required this.calories,
    required this.completionPercentage,
    this.showRateReviewPrompt = false,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  bool _rateDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showRateReviewPromptIfNeeded();
    });
  }

  Future<void> _showRateReviewPromptIfNeeded() async {
    if (_rateDialogShown || !widget.showRateReviewPrompt || !mounted) {
      return;
    }

    _rateDialogShown = true;
    final t = Translations.of(context);
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          t.get('rate_review_title'),
          style: TextStyle(color: Theme.of(dialogContext).colorScheme.onSurface),
        ),
        content: Text(
          t.get('rate_review_desc'),
          style: TextStyle(
            color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('never'),
            child: Text(t.get('rate_review_never')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('later'),
            child: Text(t.get('rate_review_later')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop('rate'),
            child: Text(t.get('rate_review_star')),
          ),
        ],
      ),
    );

    if (action == null || !mounted) {
      return;
    }

    if (action == 'never') {
      await const StartupFlowService().setNeverShowRateReview(true);
      return;
    }

    if (action == 'later') {
      return;
    }

    final opened = await StoreLauncher.openCurrentAppReviewPage();
    if (opened) {
      await const StartupFlowService().markRateReviewCompleted();
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t.get('rate_review_open_failed'),
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final t = Translations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              Text(
                t.get('workout_completed'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 60),
              _buildStatRow(context, t.get('total_duration'), formatDuration(widget.duration), Icons.timer),
              _buildStatRow(context, t.get('total_volume'), settings.formatWeight(widget.volume), Icons.fitness_center),
              _buildStatRow(context, t.get('total_sets'), '${widget.setsCompleted}', Icons.check_circle),
              _buildStatRow(context, 'Completion', '${widget.completionPercentage.round()}%', Icons.show_chart),
              _buildStatRow(context, 'Calories', '${widget.calories} kcal', Icons.local_fire_department),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(t.get('home'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
