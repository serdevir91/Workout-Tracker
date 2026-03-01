import 'package:flutter/material.dart';
import '../providers/workout_provider.dart';
import '../utils/exrx_url_matcher.dart';
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
  final Map<String, Map<String, String>> _exerciseLookupCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Pre-fetch exercise info for all exercises
    _prefetchExerciseInfo();
  }

  Future<void> _prefetchExerciseInfo() async {
    for (final ex in widget.exercises) {
      if (!_exerciseLookupCache.containsKey(ex.exercise.name)) {
        final result = await ExrxUrlMatcher.findExercise(ex.exercise.name);
        if (result != null && mounted) {
          _exerciseLookupCache[ex.exercise.name] = {
            'url': result['url'] ?? '',
            'gif_url': result['gif_url'] ?? '',
          };
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
          },
          itemBuilder: (context, index) {
            final activeEx = widget.exercises[index];
            final cached = _exerciseLookupCache[activeEx.exercise.name];

            return ExerciseInfoScreen(
              exerciseName: activeEx.exercise.name,
              exrxUrl: cached?['url'] ?? '',
              gifUrl: cached?['gif_url'] ?? '',
              exerciseId: activeEx.exercise.id,
              targetSets: activeEx.targetSets,
              targetReps: activeEx.targetReps,
              targetWeight: activeEx.targetWeight,
              restSeconds: activeEx.restSeconds,
              isCardio: activeEx.isCardio,
            );
          },
        ),

        // Page indicator dots at bottom
        if (widget.exercises.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.exercises.length, (i) {
                  final isActive = i == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ),

        // Swipe hint overlay (shown briefly)
        if (widget.exercises.length > 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56,
            left: 0,
            right: 0,
            child: Center(
              child: _SwipeHint(
                currentIndex: _currentIndex,
                totalCount: widget.exercises.length,
              ),
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
        ),
      ),
    );
  }
}
