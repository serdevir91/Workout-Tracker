import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../utils/exercise_db.dart';
import 'exercise_info_screen.dart';

/// Wrapper that enables swipe navigation between exercises during a workout.
/// Swipe right → next exercise, swipe left → previous exercise.
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
  State<SwipeableExerciseScreen> createState() => _SwipeableExerciseScreenState();
}

class _SwipeableExerciseScreenState extends State<SwipeableExerciseScreen> {
  late PageController _pageController;
  late int _currentIndex;

  // Cache exercise lookup results to avoid repeated async lookups
  final Map<String, Map<String, dynamic>> _exerciseLookupCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Pre-fetch exercise info for all exercises
    _prefetchExerciseInfo();
    // Notify provider of the initial viewing exercise
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkoutProvider>().setCurrentViewingExercise(widget.initialIndex);
      }
    });
  }

  Future<void> _prefetchExerciseInfo() async {
    for (final ex in widget.exercises) {
      if (!_exerciseLookupCache.containsKey(ex.exercise.name)) {
        final result = await ExerciseDB.findExercise(ex.exercise.name);
        if (result != null && mounted) {
          _exerciseLookupCache[ex.exercise.name] = result;
          // Trigger rebuild so pages get their info
          setState(() {});
        }
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
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.exercises.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            context.read<WorkoutProvider>().setCurrentViewingExercise(index);
          },
          itemBuilder: (context, index) {
            final activeEx = widget.exercises[index];
            final cached = _exerciseLookupCache[activeEx.exercise.name];
            final images = (cached?['images'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];

            return ExerciseInfoScreen(
              exerciseName: activeEx.exercise.name,
              imageUrls: images,
              exerciseId: activeEx.exercise.id,
              targetSets: activeEx.targetSets,
              targetReps: activeEx.targetReps,
              targetWeight: activeEx.targetWeight,
              restSeconds: activeEx.restSeconds,
              isCardio: activeEx.isCardio,
            );
          },
        ),

        // Swipe hint overlay — right below the "0/3 sets" badge
        if (widget.exercises.length > 1)
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 42,
            right: 16,
            child: _SwipeHint(
              currentIndex: _currentIndex,
              totalCount: widget.exercises.length,
            ),
          ),
      ],
    );
  }
}

/// A small hint badge showing exercise position (e.g., "2 / 5").
class _SwipeHint extends StatelessWidget {
  final int currentIndex;
  final int totalCount;

  const _SwipeHint({required this.currentIndex, required this.totalCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Text(
        '${currentIndex + 1} / $totalCount',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
