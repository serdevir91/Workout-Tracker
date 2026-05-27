const List<int> kSetMilestones = <int>[50, 100, 1000];
const List<int> kStreakMilestones = <int>[7, 14, 30];

String setAchievementKey(int threshold) => 'sets_$threshold';
String streakAchievementKey(int threshold) => 'streak_$threshold';

class StreakSnapshot {
  const StreakSnapshot({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.scheduledToday,
    required this.completedToday,
    required this.offDayToday,
    required this.recentRequiredDays,
    required this.recentCompletedDays,
  });

  final int currentStreakDays;
  final int longestStreakDays;
  final bool scheduledToday;
  final bool completedToday;
  final bool offDayToday;
  final int recentRequiredDays;
  final int recentCompletedDays;

  double get recentAdherenceRate {
    if (recentRequiredDays == 0) {
      return 1.0;
    }
    return recentCompletedDays / recentRequiredDays;
  }

  int? get nextMilestoneDays {
    for (final int threshold in kStreakMilestones) {
      if (currentStreakDays < threshold) {
        return threshold;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'currentStreakDays': currentStreakDays,
      'longestStreakDays': longestStreakDays,
      'scheduledToday': scheduledToday,
      'completedToday': completedToday,
      'offDayToday': offDayToday,
      'recentRequiredDays': recentRequiredDays,
      'recentCompletedDays': recentCompletedDays,
      'recentAdherenceRate': recentAdherenceRate,
      'nextMilestoneDays': nextMilestoneDays,
    };
  }
}

StreakSnapshot calculateStreakSnapshot({
  required Set<int> workoutDays,
  required Set<String> offDayKeys,
  required Map<String, double> completionByDay,
  required DateTime today,
  int completionThreshold = 80,
  int lookbackDays = 365,
}) {
  final Set<int> normalizedWorkoutDays = workoutDays
      .where((int day) => day >= 1 && day <= 7)
      .toSet();

  bool isRequiredDay(DateTime date) {
    if (!normalizedWorkoutDays.contains(date.weekday)) {
      return false;
    }
    return !offDayKeys.contains(_dateKey(date));
  }

  bool isCompliant(DateTime date) {
    final String key = _dateKey(date);
    return (completionByDay[key] ?? 0) >= completionThreshold;
  }

  final DateTime todayDate = DateTime(today.year, today.month, today.day);

  final bool scheduledToday = isRequiredDay(todayDate);
  final bool completedToday = scheduledToday && isCompliant(todayDate);
  final bool offDayToday = offDayKeys.contains(_dateKey(todayDate));

  int currentStreakDays = 0;
  for (int offset = 0; offset <= lookbackDays; offset++) {
    final DateTime date = todayDate.subtract(Duration(days: offset));
    if (!isRequiredDay(date)) {
      continue;
    }

    if (offset == 0 && !isCompliant(date)) {
      // Do not break streak before the current required day is completed.
      continue;
    }

    if (isCompliant(date)) {
      currentStreakDays++;
      continue;
    }

    break;
  }

  int longestStreakDays = 0;
  int running = 0;
  for (int offset = lookbackDays; offset >= 0; offset--) {
    final DateTime date = todayDate.subtract(Duration(days: offset));
    if (!isRequiredDay(date)) {
      continue;
    }

    if (offset == 0 && !isCompliant(date)) {
      if (running > longestStreakDays) {
        longestStreakDays = running;
      }
      continue;
    }

    if (isCompliant(date)) {
      running++;
      if (running > longestStreakDays) {
        longestStreakDays = running;
      }
    } else {
      running = 0;
    }
  }

  int recentRequiredDays = 0;
  int recentCompletedDays = 0;
  for (int offset = 0; offset < 28; offset++) {
    final DateTime date = todayDate.subtract(Duration(days: offset));
    if (!isRequiredDay(date)) {
      continue;
    }
    recentRequiredDays++;
    if (isCompliant(date)) {
      recentCompletedDays++;
    }
  }

  return StreakSnapshot(
    currentStreakDays: currentStreakDays,
    longestStreakDays: longestStreakDays,
    scheduledToday: scheduledToday,
    completedToday: completedToday,
    offDayToday: offDayToday,
    recentRequiredDays: recentRequiredDays,
    recentCompletedDays: recentCompletedDays,
  );
}

String _dateKey(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
