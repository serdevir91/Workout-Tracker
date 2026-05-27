import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/models/workout_models.dart';
import 'package:workout_tracker/utils/one_rm_calculator.dart';

void main() {
  group('OneRmCalculator', () {
    test('ignores sets above rep threshold', () {
      expect(OneRmCalculator.estimate(100, 12), isNull);
    });

    test('uses lower of Epley and Brzycki', () {
      final value = OneRmCalculator.estimate(100, 8);
      expect(value, isNotNull);

      final epley = 100 * (1 + 8 / 30.0);
      final brzycki = 100 * (36.0 / (37.0 - 8));
      expect(value, closeTo(epley < brzycki ? epley : brzycki, 0.0001));
    });

    test('median of top three suppresses one outlier', () {
      final sets = [
        ExerciseSet(
          exerciseId: 1,
          setNumber: 1,
          weight: 100,
          reps: 5,
          completed: true,
        ),
        ExerciseSet(
          exerciseId: 1,
          setNumber: 2,
          weight: 102.5,
          reps: 4,
          completed: true,
        ),
        ExerciseSet(
          exerciseId: 1,
          setNumber: 3,
          weight: 140,
          reps: 1,
          completed: true,
        ),
        ExerciseSet(
          exerciseId: 1,
          setNumber: 4,
          weight: 70,
          reps: 10,
          completed: true,
        ),
      ];

      final best = OneRmCalculator.bestCombined(
        currentSets: sets,
        history: const [],
      );

      expect(best, isNotNull);
      expect(best!, lessThan(140));
      expect(best, greaterThan(105));
    });

    test('single eligible set falls back to that estimate', () {
      final best = OneRmCalculator.bestCombined(
        currentSets: [
          ExerciseSet(
            exerciseId: 1,
            setNumber: 1,
            weight: 90,
            reps: 3,
            completed: true,
          ),
        ],
        history: const [],
      );

      expect(best, closeTo(OneRmCalculator.estimate(90, 3)!, 0.0001));
    });
  });
}
