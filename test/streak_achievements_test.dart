import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/utils/streak_achievements.dart';

void main() {
  group('calculateStreakSnapshot', () {
    test('calculates streak and next milestone on compliant sequence', () {
      final snapshot = calculateStreakSnapshot(
        workoutDays: <int>{1, 2, 3, 4, 5, 6, 7},
        offDayKeys: <String>{},
        completionByDay: <String, double>{
          '2026-04-20': 82,
          '2026-04-19': 90,
          '2026-04-18': 85,
          '2026-04-17': 70,
        },
        today: DateTime(2026, 4, 20),
      );

      expect(snapshot.currentStreakDays, 3);
      expect(snapshot.nextMilestoneDays, 7);
      expect(snapshot.scheduledToday, isTrue);
      expect(snapshot.completedToday, isTrue);
    });

    test('does not break streak when today is pending', () {
      final snapshot = calculateStreakSnapshot(
        workoutDays: <int>{1, 2, 3, 4, 5, 6, 7},
        offDayKeys: <String>{},
        completionByDay: <String, double>{
          '2026-04-19': 88,
          '2026-04-18': 84,
          '2026-04-17': 65,
        },
        today: DateTime(2026, 4, 20),
      );

      expect(snapshot.currentStreakDays, 2);
      expect(snapshot.completedToday, isFalse);
      expect(snapshot.scheduledToday, isTrue);
    });

    test('skips off days while evaluating streak continuity', () {
      final snapshot = calculateStreakSnapshot(
        workoutDays: <int>{1, 2, 3, 4, 5, 6, 7},
        offDayKeys: <String>{'2026-04-19'},
        completionByDay: <String, double>{
          '2026-04-20': 92,
          '2026-04-18': 81,
          '2026-04-17': 70,
        },
        today: DateTime(2026, 4, 20),
      );

      expect(snapshot.currentStreakDays, 2);
      expect(snapshot.offDayToday, isFalse);
    });

    test('reports no required days when schedule is empty', () {
      final snapshot = calculateStreakSnapshot(
        workoutDays: <int>{},
        offDayKeys: <String>{},
        completionByDay: <String, double>{},
        today: DateTime(2026, 4, 20),
      );

      expect(snapshot.currentStreakDays, 0);
      expect(snapshot.longestStreakDays, 0);
      expect(snapshot.recentRequiredDays, 0);
      expect(snapshot.recentAdherenceRate, 1.0);
    });
  });
}
