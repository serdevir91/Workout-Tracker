import 'dart:async';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/workout_models.dart';
import '../models/workout_plan_models.dart';

class ActiveExercise {
  Exercise exercise;
  List<ExerciseSet> sets;

  ActiveExercise({required this.exercise, required this.sets});
}

class WorkoutProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  // Workout list
  List<Workout> _workouts = [];
  List<Workout> get workouts => _workouts;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Active workout
  Workout? _activeWorkout;
  Workout? get activeWorkout => _activeWorkout;
  List<ActiveExercise> _activeExercises = [];
  List<ActiveExercise> get activeExercises => _activeExercises;
  bool get isWorkoutActive => _activeWorkout != null;

  // Timers
  int _workoutElapsedSeconds = 0;
  int get workoutElapsedSeconds => _workoutElapsedSeconds;
  Map<int, int> _exerciseElapsedSeconds = {};
  Map<int, int> get exerciseElapsedSeconds => _exerciseElapsedSeconds;
  Timer? _timer;
  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  // ==================== ACTIONS ====================

  Future<void> loadWorkouts() async {
    _isLoading = true;
    notifyListeners();
    _workouts = await _db.getAllWorkouts();
    _isLoading = false;
    notifyListeners();
  }

  List<Workout> getWorkoutsForDay(DateTime day) {
    return _workouts.where((w) {
      final wDate = w.startTime;
      return wDate.year == day.year &&
             wDate.month == day.month &&
             wDate.day == day.day;
    }).toList();
  }

  Future<void> startWorkout(String name) async {
    final workoutId = await _db.createWorkout(name);
    _activeWorkout = Workout(
      id: workoutId,
      name: name,
      startTime: DateTime.now(),
    );
    _activeExercises = [];
    _workoutElapsedSeconds = 0;
    _exerciseElapsedSeconds = {};
    _isTimerRunning = false;
    notifyListeners();
  }

  Future<void> finishWorkout() async {
    if (_activeWorkout == null) return;

    // Finish any active exercise
    if (_activeExercises.isNotEmpty) {
      final lastEx = _activeExercises.last;
      if (lastEx.exercise.endTime == null) {
        final duration = _exerciseElapsedSeconds[lastEx.exercise.id] ?? 0;
        await _db.finishExercise(lastEx.exercise.id!, duration);
      }
    }

    await _db.finishWorkout(_activeWorkout!.id!, _workoutElapsedSeconds);
    _stopTimer();
    _isTimerRunning = false;
    _activeWorkout = null;
    _activeExercises = [];
    _workoutElapsedSeconds = 0;
    _exerciseElapsedSeconds = {};
    await loadWorkouts();
    notifyListeners();
  }

  Future<void> addExercise(String name) async {
    if (_activeWorkout == null) return;

    // Finish previous exercise
    if (_activeExercises.isNotEmpty) {
      final prevEx = _activeExercises.last;
      if (prevEx.exercise.endTime == null) {
        final duration = _exerciseElapsedSeconds[prevEx.exercise.id] ?? 0;
        await _db.finishExercise(prevEx.exercise.id!, duration);
        prevEx.exercise = prevEx.exercise.copyWith(
          endTime: DateTime.now(),
          duration: duration,
        );
      }
    }

    final exerciseId = await _db.createExercise(
      _activeWorkout!.id!,
      name,
      _activeExercises.length + 1,
    );

    final newExercise = ActiveExercise(
      exercise: Exercise(
        id: exerciseId,
        workoutId: _activeWorkout!.id!,
        name: name,
        startTime: DateTime.now(),
        exerciseOrder: _activeExercises.length + 1,
      ),
      sets: [],
    );

    _exerciseElapsedSeconds[exerciseId] = 0;
    _activeExercises.add(newExercise);
    notifyListeners();
  }

  Future<void> addSet(int exerciseId, double weight, int reps) async {
    final index = _activeExercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (index == -1) return;

    final setNumber = _activeExercises[index].sets.length + 1;
    final setId = await _db.createSet(exerciseId, setNumber, weight, reps);

    _activeExercises[index].sets.add(ExerciseSet(
      id: setId,
      exerciseId: exerciseId,
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      completed: true,
    ));
    notifyListeners();
  }

  Future<void> deleteWorkout(int id) async {
    await _db.deleteWorkout(id);
    await loadWorkouts();
  }

  Future<void> deleteSet(int exerciseId, int setId) async {
    await _db.deleteSet(setId);
    final index = _activeExercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (index != -1) {
      _activeExercises[index].sets.removeWhere((s) => s.id == setId);
      // Re-number sets
      for (int i = 0; i < _activeExercises[index].sets.length; i++) {
        final oldSet = _activeExercises[index].sets[i];
        _activeExercises[index].sets[i] = ExerciseSet(
          id: oldSet.id,
          exerciseId: oldSet.exerciseId,
          setNumber: i + 1,
          weight: oldSet.weight,
          reps: oldSet.reps,
          completed: oldSet.completed,
        );
      }
      notifyListeners();
    }
  }

  Future<void> deleteExercise(int exerciseId) async {
    await _db.deleteExercise(exerciseId);
    _activeExercises.removeWhere((e) => e.exercise.id == exerciseId);
    _exerciseElapsedSeconds.remove(exerciseId);
    notifyListeners();
  }

  Future<void> startWorkoutFromPlan(WorkoutPlan plan) async {
    final workoutId = await _db.createWorkout('Day ${plan.dayNumber} - ${plan.name}');
    _activeWorkout = Workout(
      id: workoutId,
      name: 'Day ${plan.dayNumber} - ${plan.name}',
      startTime: DateTime.now(),
    );
    _activeExercises = [];
    _workoutElapsedSeconds = 0;
    _exerciseElapsedSeconds = {};

    // Create all exercises from plan
    for (int i = 0; i < plan.exercises.length; i++) {
      final planEx = plan.exercises[i];
      final exerciseId = await _db.createExercise(workoutId, planEx.name, i + 1);

      final activeEx = ActiveExercise(
        exercise: Exercise(
          id: exerciseId,
          workoutId: workoutId,
          name: planEx.name,
          startTime: DateTime.now(),
          exerciseOrder: i + 1,
        ),
        sets: [],
      );

      _exerciseElapsedSeconds[exerciseId] = 0;
      _activeExercises.add(activeEx);
    }

    _isTimerRunning = false;
    notifyListeners();
  }

  // ==================== TIMER ====================

  void pauseTimer() {
    _stopTimer();
    _isTimerRunning = false;
    notifyListeners();
  }

  void resumeTimer() {
    if (_isTimerRunning) return;
    _startTimer();
    _isTimerRunning = true;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _workoutElapsedSeconds++;

      // Tick active exercise timer
      if (_activeExercises.isNotEmpty) {
        final lastEx = _activeExercises.last;
        if (lastEx.exercise.endTime == null && lastEx.exercise.id != null) {
          _exerciseElapsedSeconds[lastEx.exercise.id!] =
              (_exerciseElapsedSeconds[lastEx.exercise.id!] ?? 0) + 1;
        }
      }
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ==================== DETAIL ====================

  Future<Map<String, dynamic>> loadWorkoutDetail(int id) async {
    final workout = await _db.getWorkoutById(id);
    if (workout == null) return {'workout': null, 'exercises': <Map<String, dynamic>>[]};

    final exercises = await _db.getExercisesByWorkoutId(id);
    final List<Map<String, dynamic>> exercisesWithSets = [];

    for (final exercise in exercises) {
      final sets = await _db.getSetsByExerciseId(exercise.id!);
      exercisesWithSets.add({'exercise': exercise, 'sets': sets});
    }

    return {'workout': workout, 'exercises': exercisesWithSets};
  }

  // ==================== STATS ====================

  Future<Map<String, num>> getStats() async {
    return _db.getWorkoutStats();
  }

  Future<List<Map<String, dynamic>>> getExerciseStats() async {
    return _db.getExerciseStats();
  }

  Future<List<double>> getWeeklyVolumeStats() async {
    return _db.getWeeklyVolumeStats();
  }

  Future<List<double>> getWeeklyRepsStats() async {
    return _db.getWeeklyRepsStats();
  }

  Future<List<double>> getWeeklySetsStats() async {
    return _db.getWeeklySetsStats();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
