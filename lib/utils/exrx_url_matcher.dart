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
}
