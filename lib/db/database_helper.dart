import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/workout_models.dart';
import '../models/workout_plan_models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;
  Future<Database>? _initDbFuture;

  /// Initialize the database factory for the current platform
  static void initDatabaseFactory() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Eğer hali hazırda bir kurulum devam ediyorsa onu bekle
    if (_initDbFuture != null) {
      _database = await _initDbFuture;
      return _database!;
    }
    
    _initDbFuture = _initDatabase();
    _database = await _initDbFuture;
    _initDbFuture = null;
    return _database!;
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'workout_tracker.db');
  }

  /// Close the database connection and reset the singleton so it reopens fresh.
  /// Must be called before replacing the DB file (restore).
  Future<void> closeAndReset() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _initDbFuture = null;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'workout_tracker.db');

    return openDatabase(
      path,
      version: 9, // Upgraded to v9 (indexes)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Core Workout Tables
    await db.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        total_duration INTEGER DEFAULT 0,
        calories REAL DEFAULT 0,
        completion_percentage REAL DEFAULT 100.0
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

    // 2. Settings & Options
    await db.execute('''
      CREATE TABLE user_settings (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        theme TEXT DEFAULT 'system',
        language TEXT DEFAULT 'en',
        unit TEXT DEFAULT 'kg',
        height REAL,
        weight REAL,
        last_weight_update TEXT,
        show_on_dashboard INTEGER DEFAULT 1,
        display_all_data INTEGER DEFAULT 1,
        auto_positioning INTEGER DEFAULT 0,
        workout_days TEXT DEFAULT '1,2,3,4,5,6,7'
      )
    ''');
    await db.execute("INSERT INTO user_settings (id) VALUES (1)");

    await db.execute('''
      CREATE TABLE off_days (
        date TEXT PRIMARY KEY
      )
    ''');

    // 3. Workout Templates (Plans)
    await db.execute('''
      CREATE TABLE workout_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day_number INTEGER NOT NULL,
        name TEXT NOT NULL,
        target_muscles TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE template_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight REAL DEFAULT 0,
        duration_minutes INTEGER,
        rest_seconds INTEGER DEFAULT 60,
        FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE
      )
    ''');

    // Note: User requested not to seed default templates. Just keep schema empty.

    // Performance indexes
    await db.execute('CREATE INDEX idx_exercises_workout_id ON exercises(workout_id)');
    await db.execute('CREATE INDEX idx_exercise_sets_exercise_id ON exercise_sets(exercise_id)');
    await db.execute('CREATE INDEX idx_exercises_name ON exercises(name)');
    await db.execute('CREATE INDEX idx_workouts_start_time ON workouts(start_time)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add calories column to existing workouts
      await db.execute('ALTER TABLE workouts ADD COLUMN calories REAL DEFAULT 0');

      // Create Settings
      await db.execute('''
        CREATE TABLE user_settings (
          id INTEGER PRIMARY KEY CHECK (id = 1),
          theme TEXT DEFAULT 'system',
          language TEXT DEFAULT 'en',
          unit TEXT DEFAULT 'kg',
          height REAL,
          weight REAL,
          last_weight_update TEXT,
          show_on_dashboard INTEGER DEFAULT 1,
          display_all_data INTEGER DEFAULT 1,
          auto_positioning INTEGER DEFAULT 0,
          workout_days TEXT DEFAULT '1,2,3,4,5,6,7'
        )
      ''');
      await db.execute("INSERT INTO user_settings (id) VALUES (1)");

      // Create Off-days
      await db.execute('''
        CREATE TABLE off_days (
          date TEXT PRIMARY KEY
        )
      ''');

      // Create Templates
      await db.execute('''
        CREATE TABLE workout_templates (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          day_number INTEGER NOT NULL,
          name TEXT NOT NULL,
          target_muscles TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE template_exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          template_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          weight REAL DEFAULT 0,
          duration_minutes INTEGER,
          rest_seconds INTEGER DEFAULT 60,
          FOREIGN KEY (template_id) REFERENCES workout_templates(id) ON DELETE CASCADE
        )
      ''');

      // Seed default plans
      await _seedDefaultTemplates(db);
    }
    
    if (oldVersion < 3) {
      // The user requested to delete the default templates natively assigned
      await db.delete('workout_templates', where: "name IN ('Push Day', 'Pull Day', 'Leg Day')");
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE user_settings ADD COLUMN show_on_dashboard INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE user_settings ADD COLUMN display_all_data INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE user_settings ADD COLUMN auto_positioning INTEGER DEFAULT 0');
      await db.execute("ALTER TABLE user_settings ADD COLUMN workout_days TEXT DEFAULT '1,2,3,4,5,6,7'");
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE workouts ADD COLUMN completion_percentage REAL DEFAULT 100.0');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE template_exercises ADD COLUMN rest_seconds INTEGER DEFAULT 60');
    }
    if (oldVersion < 8) {
      // Fix for databases created that missed the completion_percentage column
      try {
        await db.execute('ALTER TABLE workouts ADD COLUMN completion_percentage REAL DEFAULT 100.0');
      } catch (_) {
        // Ignored. Column likely already exists.
      }
    }

    if (oldVersion < 9) {
      // Performance indexes
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_workout_id ON exercises(workout_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercise_sets_exercise_id ON exercise_sets(exercise_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercises_name ON exercises(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_workouts_start_time ON workouts(start_time)');
    }
  }

  Future<void> _seedDefaultTemplates(Database db) async {
    for (var plan in defaultWorkoutPlans) {
      int tempId = await db.insert('workout_templates', {
        'day_number': plan.dayNumber,
        'name': plan.name,
        'target_muscles': plan.targetMuscles,
      });

      for (var ex in plan.exercises) {
        await db.insert('template_exercises', {
          'template_id': tempId,
          'name': ex.name,
          'sets': ex.sets,
          'reps': ex.reps,
          'weight': ex.weight,
          'duration_minutes': ex.durationMinutes,
          'rest_seconds': ex.restSeconds,
        });
      }
    }
  }

  // ==================== SETTINGS & OFF-DAYS ====================

  Future<Map<String, dynamic>> getUserSettings() async {
    final db = await database;
    final maps = await db.query('user_settings', where: 'id = 1');
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return {};
  }

  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    final db = await database;
    await db.update('user_settings', settings, where: 'id = 1');
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

  Future<void> finishWorkout(int id, int totalDuration, double calories, double completionPercentage) async {
    final db = await database;
    await db.update(
      'workouts',
      {
        'end_time': DateTime.now().toIso8601String(),
        'total_duration': totalDuration,
        'calories': calories,
        'completion_percentage': completionPercentage,
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

  Future<Workout?> getUnfinishedWorkout() async {
    final db = await database;
    final maps = await db.query(
      'workouts', 
      where: 'end_time IS NULL', 
      orderBy: 'start_time DESC', 
      limit: 1
    );
    if (maps.isNotEmpty) {
      return Workout.fromMap(maps.first);
    }
    return null;
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

  Future<void> updateSet(int setId, double weight, int reps) async {
    final db = await database;
    await db.update('exercise_sets', {
      'weight': weight,
      'reps': reps,
    }, where: 'id = ?', whereArgs: [setId]);
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

  /// Get exercises with their sets in a single JOIN query (N+1 fix for workout detail).
  Future<List<Map<String, dynamic>>> getExercisesWithSets(int workoutId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        e.id as exercise_id, e.workout_id, e.name, e.start_time, e.end_time, 
        e.duration, e.exercise_order,
        s.id as set_id, s.set_number, s.weight, s.reps, s.completed
      FROM exercises e
      LEFT JOIN exercise_sets s ON e.id = s.exercise_id
      WHERE e.workout_id = ?
      ORDER BY e.exercise_order ASC, s.set_number ASC
    ''', [workoutId]);

    final Map<int, Map<String, dynamic>> grouped = {};
    for (final row in result) {
      final exId = row['exercise_id'] as int;
      if (!grouped.containsKey(exId)) {
        grouped[exId] = {
          'exercise': Exercise(
            id: exId,
            workoutId: row['workout_id'] as int,
            name: row['name'] as String,
            startTime: DateTime.parse(row['start_time'] as String),
            endTime: row['end_time'] != null ? DateTime.parse(row['end_time'] as String) : null,
            duration: row['duration'] as int? ?? 0,
            exerciseOrder: row['exercise_order'] as int,
          ),
          'sets': <ExerciseSet>[],
        };
      }
      if (row['set_id'] != null) {
        (grouped[exId]!['sets'] as List<ExerciseSet>).add(ExerciseSet(
          id: row['set_id'] as int,
          exerciseId: exId,
          setNumber: row['set_number'] as int,
          weight: (row['weight'] as num).toDouble(),
          reps: row['reps'] as int,
          completed: (row['completed'] as int? ?? 0) == 1,
        ));
      }
    }
    return grouped.values.toList();
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
        COALESCE(SUM(s.reps), 0) as total_reps,
        COALESCE(SUM(s.weight * s.reps), 0) as total_volume,
        COALESCE(SUM(e.duration), 0) as total_duration,
        COALESCE(AVG(s.weight), 0) as avg_weight,
        COALESCE(AVG(s.reps), 0) as avg_reps
      FROM exercises e
      JOIN exercise_sets s ON e.id = s.exercise_id
      WHERE s.completed = 1
      GROUP BY e.name
      ORDER BY total_volume DESC, total_sets DESC
    ''');
    
    return result;
  }

  Future<List<Map<String, dynamic>>> getWorkoutSessionStats() async {
    final db = await database;
    
    final sessions = await db.rawQuery('''
      SELECT 
        w.id,
        w.name,
        w.start_time,
        w.total_duration,
        COUNT(DISTINCT e.id) as total_exercises,
        COUNT(s.id) as total_sets,
        COALESCE(SUM(s.reps), 0) as total_reps,
        COALESCE(SUM(s.weight * s.reps), 0) as total_volume
      FROM workouts w
      LEFT JOIN exercises e ON w.id = e.workout_id
      LEFT JOIN exercise_sets s ON e.id = s.exercise_id AND s.completed = 1
      WHERE w.end_time IS NOT NULL
      GROUP BY w.id
      ORDER BY w.start_time DESC
    ''');
    
    final exercises = await db.rawQuery('''
      SELECT 
        e.workout_id,
        e.name,
        COALESCE(e.duration, 0) as duration,
        COUNT(s.id) as sets,
        COALESCE(SUM(s.reps), 0) as reps,
        COALESCE(MAX(s.weight), 0) as max_weight,
        COALESCE(AVG(s.weight), 0) as avg_weight
      FROM exercises e
      JOIN exercise_sets s ON e.id = s.exercise_id AND s.completed = 1
      GROUP BY e.id
      ORDER BY e.exercise_order ASC
    ''');
    
    final List<Map<String, dynamic>> result = [];
    for (var session in sessions) {
      final sessMap = Map<String, dynamic>.from(session);
      final workoutId = session['id'];
      sessMap['exercises'] = exercises.where((e) => e['workout_id'] == workoutId).toList();
      result.add(sessMap);
    }
    
    return result;
  }

  /// Get all weekly stats in a single query (replaces 21 separate queries).
  Future<Map<String, List<double>>> getWeeklyAllStats() async {
    final db = await database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)).toIso8601String();
    final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery('''
      SELECT 
        date(w.start_time) as workout_date,
        COALESCE(SUM(s.weight * s.reps), 0) as daily_volume,
        COALESCE(SUM(s.reps), 0) as daily_reps,
        COUNT(s.id) as daily_sets
      FROM exercise_sets s
      JOIN exercises e ON s.exercise_id = e.id
      JOIN workouts w ON e.workout_id = w.id
      WHERE w.start_time >= ? AND w.start_time <= ? AND s.completed = 1
      GROUP BY date(w.start_time)
    ''', [startDate, endDate]);

    final volumes = List.filled(7, 0.0);
    final reps = List.filled(7, 0.0);
    final sets = List.filled(7, 0.0);

    final todayStart = DateTime(now.year, now.month, now.day);
    for (final row in result) {
      final dateStr = row['workout_date'] as String;
      final date = DateTime.parse(dateStr);
      final daysAgo = todayStart.difference(DateTime(date.year, date.month, date.day)).inDays;
      final index = 6 - daysAgo;
      if (index >= 0 && index < 7) {
        volumes[index] = (row['daily_volume'] as num?)?.toDouble() ?? 0.0;
        reps[index] = (row['daily_reps'] as num?)?.toDouble() ?? 0.0;
        sets[index] = (row['daily_sets'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return {'volume': volumes, 'reps': reps, 'sets': sets};
  }

  /// Get all exercise names with their set counts for a given time range.
  /// Used to build muscle group distribution charts.
  Future<List<Map<String, dynamic>>> getExerciseSetCountsByPeriod(String? startDate) async {
    final db = await database;
    final where = startDate != null ? 'AND w.start_time >= ?' : '';
    final args = startDate != null ? [startDate] : <String>[];
    
    final result = await db.rawQuery('''
      SELECT 
        e.name,
        COUNT(s.id) as total_sets
      FROM exercises e
      JOIN exercise_sets s ON e.id = s.exercise_id AND s.completed = 1
      JOIN workouts w ON e.workout_id = w.id
      WHERE w.end_time IS NOT NULL $where
      GROUP BY LOWER(e.name)
      ORDER BY total_sets DESC
    ''', args);
    return result;
  }

  /// Get calories per workout session for the chart.
  Future<List<Map<String, dynamic>>> getCaloriesPerWorkout(String? startDate) async {
    final db = await database;
    final where = startDate != null ? 'AND w.start_time >= ?' : '';
    final args = startDate != null ? [startDate] : <String>[];
    
    final result = await db.rawQuery('''
      SELECT 
        w.id,
        w.name,
        w.start_time,
        COALESCE(w.calories, 0) as calories,
        w.total_duration
      FROM workouts w
      WHERE w.end_time IS NOT NULL $where
      ORDER BY w.start_time DESC
      LIMIT 10
    ''', args);
    return result;
  }

  Future<Map<String, dynamic>?> getLastExerciseRecord(String exerciseName) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        w.start_time,
        COUNT(s.id) as sets,
        COALESCE(MAX(s.weight), 0) as max_weight,
        COALESCE(SUM(s.reps), 0) as total_reps
      FROM exercises e
      JOIN workouts w ON e.workout_id = w.id
      JOIN exercise_sets s ON e.id = s.exercise_id AND s.completed = 1
      WHERE e.name = ? AND w.end_time IS NOT NULL
      GROUP BY e.id
      ORDER BY w.start_time DESC
      LIMIT 1
    ''', [exerciseName]);
    
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  /// Get exercise history grouped by workout session (single JOIN query).
  Future<List<Map<String, dynamic>>> getExerciseHistory(String exerciseName) async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        e.id as exercise_id,
        e.duration,
        w.start_time,
        w.name as workout_name,
        s.set_number,
        s.weight,
        s.reps
      FROM exercises e
      JOIN workouts w ON e.workout_id = w.id
      LEFT JOIN exercise_sets s ON e.id = s.exercise_id AND s.completed = 1
      WHERE LOWER(e.name) = LOWER(?) AND w.end_time IS NOT NULL
      ORDER BY w.start_time DESC, s.set_number ASC
    ''', [exerciseName]);

    // Group by exercise_id (preserving insertion order = most recent first)
    final Map<int, Map<String, dynamic>> grouped = {};
    for (final row in result) {
      final exId = row['exercise_id'] as int;
      if (!grouped.containsKey(exId)) {
        grouped[exId] = {
          'start_time': row['start_time'],
          'workout_name': row['workout_name'],
          'duration': row['duration'] ?? 0,
          'sets': <Map<String, dynamic>>[],
        };
      }
      if (row['set_number'] != null) {
        (grouped[exId]!['sets'] as List).add({
          'set_number': row['set_number'],
          'weight': row['weight'],
          'reps': row['reps'],
        });
      }
    }
    return grouped.values.take(20).toList();
  }

  // ==================== WORKOUT TEMPLATES ====================

  Future<List<WorkoutPlan>> getAllWorkoutTemplates() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        t.id as template_id, t.name, t.day_number, t.target_muscles,
        te.id as ex_id, te.name as ex_name, te.sets, te.reps, 
        te.weight, te.duration_minutes, te.rest_seconds
      FROM workout_templates t
      LEFT JOIN template_exercises te ON t.id = te.template_id
      ORDER BY t.day_number ASC, te.id ASC
    ''');

    final Map<int, Map<String, dynamic>> templateMap = {};
    final Map<int, List<PlanExercise>> exerciseMap = {};

    for (final row in result) {
      final tId = row['template_id'] as int;
      if (!templateMap.containsKey(tId)) {
        templateMap[tId] = row;
        exerciseMap[tId] = [];
      }
      if (row['ex_id'] != null) {
        exerciseMap[tId]!.add(PlanExercise(
          id: row['ex_id'] as int,
          templateId: tId,
          name: row['ex_name'] as String,
          sets: (row['sets'] as num?)?.toInt() ?? 1,
          reps: (row['reps'] as num?)?.toInt() ?? 0,
          weight: (row['weight'] as num?)?.toDouble() ?? 0,
          durationMinutes: row['duration_minutes'] as int?,
          restSeconds: (row['rest_seconds'] as num?)?.toInt() ?? 60,
        ));
      }
    }

    return templateMap.entries.map((entry) {
      final row = entry.value;
      final tId = entry.key;
      return WorkoutPlan(
        id: tId,
        name: row['name'] as String,
        dayNumber: row['day_number'] as int,
        exercises: exerciseMap[tId] ?? [],
        targetMuscles: row['target_muscles'] as String? ?? '',
      );
    }).toList();
  }

  Future<int> insertWorkoutTemplate(WorkoutPlan plan) async {
    final db = await database;
    final tId = await db.insert('workout_templates', {
      'name': plan.name,
      'day_number': plan.dayNumber,
      'target_muscles': plan.targetMuscles,
    });
    
    for (int i = 0; i < plan.exercises.length; i++) {
      final ex = plan.exercises[i];
      await db.insert('template_exercises', {
        'template_id': tId,
        'name': ex.name,
        'sets': ex.sets > 0 ? ex.sets : 3,
        'reps': ex.reps > 0 ? ex.reps : 10,
        'weight': ex.weight,
        'duration_minutes': ex.durationMinutes,
        'rest_seconds': ex.restSeconds,
      });
    }
    return tId;
  }

  Future<void> updateWorkoutTemplate(WorkoutPlan plan) async {
    if (plan.id == null) return;
    final db = await database;
    await db.update('workout_templates', {
      'name': plan.name,
      'day_number': plan.dayNumber,
      'target_muscles': plan.targetMuscles,
    }, where: 'id = ?', whereArgs: [plan.id]);
    
    await db.delete('template_exercises', where: 'template_id = ?', whereArgs: [plan.id]);
    
    for (int i = 0; i < plan.exercises.length; i++) {
      final ex = plan.exercises[i];
      await db.insert('template_exercises', {
        'template_id': plan.id,
        'name': ex.name,
        'sets': ex.sets > 0 ? ex.sets : 3,
        'reps': ex.reps > 0 ? ex.reps : 10,
        'weight': ex.weight,
        'duration_minutes': ex.durationMinutes,
        'rest_seconds': ex.restSeconds,
      });
    }
  }

  Future<void> deleteWorkoutTemplate(int id) async {
    final db = await database;
    await db.delete('template_exercises', where: 'template_id = ?', whereArgs: [id]);
    await db.delete('workout_templates', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== OFF DAYS ====================

  Future<List<DateTime>> getOffDays() async {
    final db = await database;
    final maps = await db.query('off_days');
    return maps.map((e) => DateTime.parse(e['date'] as String)).toList();
  }

  Future<void> toggleOffDay(DateTime date) async {
    final db = await database;
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final existing = await db.query('off_days', where: 'date = ?', whereArgs: [dateStr]);
    if (existing.isEmpty) {
      await db.insert('off_days', {'date': dateStr});
    } else {
      await db.delete('off_days', where: 'date = ?', whereArgs: [dateStr]);
    }
  }
}
