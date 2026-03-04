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
  /// Each primary muscle maps to a specific, fine-grained category so that
  /// alternative exercise suggestions are accurate (e.g. biceps exercises
  /// are not mixed with triceps exercises).
  static const Map<String, String> _muscleGroupMap = {
    'abdominals': 'Core',
    'abductors': 'Glutes',
    'adductors': 'Glutes',
    'biceps': 'Biceps',
    'calves': 'Calves',
    'chest': 'Chest',
    'forearms': 'Forearms',
    'glutes': 'Glutes',
    'hamstrings': 'Hamstrings',
    'lats': 'Back',
    'lower back': 'Lower Back',
    'middle back': 'Back',
    'neck': 'Neck',
    'quadriceps': 'Quadriceps',
    'shoulders': 'Shoulders',
    'traps': 'Shoulders',
    'triceps': 'Triceps',
  };

  /// Category → app category mapping for special types.
  static const Map<String, String> _categoryOverrides = {
    'cardio': 'Cardio',
    'plyometrics': 'Plyometrics',
    'stretching': 'Stretches',
    'olympic weightlifting': 'Full Body',
    'strongman': 'Full Body',
  };

  /// Manual overrides for custom exercise names that don't match the
  /// free-exercise-db naming conventions. Keys must be lowercase.
  static const Map<String, String> _customExerciseOverrides = {
    // Cardio
    'exercise bike': 'Cardio',
    'cycle ergometer': 'Cardio',
    'stationary bike': 'Cardio',
    'treadmill': 'Cardio',
    'elliptical': 'Cardio',
    'jump rope': 'Cardio',
    // Quadriceps
    'air squats': 'Quadriceps',
    'bodyweight squats': 'Quadriceps',
    'narrow stance leg press': 'Quadriceps',
    'leg extension': 'Quadriceps',
    'leg press': 'Quadriceps',
    'goblet squat': 'Quadriceps',
    'bulgarian split squat': 'Quadriceps',
    'front squat': 'Quadriceps',
    'hack squat': 'Quadriceps',
    'sissy squat': 'Quadriceps',
    'wall sit': 'Quadriceps',
    // Hamstrings
    'seated leg curls': 'Hamstrings',
    'lying leg curls': 'Hamstrings',
    'nordic hamstring curl': 'Hamstrings',
    'romanian deadlift': 'Hamstrings',
    'stiff-leg deadlift': 'Hamstrings',
    'good morning': 'Hamstrings',
    // Chest
    'seated pec fly': 'Chest',
    'seated fly isolateral': 'Chest',
    'horizontal barbell bench press': 'Chest',
    '30° incline dumbbell bench press': 'Chest',
    'cable crossover': 'Chest',
    'chest dip': 'Chest',
    'pec deck': 'Chest',
    // Back (Lats / Middle Back)
    'standing rope pullover': 'Back',
    'narrow grip seated row': 'Back',
    'narrow grip isolateral': 'Back',
    'universal lat pulldown machine': 'Back',
    'incline prone dumbbell row': 'Back',
    'bent-over dumbbell row': 'Back',
    'cable row': 'Back',
    'pull-up': 'Back',
    'chin-up': 'Back',
    't-bar row': 'Back',
    // Lower Back
    'back extension': 'Lower Back',
    'hyperextension': 'Lower Back',
    'superman': 'Lower Back',
    'reverse hyperextension': 'Lower Back',
    // Shoulders
    'one-arm cable lateral raise': 'Shoulders',
    'machine shoulder press': 'Shoulders',
    'face pull': 'Shoulders',
    'lateral raise': 'Shoulders',
    'front raise': 'Shoulders',
    'arnold press': 'Shoulders',
    'upright row': 'Shoulders',
    // Biceps
    'standing dumbbell curls': 'Biceps',
    'one-arm scott dumbbell curl': 'Biceps',
    'barbell curl': 'Biceps',
    'hammer curl': 'Biceps',
    'preacher curl': 'Biceps',
    'concentration curl': 'Biceps',
    'cable curl': 'Biceps',
    'ez-bar curl': 'Biceps',
    'incline dumbbell curl': 'Biceps',
    // Triceps
    'triceps pushdown': 'Triceps',
    'skull crusher': 'Triceps',
    'overhead triceps extension': 'Triceps',
    'triceps dip': 'Triceps',
    'close-grip bench press': 'Triceps',
    'cable triceps extension': 'Triceps',
    'diamond push-up': 'Triceps',
    'kickback': 'Triceps',
    // Glutes
    'hip thrust': 'Glutes',
    'glute bridge': 'Glutes',
    'cable kickback': 'Glutes',
    'donkey kick': 'Glutes',
    'fire hydrant': 'Glutes',
    'hip abduction': 'Glutes',
    'hip adduction': 'Glutes',
    // Calves
    'seated calf raises': 'Calves',
    'standing calf raises': 'Calves',
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
    final name = (exercise['name'] as String? ?? '').toLowerCase();
    final category = (exercise['category'] as String? ?? '').toLowerCase();

    // Check category overrides first (cardio, plyometrics, stretching, etc.)
    if (_categoryOverrides.containsKey(category)) {
      return _categoryOverrides[category]!;
    }

    // Name-based overrides for exercises whose primaryMuscles in the DB
    // don't reflect the actual main target (common data quality issues).
    // Close-grip bench press targets triceps; other bench presses target chest.
    if (name.contains('bench press')) {
      if (name.contains('close-grip') || name.contains('close grip') || name.contains('reverse triceps')) {
        return 'Triceps';
      }
      return 'Chest';
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

  /// Cache for fuzzy-matched exercise names → muscle group.
  static final Map<String, String> _fuzzyCache = {};

  /// Find the muscle group for a given exercise name.
  /// Uses exact match, then contains match, then keyword matching.
  /// Results are cached for performance.
  static Future<String> findMuscleGroup(String exerciseName) async {
    await _ensureLoaded();
    if (_exercises == null || _exercises!.isEmpty) return 'Other';

    final lower = exerciseName.toLowerCase().trim();
    if (lower.isEmpty) return 'Other';

    // Check fuzzy cache first
    if (_fuzzyCache.containsKey(lower)) return _fuzzyCache[lower]!;

    // Check custom overrides for known exercise names
    if (_customExerciseOverrides.containsKey(lower)) {
      final group = _customExerciseOverrides[lower]!;
      _fuzzyCache[lower] = group;
      return group;
    }

    // Try exact match first
    for (final ex in _exercises!) {
      if ((ex['name'] as String).toLowerCase() == lower) {
        final group = _resolveMuscleGroup(ex);
        _fuzzyCache[lower] = group;
        return group;
      }
    }

    // Try contains match
    for (final ex in _exercises!) {
      final exName = (ex['name'] as String).toLowerCase();
      if (exName.contains(lower) || lower.contains(exName)) {
        final group = _resolveMuscleGroup(ex);
        _fuzzyCache[lower] = group;
        return group;
      }
    }

    // Keyword matching fallback — at least 2 words must match
    final queryWords = lower.split(RegExp(r'[\s\-_°]+'));
    Map<String, dynamic>? bestMatch;
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
        bestMatch = ex;
      }
    }

    if (bestMatch != null && maxMatches >= 2) {
      final group = _resolveMuscleGroup(bestMatch);
      _fuzzyCache[lower] = group;
      return group;
    }

    _fuzzyCache[lower] = 'Other';
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
    // Include custom overrides so exact-match also covers plan exercises
    map.addAll(_customExerciseOverrides);
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
