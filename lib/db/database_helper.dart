import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/workout_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  /// Initialize the database factory for the current platform
  static void initDatabaseFactory() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_duration INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration INTEGER DEFAULT 0,
        exercise_order INTEGER NOT NULL,
        FOREIGN KEY (workout_id) REFERENCES workouts(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE exercise_sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        weight REAL NOT NULL DEFAULT 0,
        reps INTEGER NOT NULL DEFAULT 0,
        completed INTEGER DEFAULT 1,
        FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== WORKOUTS ====================

  Future<List<Workout>> getAllWorkouts() async {
    final db = await database;
    final maps = await db.query('workouts', orderBy: 'start_time DESC');
    return maps.map((m) => Workout.fromMap(m)).toList();
  }

  Future<int> createWorkout(String name) async {
    final db = await database;
    return db.insert('workouts', {
      'name': name,
      'start_time': DateTime.now().toIso8601String(),
    });
  }

  Future<void> finishWorkout(int id, int totalDuration) async {
    final db = await database;
    await db.update(
      'workouts',
      {
        'end_time': DateTime.now().toIso8601String(),
        'total_duration': totalDuration,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteWorkout(int id) async {
    final db = await database;
    await db.delete('exercises', where: 'workout_id = ?', whereArgs: [id]);
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }

  Future<Workout?> getWorkoutById(int id) async {
    final db = await database;
    final maps = await db.query('workouts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Workout.fromMap(maps.first);
  }

  // ==================== EXERCISES ====================

  Future<List<Exercise>> getExercisesByWorkoutId(int workoutId) async {
    final db = await database;
    final maps = await db.query(
      'exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'exercise_order ASC',
    );
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<int> createExercise(int workoutId, String name, int order) async {
    final db = await database;
    return db.insert('exercises', {
      'workout_id': workoutId,
      'name': name,
      'start_time': DateTime.now().toIso8601String(),
      'exercise_order': order,
    });
  }

  Future<void> finishExercise(int id, int duration) async {
    final db = await database;
    await db.update(
      'exercises',
      {
        'end_time': DateTime.now().toIso8601String(),
        'duration': duration,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SETS ====================

  Future<List<ExerciseSet>> getSetsByExerciseId(int exerciseId) async {
    final db = await database;
    final maps = await db.query(
      'exercise_sets',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'set_number ASC',
    );
    return maps.map((m) => ExerciseSet.fromMap(m)).toList();
  }

  Future<int> createSet(int exerciseId, int setNumber, double weight, int reps) async {
    final db = await database;
    return db.insert('exercise_sets', {
      'exercise_id': exerciseId,
      'set_number': setNumber,
      'weight': weight,
      'reps': reps,
      'completed': 1,
    });
  }

  Future<int> deleteSet(int setId) async {
    final db = await database;
    return db.delete('exercise_sets', where: 'id = ?', whereArgs: [setId]);
  }

  Future<int> deleteExercise(int exerciseId) async {
    final db = await database;
    await db.delete('exercise_sets', where: 'exercise_id = ?', whereArgs: [exerciseId]);
    return db.delete('exercises', where: 'id = ?', whereArgs: [exerciseId]);
  }

  // ==================== STATS ====================

  Future<Map<String, num>> getWorkoutStats() async {
    final db = await database;

    final workoutResult = await db.rawQuery(
      "SELECT COUNT(*) as total_workouts, COALESCE(SUM(total_duration), 0) as total_duration FROM workouts WHERE end_time IS NOT NULL",
    );

    final volumeResult = await db.rawQuery(
      "SELECT COALESCE(SUM(weight * reps), 0) as total_volume, COUNT(*) as total_sets FROM exercise_sets WHERE completed = 1",
    );

    return {
      'totalWorkouts': workoutResult.first['total_workouts'] as int? ?? 0,
      'totalDuration': workoutResult.first['total_duration'] as int? ?? 0,
      'totalVolume': (volumeResult.first['total_volume'] as num?) ?? 0,
      'totalSets': volumeResult.first['total_sets'] as int? ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getExerciseStats() async {
    final db = await database;
    
    // Group by exercise name
    final result = await db.rawQuery('''
      SELECT 
        e.name,
        COUNT(s.id) as total_sets,
        COALESCE(SUM(s.weight * s.reps), 0) as total_volume,
        COALESCE(SUM(e.duration), 0) as total_duration -- Approximated per exercise if durations are kept
      FROM exercises e
      JOIN exercise_sets s ON e.id = s.exercise_id
      WHERE s.completed = 1
      GROUP BY e.name
      ORDER BY total_volume DESC, total_sets DESC
    ''');
    
    return result;
  }

  Future<List<double>> getWeeklyVolumeStats() async {
    final db = await database;
    final now = DateTime.now();
    final List<double> weeklyVolumes = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
        
        final result = await db.rawQuery('''
          SELECT COALESCE(SUM(s.weight * s.reps), 0) as daily_volume
          FROM exercise_sets s
          JOIN exercises e ON s.exercise_id = e.id
          JOIN workouts w ON e.workout_id = w.id
          WHERE w.start_time >= ? AND w.start_time <= ? AND s.completed = 1
        ''', [startOfDay, endOfDay]);
        
        weeklyVolumes[i] = (result.first['daily_volume'] as num?)?.toDouble() ?? 0.0;
    }
    return weeklyVolumes;
  }

  Future<List<double>> getWeeklyRepsStats() async {
    final db = await database;
    final now = DateTime.now();
    final List<double> weeklyReps = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
        
        final result = await db.rawQuery('''
          SELECT COALESCE(SUM(s.reps), 0) as daily_reps
          FROM exercise_sets s
          JOIN exercises e ON s.exercise_id = e.id
          JOIN workouts w ON e.workout_id = w.id
          WHERE w.start_time >= ? AND w.start_time <= ? AND s.completed = 1
        ''', [startOfDay, endOfDay]);
        
        weeklyReps[i] = (result.first['daily_reps'] as num?)?.toDouble() ?? 0.0;
    }
    return weeklyReps;
  }

  Future<List<double>> getWeeklySetsStats() async {
    final db = await database;
    final now = DateTime.now();
    final List<double> weeklySets = List.filled(7, 0.0);

    for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
        
        final result = await db.rawQuery('''
          SELECT COUNT(s.id) as daily_sets
          FROM exercise_sets s
          JOIN exercises e ON s.exercise_id = e.id
          JOIN workouts w ON e.workout_id = w.id
          WHERE w.start_time >= ? AND w.start_time <= ? AND s.completed = 1
        ''', [startOfDay, endOfDay]);
        
        weeklySets[i] = (result.first['daily_sets'] as num?)?.toDouble() ?? 0.0;
    }
    return weeklySets;
  }
}
