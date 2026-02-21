import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../utils/formatters.dart';
import '../utils/exrx_url_matcher.dart';
import 'exercise_info_screen.dart';
import 'exercise_library_screen.dart';

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

  TextEditingController _getWeightController(int exerciseId) {
    return _weightControllers.putIfAbsent(exerciseId, () => TextEditingController());
  }

  TextEditingController _getRepsController(int exerciseId) {
    return _repsControllers.putIfAbsent(exerciseId, () => TextEditingController());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        if (!provider.isWorkoutActive) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: Text('No active workout', style: TextStyle(color: Colors.white))),
          );
        }

        // Calculate progress %
        int totalExercises = provider.activeExercises.isEmpty ? 1 : provider.activeExercises.length;
        int completedExercises = 0;
        for (var ex in provider.activeExercises) {
           if (ex.sets.isNotEmpty) {
              completedExercises++;
           }
        }
        double progress = completedExercises / totalExercises;
        if (progress > 1.0) progress = 1.0;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(provider.activeWorkout!.name),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  border: Border.all(color: const Color(0xFF222222)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        provider.isTimerRunning ? Icons.pause : Icons.play_arrow,
                        color: const Color(0xFF00D4AA),
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
                    Text(
                      formatDuration(provider.workoutElapsedSeconds),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF00D4AA),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Workout Progress', style: TextStyle(color: Color(0xFFA0A0C0), fontSize: 13)),
                         Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xFF222222),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D4AA)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
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
          Icon(Icons.add_circle_outline, size: 48, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          const Text(
            'Add exercise',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFA0A0C0)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the button below to add an exercise',
            style: TextStyle(color: Color(0xFF6B6B8D)),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, WorkoutProvider provider, int index) {
    final activeEx = provider.activeExercises[index];
    final exerciseId = activeEx.exercise.id!;
    // For manual additions, the last one is active. If from plan, all are active simultaneously.
    final isActive = true; // Make all active so user can add sets directly
    final elapsed = provider.exerciseElapsedSeconds[exerciseId] ?? 0;
    final exName = activeEx.exercise.name.toLowerCase();
    final isCardio = exName.contains('bike') || exName.contains('run') || exName.contains('treadmill') || exName.contains('bisiklet') || exName.contains('koşu') || exName.contains('cardio');

    return Card(
      color: const Color(0xFF0F0F12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF222222)),
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
                          onTap: () async {
                            final result = await ExrxUrlMatcher.findExercise(activeEx.exercise.name);
                            if (!context.mounted) return;
                            if (result != null && result['url']!.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExerciseInfoScreen(
                                    exerciseName: activeEx.exercise.name,
                                    exrxUrl: result['url']!,
                                    gifUrl: result['gif_url'] ?? '',
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No ExRx info found for this exercise')),
                              );
                            }
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeEx.exercise.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                              const Icon(Icons.play_circle_outline, color: Color(0xFF00D4AA), size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF6B6B)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                           showDialog(
                             context: context,
                             builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF0F0F12),
                                title: const Text('Delete Exercise?', style: TextStyle(color: Colors.white)),
                                content: const Text('All sets will be lost.', style: TextStyle(color: Color(0xFFA0A0C0))),
                                actions: [
                                   TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                   TextButton(
                                      onPressed: () {
                                         provider.deleteExercise(exerciseId);
                                         Navigator.pop(ctx);
                                      },
                                      child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
                                   ),
                                ],
                             ),
                           );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeEx.sets.isNotEmpty ? const Color(0xFF00D4AA).withValues(alpha: 0.15) : const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: activeEx.sets.isNotEmpty ? const Color(0xFF00D4AA).withValues(alpha: 0.3) : const Color(0xFF222222)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activeEx.sets.isNotEmpty ? Icons.check_circle : Icons.timer,
                        size: 14,
                        color: activeEx.sets.isNotEmpty ? const Color(0xFF00D4AA) : const Color(0xFFA0A0C0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activeEx.sets.isNotEmpty ? '${activeEx.sets.length} sets' : formatDuration(elapsed),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: activeEx.sets.isNotEmpty ? const Color(0xFF00D4AA) : const Color(0xFFA0A0C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Sets table
            if (activeEx.sets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          if (!isCardio) ...[
                            SizedBox(width: 40, child: Text('Set', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA0A0C0)))),
                            Expanded(child: Text('Weight (kg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA0A0C0)))),
                            SizedBox(width: 60, child: Text('Reps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA0A0C0)))),
                          ] else ...[
                            SizedBox(width: 40, child: Text('Set', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA0A0C0)))),
                            Expanded(child: Text('Duration (Minutes)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFA0A0C0)))),
                          ]
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF222222)),
                    ...activeEx.sets.map((s) => Dismissible(
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
                           if (!isCardio) {
                             _getWeightController(exerciseId).text = s.weight == s.weight.toInt() ? s.weight.toInt().toString() : s.weight.toString();
                             _getRepsController(exerciseId).text = s.reps.toString();
                           }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(width: 40, child: Text('${s.setNumber}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white))),
                              if (!isCardio) ...[
                                Expanded(child: Text('${s.weight} kg', style: const TextStyle(color: Colors.white))),
                                SizedBox(width: 60, child: Text('${s.reps}', style: const TextStyle(color: Colors.white))),
                              ] else ...[
                                Expanded(child: Text('${s.reps} min', style: const TextStyle(color: Colors.white))),
                              ]
                            ],
                          ),
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            // Add set input
            if (isActive) ...[
              const SizedBox(height: 12),
              if (!isCardio)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _getWeightController(exerciseId),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'kg',
                            hintStyle: const TextStyle(color: Color(0xFF6B6B8D)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            filled: true,
                            fillColor: const Color(0xFF111111),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF222222))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF222222))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _getRepsController(exerciseId),
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Reps',
                            hintStyle: const TextStyle(color: Color(0xFF6B6B8D)),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            filled: true,
                            fillColor: const Color(0xFF111111),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF222222))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF222222))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addSet(context, provider, exerciseId, false, elapsed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('+ Set'),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        onPressed: () => _addSet(context, provider, exerciseId, true, elapsed),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00D4AA),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: Text('Save Duration (${(elapsed~/60)} min)'),
                      ),
                    ),
                  ],
                )
            ],
          ],
        ),
      ),
    );
  }

  void _addSet(BuildContext context, WorkoutProvider provider, int exerciseId, bool isCardio, int elapsedMins) {
    if (isCardio) {
      // Save duration as reps, weight = 0
      int mins = elapsedMins ~/ 60;
      if (mins <= 0) mins = 1; // at least 1 min
      provider.addSet(exerciseId, 0, mins);
      return;
    }

    final weight = double.tryParse(_getWeightController(exerciseId).text) ?? 0;
    final reps = int.tryParse(_getRepsController(exerciseId).text) ?? 0;
    if (reps <= 0) return;

    provider.addSet(exerciseId, weight, reps);
    // DO NOT clear controllers, so they act as a sticky default for the next set!
  }

  Widget _buildBottomBar(BuildContext context, WorkoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showExercisePicker(context, provider),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Exercise'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF222222)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final name = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExerciseLibraryScreen(pickMode: true),
                ),
              );
              if (name != null && name.isNotEmpty && context.mounted) {
                provider.addExercise(name);
              }
            },
            icon: const Icon(Icons.menu_book, size: 20),
            label: const Text('Library'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A2E),
              foregroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              side: const BorderSide(color: Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _finishWorkout(context, provider),
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text('Finish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4AA),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker(BuildContext context, WorkoutProvider provider) {
    final exercises = [
      'Exercise Bike',
      'Barbell Bench Press',
      '30° Incline DB Bench Press',
      'Seated Pec Fly',
      'Machine Shoulder Press',
      'Cable Lateral Raise',
      'Incline Prone DB Row',
      'Triceps Pushdown',
      'Wide Grip Lat Pulldown',
      'Bent-over Dumbbell Row',
      'Narrow Grip Seated Row',
      'Standing Rope Pullover',
      'Lat Pulldown Machine',
      'Standing Dumbbell Curls',
      'Scott Dumbbell Curl',
      'Air Squats',
      'Narrow Stance Leg Press',
      'Seated Leg Curls',
      'Seated Calf Raises',
      'Romanian Deadlift',
      'Horizontal Barbell Bench Press',
    ];

    final customController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: customController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Custom exercise name',
                        hintStyle: const TextStyle(color: Color(0xFF6B6B8D)),
                        filled: true,
                        fillColor: const Color(0xFF111111),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF222222))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (customController.text.trim().isNotEmpty) {
                        provider.addExercise(customController.text.trim());
                        Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF6C63FF),
                       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF222222), height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: exercises.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const Icon(Icons.fitness_center, size: 20, color: Color(0xFF6C63FF)),
                  title: Text(exercises[i], style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    provider.addExercise(exercises[i]);
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishWorkout(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F0F12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF222222))),
        title: const Text('Finish Workout', style: TextStyle(color: Colors.white)),
        content: Text(
          'Total duration: ${formatDuration(provider.workoutElapsedSeconds)}\nDo you want to finish?',
          style: const TextStyle(color: Color(0xFFA0A0C0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFFA0A0C0))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.finishWorkout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Finish', style: TextStyle(color: Color(0xFF00D4AA))),
          ),
        ],
      ),
    );
  }
}
