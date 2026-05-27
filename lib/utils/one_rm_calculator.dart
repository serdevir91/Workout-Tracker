import '../models/workout_models.dart';

class OneRmCalculator {
  static const int minEligibleReps = 1;
  static const int maxEligibleReps = 10;

  static bool isEligibleSet(double weight, int reps) {
    return weight > 0 &&
        reps >= minEligibleReps &&
        reps <= maxEligibleReps;
  }

  static double? estimate(double weight, int reps) {
    if (!isEligibleSet(weight, reps)) {
      return null;
    }

    if (reps == 1) {
      return weight;
    }

    final epley = weight * (1 + reps / 30.0);
    final brzycki = weight * (36.0 / (37.0 - reps));
    return epley < brzycki ? epley : brzycki;
  }

  static double? bestEstimateFromSets(Iterable<ExerciseSet> sets) {
    final estimates = sets
        .map((set) => estimate(set.weight, set.reps))
        .whereType<double>()
        .toList();
    return _aggregate(estimates);
  }

  static double? bestEstimateFromHistory(Iterable<Map<String, dynamic>> history) {
    final estimates = <double>[];
    for (final session in history) {
      final sets = (session['sets'] as List<dynamic>? ?? const []);
      for (final raw in sets) {
        final map = raw as Map<String, dynamic>;
        final weight = (map['weight'] as num?)?.toDouble() ?? 0;
        final reps = (map['reps'] as num?)?.toInt() ?? 0;
        final estimateValue = estimate(weight, reps);
        if (estimateValue != null) {
          estimates.add(estimateValue);
        }
      }
    }
    return _aggregate(estimates);
  }

  static double? bestCombined({
    required Iterable<ExerciseSet> currentSets,
    required Iterable<Map<String, dynamic>> history,
  }) {
    final estimates = currentSets
        .map((set) => estimate(set.weight, set.reps))
        .whereType<double>()
        .toList();

    for (final session in history) {
      final sets = (session['sets'] as List<dynamic>? ?? const []);
      for (final raw in sets) {
        final map = raw as Map<String, dynamic>;
        final weight = (map['weight'] as num?)?.toDouble() ?? 0;
        final reps = (map['reps'] as num?)?.toInt() ?? 0;
        final estimateValue = estimate(weight, reps);
        if (estimateValue != null) {
          estimates.add(estimateValue);
        }
      }
    }

    return _aggregate(estimates);
  }

  static double? _aggregate(List<double> estimates) {
    if (estimates.isEmpty) {
      return null;
    }

    estimates.sort((a, b) => b.compareTo(a));
    final top = estimates.take(3).toList()..sort();
    return top[top.length ~/ 2];
  }
}
