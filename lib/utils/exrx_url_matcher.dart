import 'dart:convert';
import 'package:flutter/services.dart';

/// Utility to look up ExRx.net URLs and GIF URLs from exercise names.
class ExrxUrlMatcher {
  static List<Map<String, dynamic>>? _exercises;

  /// Load the ExRx exercise database from assets.
  static Future<void> _ensureLoaded() async {
    if (_exercises != null) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/exrx_exercises.json');
      final List<dynamic> data = json.decode(jsonStr);
      _exercises = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _exercises = [];
    }
  }

  /// Get all loaded exercises in the library.
  static Future<List<Map<String, dynamic>>> getAllExercises() async {
    await _ensureLoaded();
    return _exercises ?? [];
  }

  /// Find the best matching ExRx exercise for a given exercise name.
  /// Returns a map with 'url' and 'gif_url' keys, or null if no match.
  static Future<Map<String, String>?> findExercise(String exerciseName) async {
    await _ensureLoaded();
    if (_exercises == null || _exercises!.isEmpty) return null;

    final lower = exerciseName.toLowerCase().trim();
    if (lower.isEmpty) return null;

    Map<String, dynamic>? bestExercise;
    int bestScore = 0;

    for (final ex in _exercises!) {
      final exName = (ex['name'] as String).toLowerCase();

      // Exact match — highest priority
      if (exName == lower) {
        bestExercise = ex;
        bestScore = 10000;
        break;
      }

      // Contains match
      if (exName.contains(lower) || lower.contains(exName)) {
        final score = exName.length + 100;
        if (score > bestScore) {
          bestScore = score;
          bestExercise = ex;
        }
      }
    }

    // Keyword matching fallback
    if (bestExercise == null) {
      final queryWords = lower.split(RegExp(r'[\s\-_]+'));
      int maxMatches = 0;

      for (final ex in _exercises!) {
        final exName = (ex['name'] as String).toLowerCase();
        int matches = 0;
        for (final word in queryWords) {
          if (word.length > 2 && exName.contains(word)) {
            matches++;
          }
        }
        if (matches > maxMatches) {
          maxMatches = matches;
          bestExercise = ex;
        }
      }

      if (maxMatches < 2) bestExercise = null;
    }

    if (bestExercise == null) return null;

    return {
      'url': bestExercise['url'] as String? ?? '',
      'gif_url': bestExercise['gif_url'] as String? ?? '',
    };
  }

  /// Shortcut to just get the URL string.
  static Future<String?> findUrl(String exerciseName) async {
    final result = await findExercise(exerciseName);
    if (result == null || result['url']!.isEmpty) return null;
    return result['url'];
  }

  /// Find the muscle group for a given exercise name.
  static Future<String> findMuscleGroup(String exerciseName) async {
    await _ensureLoaded();
    if (_exercises == null || _exercises!.isEmpty) return 'Other';

    final lower = exerciseName.toLowerCase().trim();
    if (lower.isEmpty) return 'Other';

    // Try exact match first
    for (final ex in _exercises!) {
      if ((ex['name'] as String).toLowerCase() == lower) {
        return ex['muscle_group'] as String? ?? 'Other';
      }
    }

    // Try contains match
    for (final ex in _exercises!) {
      final exName = (ex['name'] as String).toLowerCase();
      if (exName.contains(lower) || lower.contains(exName)) {
        return ex['muscle_group'] as String? ?? 'Other';
      }
    }

    return 'Other';
  }

  static Map<String, String>? _muscleGroupMapCache;

  /// Build a map of exercise name -> muscle group for all known exercises.
  /// Cached after first call.
  static Future<Map<String, String>> buildMuscleGroupMap() async {
    if (_muscleGroupMapCache != null) return _muscleGroupMapCache!;
    await _ensureLoaded();
    final map = <String, String>{};
    if (_exercises == null) return map;
    for (final ex in _exercises!) {
      final name = (ex['name'] as String).toLowerCase();
      final group = ex['muscle_group'] as String? ?? 'Other';
      map[name] = group;
    }
    _muscleGroupMapCache = map;
    return map;
  }

  /// Get all exercises belonging to a specific muscle group.
  /// Returns a list of maps with 'name', 'url', 'gif_url' keys.
  static Future<List<Map<String, String>>> getExercisesByMuscleGroup(String muscleGroup) async {
    await _ensureLoaded();
    if (_exercises == null || _exercises!.isEmpty) return [];
    final lower = muscleGroup.toLowerCase().trim();
    final results = <Map<String, String>>[];
    for (final ex in _exercises!) {
      final group = (ex['muscle_group'] as String? ?? '').toLowerCase();
      if (group == lower) {
        results.add({
          'name': ex['name'] as String? ?? '',
          'url': ex['url'] as String? ?? '',
          'gif_url': ex['gif_url'] as String? ?? '',
        });
      }
    }
    return results;
  }
}
