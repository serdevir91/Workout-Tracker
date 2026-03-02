import 'dart:convert';
import 'package:flutter/services.dart';

/// Utility to look up exercises from the free-exercise-db (public domain).
/// Replaces the old ExRx.net integration.
///
/// Data source: https://github.com/yuhonas/free-exercise-db
/// License: Unlicense (public domain)
///
/// Images are hosted on GitHub raw:
///   https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{id}/0.jpg
///   https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{id}/1.jpg
class ExerciseDB {
  static List<Map<String, dynamic>>? _exercises;

  static const String _imageBaseUrl =
      'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/';

  /// Primary muscle → app category mapping.
  static const Map<String, String> _muscleGroupMap = {
    'abdominals': 'Core',
    'abductors': 'Glutes & Hips',
    'adductors': 'Glutes & Hips',
    'biceps': 'Arms',
    'calves': 'Calves',
    'chest': 'Chest',
    'forearms': 'Forearms',
    'glutes': 'Glutes & Hips',
    'hamstrings': 'Legs',
    'lats': 'Back',
    'lower back': 'Back',
    'middle back': 'Back',
    'neck': 'Neck',
    'quadriceps': 'Legs',
    'shoulders': 'Shoulders',
    'traps': 'Back',
    'triceps': 'Arms',
  };

  /// Category → app category mapping for special types.
  static const Map<String, String> _categoryOverrides = {
    'cardio': 'Cardio',
    'plyometrics': 'Plyometrics',
    'stretching': 'Stretches',
    'olympic weightlifting': 'Full Body',
    'strongman': 'Full Body',
  };

  /// Load the exercise database from bundled JSON asset.
  static Future<void> _ensureLoaded() async {
    if (_exercises != null) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/free_exercises.json');
      final List<dynamic> data = json.decode(jsonStr);
      _exercises =
          data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      _exercises = [];
    }
  }

  /// Get the app-facing muscle group for a raw exercise map.
  static String _resolveMuscleGroup(Map<String, dynamic> exercise) {
    final category = (exercise['category'] as String? ?? '').toLowerCase();

    // Check category overrides first (cardio, plyometrics, stretching, etc.)
    if (_categoryOverrides.containsKey(category)) {
      return _categoryOverrides[category]!;
    }

    // Map primary muscle to app category
    final muscles = exercise['primaryMuscles'] as List<dynamic>?;
    if (muscles != null && muscles.isNotEmpty) {
      final primary = (muscles.first as String).toLowerCase();
      return _muscleGroupMap[primary] ?? 'Other';
    }
    return 'Other';
  }

  /// Build image URL for a given exercise ID and image index (0 or 1).
  static String imageUrl(String exerciseId, int index) {
    return '$_imageBaseUrl$exerciseId/$index.jpg';
  }

  /// Get all exercises with app-compatible fields.
  /// Each map has: name, id, muscle_group, category, level, equipment,
  ///   force, mechanic, primaryMuscles, secondaryMuscles, instructions,
  ///   images (list of full URLs), image_url (first image).
  static Future<List<Map<String, dynamic>>> getAllExercises() async {
    await _ensureLoaded();
    if (_exercises == null) return [];

    return _exercises!.map((ex) {
      final images = (ex['images'] as List<dynamic>?)
              ?.map((img) => '$_imageBaseUrl$img')
              .toList() ??
          [];

      return {
        ...ex,
        'muscle_group': _resolveMuscleGroup(ex),
        'image_url': images.isNotEmpty ? images.first : '',
        'images': images,
      };
    }).toList();
  }

  /// Find the best matching exercise for a given name.
  /// Returns a map with 'image_url', 'images', 'muscle_group', etc.
  static Future<Map<String, dynamic>?> findExercise(
      String exerciseName) async {
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

    final images = (bestExercise['images'] as List<dynamic>?)
            ?.map((img) => '$_imageBaseUrl$img')
            .toList() ??
        [];

    return {
      ...bestExercise,
      'muscle_group': _resolveMuscleGroup(bestExercise),
      'image_url': images.isNotEmpty ? images.first : '',
      'images': images,
    };
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
        return _resolveMuscleGroup(ex);
      }
    }

    // Try contains match
    for (final ex in _exercises!) {
      final exName = (ex['name'] as String).toLowerCase();
      if (exName.contains(lower) || lower.contains(exName)) {
        return _resolveMuscleGroup(ex);
      }
    }

    return 'Other';
  }

  static Map<String, String>? _muscleGroupMapCache;

  /// Build a map of exercise name (lowercase) → muscle group for all exercises.
  /// Cached after first call.
  static Future<Map<String, String>> buildMuscleGroupMap() async {
    if (_muscleGroupMapCache != null) return _muscleGroupMapCache!;
    await _ensureLoaded();
    final map = <String, String>{};
    if (_exercises == null) return map;
    for (final ex in _exercises!) {
      final name = (ex['name'] as String).toLowerCase();
      final group = _resolveMuscleGroup(ex);
      map[name] = group;
    }
    _muscleGroupMapCache = map;
    return map;
  }

  /// Get all exercises belonging to a specific muscle group.
  static Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
      String muscleGroup) async {
    await _ensureLoaded();
    if (_exercises == null || _exercises!.isEmpty) return [];
    final lower = muscleGroup.toLowerCase().trim();
    final results = <Map<String, dynamic>>[];

    for (final ex in _exercises!) {
      final group = _resolveMuscleGroup(ex).toLowerCase();
      if (group == lower) {
        final images = (ex['images'] as List<dynamic>?)
                ?.map((img) => '$_imageBaseUrl$img')
                .toList() ??
            [];
        results.add({
          ...ex,
          'muscle_group': _resolveMuscleGroup(ex),
          'image_url': images.isNotEmpty ? images.first : '',
          'images': images,
        });
      }
    }
    return results;
  }
}
