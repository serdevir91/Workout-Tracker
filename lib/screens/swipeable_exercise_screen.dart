import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../utils/exercise_db.dart';
import 'exercise_info_screen.dart';

/// Wrapper that enables swipe navigation between exercises during a workout.
/// Swipe right -> next exercise, swipe left -> previous exercise.
/// Each page is a full ExerciseInfoScreen with its own state.
class SwipeableExerciseScreen extends StatefulWidget {
  final List<ActiveExercise> exercises;
  final int initialIndex;

  const SwipeableExerciseScreen({
    super.key,
    required this.exercises,
    required this.initialIndex,
  });

  @override
  State<SwipeableExerciseScreen> createState() =>
      _SwipeableExerciseScreenState();
}

class _SwipeableExerciseScreenState extends State<SwipeableExerciseScreen> {
  late PageController _pageController;

  // Cache exercise lookup results to avoid repeated async lookups.
  final Map<String, Map<String, dynamic>> _exerciseLookupCache = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _prefetchExerciseInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkoutProvider>().setCurrentViewingExercise(
          widget.initialIndex,
        );
      }
    });
  }

  Future<void> _prefetchExerciseInfo() async {
    for (final ex in widget.exercises) {
      if (_exerciseLookupCache.containsKey(ex.exercise.name)) continue;
      final result = await ExerciseDB.findExercise(ex.exercise.name);
      if (result != null && mounted) {
        _exerciseLookupCache[ex.exercise.name] = result;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.exercises.length,
      onPageChanged: (index) {
        context.read<WorkoutProvider>().setCurrentViewingExercise(index);
      },
      itemBuilder: (context, index) {
        final activeEx = widget.exercises[index];
        final cached = _exerciseLookupCache[activeEx.exercise.name];
        final images =
            (cached?['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        return ExerciseInfoScreen(
          exerciseName: activeEx.exercise.name,
          imageUrls: images,
          exerciseId: activeEx.exercise.id,
          targetSets: activeEx.targetSets,
          targetReps: activeEx.targetReps,
          targetWeight: activeEx.targetWeight,
          restSeconds: activeEx.restSeconds,
          currentExerciseIndex: index,
          totalExerciseCount: widget.exercises.length,
          isCardio: activeEx.isCardio,
        );
      },
    );
  }
}
