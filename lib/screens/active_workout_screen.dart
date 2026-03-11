import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/exercise_thumbnail.dart';
import '../providers/workout_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/translations.dart';
import '../models/workout_models.dart';
import '../utils/formatters.dart';
import 'exercise_library_screen.dart';
import 'workout_summary_screen.dart';
import 'swipeable_exercise_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _repsControllers = {};

  @override
  void dispose() {
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getWeightController(
    int exerciseId,
    WorkoutProvider provider,
  ) {
    return _weightControllers.putIfAbsent(exerciseId, () {
      final draft = provider.getDraftWeight(exerciseId);
      if (draft.isNotEmpty) return TextEditingController(text: draft);
      // Fall back to plan target weight
      final activeEx = provider.activeExercises
          .where((e) => e.exercise.id == exerciseId)
          .toList();
      if (activeEx.isNotEmpty && activeEx.first.targetWeight > 0) {
        final w = activeEx.first.targetWeight;
        return TextEditingController(
          text: w == w.toInt() ? w.toInt().toString() : w.toStringAsFixed(1),
        );
      }
      return TextEditingController();
    });
  }

  TextEditingController _getRepsController(
    int exerciseId,
    WorkoutProvider provider,
  ) {
    return _repsControllers.putIfAbsent(exerciseId, () {
      final draft = provider.getDraftReps(exerciseId);
      if (draft.isNotEmpty) return TextEditingController(text: draft);
      // Fall back to plan target reps
      final activeEx = provider.activeExercises
          .where((e) => e.exercise.id == exerciseId)
          .toList();
      if (activeEx.isNotEmpty && activeEx.first.targetReps > 0) {
        return TextEditingController(
          text: activeEx.first.targetReps.toString(),
        );
      }
      return TextEditingController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        if (!provider.isWorkoutActive) {
          final t = Translations.of(context);
          return Scaffold(
            body: Center(
              child: Text(
                t.get('no_active_workout'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          );
        }

        // Show set totals plus the richer completion score from the provider.
        int totalPlannedSets = 0;
        int completedSets = 0;
        for (var ex in provider.activeExercises) {
          totalPlannedSets += ex.targetSets > 0
              ? ex.targetSets
              : ex.sets.length;
          completedSets += ex.sets.where((s) => s.completed).length;
        }
        if (totalPlannedSets == 0) totalPlannedSets = 1;
        final completionPercent = provider.completionPercentage;
        final double progress = (completionPercent / 100)
            .clamp(0.0, 1.0)
            .toDouble();

        return Scaffold(
          appBar: AppBar(
            title: Text(provider.activeWorkout!.name),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        provider.isTimerRunning
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        if (provider.isTimerRunning) {
                          provider.pauseTimer();
                        } else {
                          provider.resumeTimer();
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    ValueListenableBuilder<int>(
                      valueListenable: provider.elapsedSecondsNotifier,
                      builder: (_, elapsed, _) => Text(
                        formatDuration(elapsed),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Progress Bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$completedSets / $totalPlannedSets sets',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${completionPercent.round()}%',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Theme.of(context).colorScheme.outline,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.secondary,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              // Rest Timer
              ValueListenableBuilder<int>(
                valueListenable: provider.restTimerNotifier,
                builder: (_, restSeconds, _) {
                  if (restSeconds <= 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rest Timer: ${formatDuration(restSeconds)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          onPressed: () => provider.stopRestTimer(),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: provider.activeExercises.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.activeExercises.length,
                        itemBuilder: (context, index) =>
                            _buildExerciseCard(context, provider, index),
                      ),
              ),
              _buildBottomBar(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 48,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'Add exercise',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap the button below to add an exercise',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WorkoutProvider provider,
    int index,
  ) {
    final activeEx = provider.activeExercises[index];
    final exerciseId = activeEx.exercise.id!;
    // For manual additions, the last one is active. If from plan, all are active simultaneously.
    final isActive = true; // Make all active so user can add sets directly
    final isCardio = activeEx.isCardio; // Pre-computed at exercise creation
    final isCardioTimerActive = provider.isCardioTimerActive(exerciseId);
    final lastRecord = provider.getLastExerciseStats(activeEx.exercise.name);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SwipeableExerciseScreen(
                                  exercises: provider.activeExercises,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              ExerciseThumbnail(
                                exerciseName: activeEx.exercise.name,
                                size: 48,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  activeEx.exercise.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.play_circle_outline,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Color(0xFFFF6B6B),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHigh,
                              title: Text(
                                Translations.of(context).get('delete'),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              content: Text(
                                Translations.of(
                                  context,
                                ).get('delete_workout_confirm'),
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(
                                    Translations.of(context).get('cancel'),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _weightControllers[exerciseId]?.dispose();
                                    _weightControllers.remove(exerciseId);
                                    _repsControllers[exerciseId]?.dispose();
                                    _repsControllers.remove(exerciseId);
                                    provider.deleteExercise(exerciseId);
                                    Navigator.pop(ctx);
                                  },
                                  child: Text(
                                    Translations.of(context).get('delete'),
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B6B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Sets table
            if (activeEx.sets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          if (!isCardio) ...[
                            SizedBox(
                              width: 40,
                              child: Text(
                                Translations.of(context).get('sets'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${Translations.of(context).get('weight')} (${context.read<SettingsProvider>().unit})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 60,
                              child: Text(
                                Translations.of(context).get('reps'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ] else ...[
                            SizedBox(
                              width: 40,
                              child: Text(
                                Translations.of(context).get('sets'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Duration (Minutes)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    ...activeEx.sets.map(
                      (s) => ClipRect(
                        child: Dismissible(
                        key: Key('set_${s.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: const Color(0xFFFF6B6B),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          provider.deleteSet(exerciseId, s.id!);
                        },
                        child: InkWell(
                          onTap: () {
                            _showEditSetDialog(
                              context,
                              provider,
                              exerciseId,
                              s,
                              isCardio: isCardio,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    '${s.setNumber}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (!isCardio) ...[
                                  Expanded(
                                    child: Text(
                                      context
                                          .read<SettingsProvider>()
                                          .formatWeight(s.weight),
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 60,
                                    child: Text(
                                      '${s.reps}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: Text(
                                      '${s.reps} min',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            ],

            // Add set input
            if (isActive) ...[
              const SizedBox(height: 12),
              if (!isCardio) ...[
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          controller: _getWeightController(
                            exerciseId,
                            provider,
                          ),
                          onChanged: (val) =>
                              provider.setDraftWeight(exerciseId, val),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: context.read<SettingsProvider>().unit,
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextField(
                          controller: _getRepsController(exerciseId, provider),
                          onChanged: (val) =>
                              provider.setDraftReps(exerciseId, val),
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: Translations.of(context).get('reps'),
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            isDense: false,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHigh,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () =>
                          _addSet(context, provider, exerciseId, false, 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '+ Set',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (lastRecord != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'Last Session: ${lastRecord['sets']} Sets (Max: ${context.read<SettingsProvider>().formatWeight((lastRecord['max_weight'] as num).toDouble())}, ${lastRecord['total_reps']} ${Translations.of(context).get('reps')})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ] else
                ValueListenableBuilder<Map<int, int>>(
                  valueListenable: provider.exerciseTimersNotifier,
                  builder: (_, exerciseTimers, _) {
                    final elapsed = exerciseTimers[exerciseId] ?? 0;
                    return Column(
                      children: [
                        // Cardio timer display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isCardioTimerActive
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withValues(alpha: 0.1)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isCardioTimerActive
                                  ? Theme.of(context).colorScheme.secondary
                                        .withValues(alpha: 0.4)
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer,
                                color: isCardioTimerActive
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatDuration(elapsed),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isCardioTimerActive
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.onSurface,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Start/Stop timer button
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  isCardioTimerActive
                                      ? Icons.stop
                                      : Icons.play_arrow,
                                ),
                                onPressed: () {
                                  if (isCardioTimerActive) {
                                    provider.stopCardioTimer(exerciseId);
                                  } else {
                                    provider.startCardioTimer(exerciseId);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isCardioTimerActive
                                      ? const Color(0xFFFF6B6B)
                                      : Theme.of(context).colorScheme.secondary,
                                  foregroundColor: isCardioTimerActive
                                      ? Colors.white
                                      : Theme.of(context).colorScheme.onSurface,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                label: Text(
                                  isCardioTimerActive ? 'Stop' : 'Start',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Save duration button
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                onPressed: elapsed > 0
                                    ? () {
                                        // Stop timer if running
                                        if (isCardioTimerActive) {
                                          provider.stopCardioTimer(exerciseId);
                                        }
                                        _addSet(
                                          context,
                                          provider,
                                          exerciseId,
                                          true,
                                          elapsed,
                                        );
                                        // Reset the elapsed counter for next cardio set
                                        provider.resetCardioElapsed(exerciseId);
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.outline,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                label: Text('Save (${elapsed ~/ 60} min)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _addSet(
    BuildContext context,
    WorkoutProvider provider,
    int exerciseId,
    bool isCardio,
    int elapsedMins,
  ) {
    if (isCardio) {
      // Save duration as reps, weight = 0
      int mins = elapsedMins ~/ 60;
      if (mins <= 0) mins = 1; // at least 1 min
      provider.addSet(exerciseId, 0, mins);
      return;
    }

    final weight =
        double.tryParse(_getWeightController(exerciseId, provider).text) ?? 0;
    final reps =
        int.tryParse(_getRepsController(exerciseId, provider).text) ?? 0;
    if (reps <= 0) return;

    provider.addSet(exerciseId, weight, reps);
    // Use plan's rest seconds for this exercise, fallback to 60
    final activeEx = provider.activeExercises.firstWhere(
      (e) => e.exercise.id == exerciseId,
      orElse: () => ActiveExercise(
        exercise: Exercise(
          id: 0,
          workoutId: 0,
          name: '',
          startTime: DateTime.now(),
          exerciseOrder: 0,
        ),
        sets: [],
      ),
    );
    provider.startRestTimer(
      activeEx.restSeconds > 0 ? activeEx.restSeconds : 60,
    );
    // DO NOT clear controllers, so they act as a sticky default for the next set!
  }

  void _showEditSetDialog(
    BuildContext context,
    WorkoutProvider provider,
    int exerciseId,
    ExerciseSet s, {
    bool isCardio = false,
  }) {
    if (isCardio) {
      // Cardio: show duration (minutes) field only
      final durationController = TextEditingController(text: s.reps.toString());
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          title: Text(
            'Edit Set ${s.setNumber}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: TextField(
            controller: durationController,
            keyboardType: TextInputType.number,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: 'Duration (min)',
              labelStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.timer,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final newDuration = int.tryParse(durationController.text) ?? 0;
                if (newDuration > 0) {
                  provider.updateSet(exerciseId, s.id!, 0, newDuration);
                }
                Navigator.pop(ctx);
              },
              child: Text(
                'Update',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }

    // Strength: show weight + reps fields
    final weightController = TextEditingController(
      text: s.weight == s.weight.toInt()
          ? s.weight.toInt().toString()
          : s.weight.toString(),
    );
    final repsController = TextEditingController(text: s.reps.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        title: Text(
          'Edit Set ${s.setNumber}',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${Translations.of(context).get('weight')} (${context.read<SettingsProvider>().unit})',
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  labelText: Translations.of(context).get('reps'),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              Translations.of(context).get('cancel'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final newWeight = double.tryParse(weightController.text) ?? 0;
              final newReps = int.tryParse(repsController.text) ?? 0;
              if (newReps > 0) {
                provider.updateSet(exerciseId, s.id!, newWeight, newReps);
              }
              Navigator.pop(ctx);
            },
            child: Text(
              'Update',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WorkoutProvider provider) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cancel button - compact icon-only
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHigh,
                      title: Text(
                        Translations.of(context).get('cancel'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      content: Text(
                        Translations.of(context).get('delete_workout_confirm'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(Translations.of(context).get('cancel')),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.cancelWorkout();
                            Navigator.pop(context);
                          },
                          child: Text(
                            Translations.of(context).get('delete'),
                            style: const TextStyle(color: Color(0xFFFF6B6B)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.close, size: 22),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHigh,
                  foregroundColor: const Color(0xFFFF6B6B),
                  side: const BorderSide(color: Color(0xFFFF6B6B)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Add Exercise button - prominent center
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<Map<String, String>>(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ExerciseLibraryScreen(pickMode: true),
                    ),
                  );
                  if (result != null &&
                      result['name']!.isNotEmpty &&
                      context.mounted) {
                    provider.addExercise(
                      result['name']!,
                      muscleGroup: result['muscle_group'],
                    );
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: Text(Translations.of(context).get('add_exercise')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Finish button - green, prominent
            ElevatedButton.icon(
              onPressed: () => _finishWorkout(context, provider),
              icon: const Icon(Icons.check_circle, size: 20),
              label: Text(Translations.of(context).get('finish')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.black,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishWorkout(BuildContext context, WorkoutProvider provider) {
    // Gather summary data while the workout is still active
    final workoutName = provider.activeWorkout?.name ?? 'Workout';
    final duration = provider.workoutElapsedSeconds;
    int setsCompleted = 0;
    double volume = 0;
    for (var ex in provider.activeExercises) {
      setsCompleted += ex.sets.length;
      for (var s in ex.sets) {
        if (s.weight > 0) volume += (s.weight * s.reps);
      }
    }
    // Estimated calories: roughly 5.5 kcal per min (very basic estimate)
    final calories = (duration / 60.0) * 5.5;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        title: Text(
          Translations.of(context).get('finish'),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          'Total duration: ${formatDuration(provider.workoutElapsedSeconds)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              Translations.of(context).get('cancel'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutSummaryScreen(
                    name: workoutName,
                    duration: duration,
                    setsCompleted: setsCompleted,
                    volume: volume,
                    calories: calories.toInt(),
                    completionPercentage: provider.completionPercentage,
                  ),
                ),
              );

              // Fire and forget
              provider.finishWorkout();
            },
            child: Text(
              Translations.of(context).get('finish'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
