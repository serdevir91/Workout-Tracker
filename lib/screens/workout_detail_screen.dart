import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/translations.dart';
import '../utils/exrx_url_matcher.dart';
import '../utils/formatters.dart';
import '../widgets/exercise_thumbnail.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  Map<String, bool> _cardioMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<WorkoutProvider>();
    final data = await provider.loadWorkoutDetail(widget.workoutId);
    if (!mounted) return;

    // Build cardio map for all exercises using library muscle_group
    final exercises = data['exercises'] as List<Map<String, dynamic>>? ?? [];
    final cardioMap = <String, bool>{};
    for (final exData in exercises) {
      final name = exData['exercise'].name as String;
      if (!cardioMap.containsKey(name)) {
        final muscleGroup = await ExrxUrlMatcher.findMuscleGroup(name);
        cardioMap[name] = ActiveExercise.detectCardio(name, muscleGroup: muscleGroup);
      }
    }

    if (!mounted) return;
    setState(() {
      _data = data;
      _cardioMap = cardioMap;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)),
      );
    }

    if (_data == null || _data!['workout'] == null) {
      return Scaffold(
        appBar: AppBar(title: Text(Translations.of(context).get('workout_details'))),
        body: Center(child: Text('Workout not found', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
      );
    }

    final workout = _data!['workout'];
    final exercises = _data!['exercises'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Color(0xFFFF6B6B)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text('Delete Workout', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  content: Text('Are you sure you want to delete "${workout.name}"? This action cannot be undone.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        context.read<WorkoutProvider>().deleteWorkout(widget.workoutId);
                        Navigator.pop(ctx);
                        Navigator.pop(context); // Go back after delete
                      },
                      child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(workout),
          const SizedBox(height: 24),
          Text(
            'Exercises',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          ...exercises.map((exData) => _buildExerciseCard(exData)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(dynamic workout) {
    final duration = workout.totalDuration ?? 0;
    final calories = workout.calories ?? 0;
    
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outline)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(child: _buildSummaryColumn('Date', formatShortDate(workout.startTime), Icons.calendar_today, Theme.of(context).colorScheme.primary)),
            Expanded(child: _buildSummaryColumn('Time', formatTime(workout.startTime), Icons.access_time, Theme.of(context).colorScheme.secondary)),
            Expanded(child: _buildSummaryColumn('Duration', formatDuration(duration), Icons.timer, Theme.of(context).colorScheme.secondary)),
            if (calories > 0)
              Expanded(child: _buildSummaryColumn('Calories', '${calories.toInt()}', Icons.local_fire_department, Colors.orange)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exData) {
    final exercise = exData['exercise'];
    final sets = exData['sets'] as List<dynamic>;
    final isCardio = _cardioMap[exercise.name] ?? ActiveExercise.detectCardio(exercise.name);

    // Calculate total volume for this exercise
    double volume = 0;
    int totalDuration = 0;
    for (var s in sets) {
      if (isCardio) {
        totalDuration += (s.reps as int);
      } else {
        volume += (s.weight * s.reps);
      }
    }

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outline)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      ExerciseThumbnail(exerciseName: exercise.name, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  isCardio ? '$totalDuration min' : context.read<SettingsProvider>().formatWeight(volume),
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sets.isEmpty)
              Text('No sets completed', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontStyle: FontStyle.italic))
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          if (isCardio) ...[
                            Expanded(flex: 1, child: Text('#', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Duration', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12))),
                          ] else ...[
                            Expanded(flex: 1, child: Text('Set', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Weight', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12))),
                            Expanded(flex: 2, child: Text('Reps', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12))),
                          ],
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).colorScheme.outline),
                    ...sets.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          if (isCardio) ...[
                            Expanded(flex: 1, child: Text('${s.setNumber}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
                            Expanded(flex: 2, child: Text('${s.reps} min', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                          ] else ...[
                            Expanded(flex: 1, child: Text('${s.setNumber}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
                            Expanded(flex: 2, child: Text(context.read<SettingsProvider>().formatWeight(s.weight), style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                            Expanded(flex: 2, child: Text('${s.reps}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface))),
                          ],
                        ],
                      ),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
