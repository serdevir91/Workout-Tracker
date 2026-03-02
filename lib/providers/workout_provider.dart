import 'dart:async';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/workout_models.dart';
import '../models/workout_plan_models.dart';
import '../services/notification_service.dart';
import '../utils/exercise_db.dart';

class ActiveExercise {
  Exercise exercise;
  List<ExerciseSet> sets;
  final int targetSets;
  final int targetReps;
  final double targetWeight;
  final int restSeconds;
  final bool isCardio;

  ActiveExercise({
    required this.exercise,
    required this.sets,
    this.targetSets = 0,
    this.targetReps = 0,
    this.targetWeight = 0,
    this.restSeconds = 60,
    this.isCardio = false,
  });

  /// Detect cardio exercise once at creation instead of every build cycle.
  /// Uses muscle_group from exercise library if available, falls back to keyword matching.
  static bool detectCardio(String name, {String? muscleGroup}) {
    // If muscle_group is explicitly 'Cardio', return true immediately
    if (muscleGroup != null && muscleGroup.toLowerCase() == 'cardio') return true;
    final lower = name.toLowerCase();
    return lower.contains('bike') || lower.contains('run') || lower.contains('treadmill')
        || lower.contains('bisiklet') || lower.contains('koşu') || lower.contains('cardio')
        || lower.contains('cycling') || lower.contains('rowing') || lower.contains('elliptical')
        || lower.contains('jump rope') || lower.contains('swimming') || lower.contains('stair')
        || lower.contains('walk') || lower.contains('yürü') || lower.contains('kürek')
        || lower.contains('ip atlama') || lower.contains('yüzme') || lower.contains('eliptik');
  }
}

class WorkoutProvider extends ChangeNotifier with WidgetsBindingObserver {
  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notificationService = NotificationService();

  // Last set info for notification display
  String? _lastSetInfo;

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

  /// Calculate workout completion percentage from active exercises.
  /// Single source of truth — used by finishWorkout, active_workout_screen, etc.
  double get completionPercentage {
    int totalPlannedSets = 0;
    int completedSets = 0;
    for (var ex in _activeExercises) {
      totalPlannedSets += ex.targetSets > 0 ? ex.targetSets : ex.sets.length;
      completedSets += ex.sets.where((s) => s.completed).length;
    }
    if (totalPlannedSets <= 0) return 100.0;
    return (completedSets / totalPlannedSets * 100).clamp(0.0, 100.0);
  }

  // Timers — wall-clock based (survives background/throttling)
  int _workoutElapsedSeconds = 0;
  int get workoutElapsedSeconds => _workoutElapsedSeconds;
  Map<int, int> _exerciseElapsedSeconds = {};
  Map<int, int> get exerciseElapsedSeconds => _exerciseElapsedSeconds;
  Timer? _timer;
  bool _isTimerRunning = false;
  bool get isTimerRunning => _isTimerRunning;

  // Wall-clock fields — absolute timestamps for drift-proof timing
  DateTime? _workoutStartedAt;
  int _totalPausedSeconds = 0;
  DateTime? _manualPauseStartedAt;
  DateTime _lastTickTime = DateTime.now();

  // Rest Timer (countdown merged into main timer tick)
  int _restTimerSeconds = 0;
  int get restTimerSeconds => _restTimerSeconds;
  bool get isRestTimerActive => _restTimerSeconds > 0;
  int _restTimerTotalSeconds = 0; // Total rest duration for progress calculation
  DateTime? _restTimerStartedAt; // Wall-clock anchor for drift-proof rest countdown

  // ValueNotifiers for timer-only UI updates (avoids full widget tree rebuild)
  final ValueNotifier<int> elapsedSecondsNotifier = ValueNotifier(0);
  final ValueNotifier<int> restTimerNotifier = ValueNotifier(0);
  final ValueNotifier<Map<int, int>> exerciseTimersNotifier = ValueNotifier({});

  // Cardio timer tracking — exercises with active cardio timers
  final Set<int> _activeCardioTimerIds = {};
  Set<int> get activeCardioTimerIds => _activeCardioTimerIds;

  void startCardioTimer(int exerciseId) {
    _activeCardioTimerIds.add(exerciseId);
    notifyListeners();
  }

  void stopCardioTimer(int exerciseId) {
    _activeCardioTimerIds.remove(exerciseId);
    notifyListeners();
  }

  /// Reset cardio elapsed timer after saving a set.
  void resetCardioElapsed(int exerciseId) {
    _exerciseElapsedSeconds[exerciseId] = 0;
    exerciseTimersNotifier.value = Map.from(_exerciseElapsedSeconds);
    notifyListeners();
  }

  bool isCardioTimerActive(int exerciseId) => _activeCardioTimerIds.contains(exerciseId);

  // Draft Inputs for in-progress sets
  final Map<int, String> _draftWeights = {};
  final Map<int, String> _draftReps = {};
  final Map<String, Map<String, dynamic>> _lastExerciseStats = {};

  // Track which exercise the user is currently viewing (for notification)
  int _currentViewingExerciseIndex = -1;
  int get currentViewingExerciseIndex => _currentViewingExerciseIndex;

  void setCurrentViewingExercise(int index) {
    _currentViewingExerciseIndex = index;
    _updateNotification();
  }

  WorkoutProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    elapsedSecondsNotifier.dispose();
    restTimerNotifier.dispose();
    exerciseTimersNotifier.dispose();
    super.dispose();
  }

  /// Handle app lifecycle changes — wall-clock approach auto-corrects on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!isWorkoutActive || !_isTimerRunning) return;

    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      // 1. Recalculate total elapsed from wall clock (drift-proof)
      if (_workoutStartedAt != null) {
        _workoutElapsedSeconds = now.difference(_workoutStartedAt!).inSeconds - _totalPausedSeconds;
      }

      // 2. Recalculate rest timer from wall clock (drift-proof in background)
      if (_restTimerStartedAt != null && _restTimerTotalSeconds > 0) {
        final elapsed = now.difference(_restTimerStartedAt!).inSeconds;
        final remaining = _restTimerTotalSeconds - elapsed;
        if (remaining > 0) {
          _restTimerSeconds = remaining;
          restTimerNotifier.value = _restTimerSeconds;
        } else if (_restTimerSeconds > 0) {
          // Rest finished while app was in background
          _restTimerSeconds = 0;
          restTimerNotifier.value = 0;
          _restTimerStartedAt = null;
          _restTimerTotalSeconds = 0;
          _notificationService.showRestFinishedNotification();
        }
      }

      // 3. Compensate exercise & cardio timers for missed background time
      final missedSeconds = now.difference(_lastTickTime).inSeconds;
      if (missedSeconds > 1) {
        if (_activeExercises.isNotEmpty) {
          final lastEx = _activeExercises.last;
          if (lastEx.exercise.endTime == null && lastEx.exercise.id != null
              && !_activeCardioTimerIds.contains(lastEx.exercise.id!)) {
            _exerciseElapsedSeconds[lastEx.exercise.id!] =
                (_exerciseElapsedSeconds[lastEx.exercise.id!] ?? 0) + missedSeconds;
          }
        }
        for (final exId in _activeCardioTimerIds) {
          _exerciseElapsedSeconds[exId] =
              (_exerciseElapsedSeconds[exId] ?? 0) + missedSeconds;
        }
      }
      _lastTickTime = now;

      // 3. Ensure timer is alive (may have been killed by OS)
      _stopTimer();
      _startTimer();

      // 4. Update notification & UI
      _updateNotification();
      elapsedSecondsNotifier.value = _workoutElapsedSeconds;
      exerciseTimersNotifier.value = Map.from(_exerciseElapsedSeconds);
      notifyListeners();
    }
  }

  Map<String, dynamic>? getLastExerciseStats(String exerciseName) => _lastExerciseStats[exerciseName];

  String getDraftWeight(int exerciseId) => _draftWeights[exerciseId] ?? '';
  String getDraftReps(int exerciseId) => _draftReps[exerciseId] ?? '';

  void setDraftWeight(int exerciseId, String val) {
    _draftWeights[exerciseId] = val;
  }

  void setDraftReps(int exerciseId, String val) {
    _draftReps[exerciseId] = val;
  }
  
  void clearDrafts(int exerciseId) {
    _draftWeights.remove(exerciseId);
    _draftReps.remove(exerciseId);
  }

  // ==================== ACTIONS ====================

  Future<void> loadWorkouts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _workouts = await _db.getAllWorkouts();
      _offDays = await _db.getOffDays();
      _workoutPlans = await _db.getAllWorkoutTemplates();

      if (_activeWorkout == null) {
        final unfinished = await _db.getUnfinishedWorkout();
        if (unfinished != null) {
          _activeWorkout = unfinished;
          final exercises = await _db.getExercisesByWorkoutId(unfinished.id!);
          _activeExercises = [];
          for (var ex in exercises) {
            final sets = await _db.getSetsByExerciseId(ex.id!);
            final muscleGroup = await ExerciseDB.findMuscleGroup(ex.name);
            _activeExercises.add(ActiveExercise(exercise: ex, sets: sets, isCardio: ActiveExercise.detectCardio(ex.name, muscleGroup: muscleGroup)));
            _exerciseElapsedSeconds[ex.id!] = ex.duration;
            
            if (!_lastExerciseStats.containsKey(ex.name)) {
               final lastRecord = await _db.getLastExerciseRecord(ex.name);
               if (lastRecord != null) {
                 _lastExerciseStats[ex.name] = lastRecord;
               }
            }
          }
          final now = DateTime.now();
          _workoutStartedAt = unfinished.startTime;
          _totalPausedSeconds = 0;
          _manualPauseStartedAt = null;
          _workoutElapsedSeconds = now.difference(unfinished.startTime).inSeconds;
          _isTimerRunning = true;
          _startTimer();
          
          _workouts.removeWhere((w) => w.id == unfinished.id);
        }
      }
    } catch (e) {
      debugPrint("Error loading workouts: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
    // If there's already an active workout, finish it first
    if (_activeWorkout != null) {
      await _finishCurrentWorkoutSilently();
    }
    
    // Request notification permission
    await _notificationService.requestPermission();
    
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
    _workoutStartedAt = DateTime.now();
    _totalPausedSeconds = 0;
    _manualPauseStartedAt = null;
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

    final burnedCalories = _workoutElapsedSeconds * 0.15; // 9 calories per minute (0.15 per second)
    
    final percentage = completionPercentage;
    
    await _db.finishWorkout(_activeWorkout!.id!, _workoutElapsedSeconds, burnedCalories, percentage);
    _stopTimer();
    _isTimerRunning = false;
    _notificationService.cancelWorkoutNotification();
    _lastSetInfo = null;
    _activeWorkout = null;
    _activeExercises = [];
    _workoutElapsedSeconds = 0;
    _exerciseElapsedSeconds = {};
    _lastExerciseStats.clear();
    _activeCardioTimerIds.clear();
    _currentViewingExerciseIndex = -1;
    _workoutStartedAt = null;
    _totalPausedSeconds = 0;
    _manualPauseStartedAt = null;
    _restTimerStartedAt = null;
    _restTimerTotalSeconds = 0;
    elapsedSecondsNotifier.value = 0;
    restTimerNotifier.value = 0;
    exerciseTimersNotifier.value = {};
    await loadWorkouts();
    notifyListeners();
  }

  /// Finish the current workout silently (without resetting state for new workout).
  /// Used when switching to a new workout.
  Future<void> _finishCurrentWorkoutSilently() async {
    if (_activeWorkout == null) return;

    // Finish any active exercise
    if (_activeExercises.isNotEmpty) {
      final lastEx = _activeExercises.last;
      if (lastEx.exercise.endTime == null) {
        final duration = _exerciseElapsedSeconds[lastEx.exercise.id] ?? 0;
        await _db.finishExercise(lastEx.exercise.id!, duration);
      }
    }

    final burnedCalories = _workoutElapsedSeconds * 0.15;

    final percentage = completionPercentage;

    await _db.finishWorkout(_activeWorkout!.id!, _workoutElapsedSeconds, burnedCalories, percentage);
    _stopTimer();
  }

  Future<void> addExercise(String name, {String? muscleGroup}) async {
    if (_activeWorkout == null) return;

    // Start workout timer on first exercise add if not running
    if (!_isTimerRunning) {
      _isTimerRunning = true;
      _startTimer();
    }

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
      isCardio: ActiveExercise.detectCardio(name, muscleGroup: muscleGroup),
    );

    if (!_lastExerciseStats.containsKey(name)) {
       final lastRecord = await _db.getLastExerciseRecord(name);
       if (lastRecord != null) {
         _lastExerciseStats[name] = lastRecord;
       }
    }

    _exerciseElapsedSeconds[exerciseId] = 0;
    _activeExercises.add(newExercise);
    notifyListeners();
  }

  Future<void> addSet(int exerciseId, double weight, int reps) async {
    final index = _activeExercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (index == -1) return;

    // Start timer on first set if not already running
    if (!_isTimerRunning) {
      _isTimerRunning = true;
      _startTimer();
      // Show initial notification
      _updateNotification();
    }

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

    // Update last set info for notification
    final exName = _activeExercises[index].exercise.name;
    if (weight > 0) {
      final w = weight == weight.toInt() ? weight.toInt().toString() : weight.toStringAsFixed(1);
      _lastSetInfo = '$exName ${w}kg x $reps';
    } else {
      _lastSetInfo = '$exName $reps min';
    }
    _updateNotification();

    notifyListeners();
  }

  Future<void> updateSet(int exerciseId, int setId, double weight, int reps) async {
    await _db.updateSet(setId, weight, reps);
    final index = _activeExercises.indexWhere((e) => e.exercise.id == exerciseId);
    if (index != -1) {
      final setIndex = _activeExercises[index].sets.indexWhere((s) => s.id == setId);
      if (setIndex != -1) {
         final oldSet = _activeExercises[index].sets[setIndex];
         _activeExercises[index].sets[setIndex] = ExerciseSet(
            id: oldSet.id,
            exerciseId: oldSet.exerciseId,
            setNumber: oldSet.setNumber,
            weight: weight,
            reps: reps,
            completed: oldSet.completed,
         );
         notifyListeners();
      }
    }
  }

  Future<void> cancelWorkout() async {
    if (_activeWorkout != null) {
      await _db.deleteWorkout(_activeWorkout!.id!);
      _stopTimer();
      _isTimerRunning = false;
      _notificationService.cancelWorkoutNotification();
      _lastSetInfo = null;
      _activeWorkout = null;
      _activeExercises = [];
      _workoutElapsedSeconds = 0;
      _exerciseElapsedSeconds = {};
      _lastExerciseStats.clear();
      _activeCardioTimerIds.clear();
      _currentViewingExerciseIndex = -1;
      _workoutStartedAt = null;
      _totalPausedSeconds = 0;
      _manualPauseStartedAt = null;
      elapsedSecondsNotifier.value = 0;
      exerciseTimersNotifier.value = {};
      stopRestTimer();
      notifyListeners();
      await loadWorkouts();
    }
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
    // If there's already an active workout, finish it first
    if (_activeWorkout != null) {
      await _finishCurrentWorkoutSilently();
    }
    
    // Request notification permission
    await _notificationService.requestPermission();

    final workoutId = await _db.createWorkout('Day ${plan.dayNumber} - ${plan.name}');
    _activeWorkout = Workout(
      id: workoutId,
      name: 'Day ${plan.dayNumber} - ${plan.name}',
      startTime: DateTime.now(),
    );
    _activeExercises = [];
    _workoutElapsedSeconds = 0;
    _exerciseElapsedSeconds = {};
    _lastExerciseStats.clear();
    _workoutStartedAt = DateTime.now();
    _totalPausedSeconds = 0;
    _manualPauseStartedAt = null;

    // Create all exercises from plan
    for (int i = 0; i < plan.exercises.length; i++) {
      final planEx = plan.exercises[i];
      final exerciseId = await _db.createExercise(workoutId, planEx.name, i + 1);

      final muscleGroupPlan = await ExerciseDB.findMuscleGroup(planEx.name);
      final activeEx = ActiveExercise(
        exercise: Exercise(
          id: exerciseId,
          workoutId: workoutId,
          name: planEx.name,
          startTime: DateTime.now(),
          exerciseOrder: i + 1,
        ),
        sets: [],
        targetSets: planEx.sets,
        targetReps: planEx.reps,
        targetWeight: planEx.weight,
        restSeconds: planEx.restSeconds,
        isCardio: ActiveExercise.detectCardio(planEx.name, muscleGroup: muscleGroupPlan),
      );

      if (!_lastExerciseStats.containsKey(planEx.name)) {
         final lastRecord = await _db.getLastExerciseRecord(planEx.name);
         if (lastRecord != null) {
           _lastExerciseStats[planEx.name] = lastRecord;
         }
      }

      _exerciseElapsedSeconds[exerciseId] = 0;
      _activeExercises.add(activeEx);
    }

    _isTimerRunning = false;
    notifyListeners();
  }

  // ==================== TIMER ====================

  void pauseTimer() {
    _manualPauseStartedAt = DateTime.now();
    _stopTimer();
    _isTimerRunning = false;
    notifyListeners();
  }

  void resumeTimer() {
    if (_isTimerRunning) return;
    // Account for manual pause duration
    if (_manualPauseStartedAt != null) {
      _totalPausedSeconds += DateTime.now().difference(_manualPauseStartedAt!).inSeconds;
      _manualPauseStartedAt = null;
    }
    _startTimer();
    _isTimerRunning = true;
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _lastTickTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final delta = now.difference(_lastTickTime).inSeconds;
      _lastTickTime = now;

      // Wall-clock for total elapsed (drift-proof, survives background)
      if (_workoutStartedAt != null) {
        _workoutElapsedSeconds = now.difference(_workoutStartedAt!).inSeconds - _totalPausedSeconds;
      }

      // Delta-based for exercise timers (auto-compensates background gaps)
      // Skip exercises that have active cardio timers — they use their own path below
      if (_activeExercises.isNotEmpty) {
        final lastEx = _activeExercises.last;
        if (lastEx.exercise.endTime == null && lastEx.exercise.id != null
            && !_activeCardioTimerIds.contains(lastEx.exercise.id!)) {
          _exerciseElapsedSeconds[lastEx.exercise.id!] =
              (_exerciseElapsedSeconds[lastEx.exercise.id!] ?? 0) + delta;
        }
      }

      // Delta-based for cardio timers
      for (final exId in _activeCardioTimerIds) {
        _exerciseElapsedSeconds[exId] =
            (_exerciseElapsedSeconds[exId] ?? 0) + delta;
      }

      // Rest timer countdown — wall-clock based (drift-proof in background)
      if (_restTimerStartedAt != null && _restTimerTotalSeconds > 0) {
        final elapsed = now.difference(_restTimerStartedAt!).inSeconds;
        final remaining = _restTimerTotalSeconds - elapsed;
        if (remaining > 0) {
          _restTimerSeconds = remaining;
          restTimerNotifier.value = _restTimerSeconds;
          // Update rest countdown notification
          _notificationService.showRestTimerNotification(
            remainingSeconds: _restTimerSeconds,
            totalSeconds: _restTimerTotalSeconds,
          );
        } else if (_restTimerSeconds > 0) {
          // Rest just finished — send alert
          _restTimerSeconds = 0;
          restTimerNotifier.value = 0;
          _restTimerStartedAt = null;
          _restTimerTotalSeconds = 0;
          _notificationService.showRestFinishedNotification();
          notifyListeners(); // Notify once when rest finishes to update UI
        }
      }

      // Update notification every second for live timer display
      if (_activeWorkout != null) {
        _updateNotification();
      }

      // Update ValueNotifiers only (no full-tree notifyListeners per tick)
      elapsedSecondsNotifier.value = _workoutElapsedSeconds;
      exerciseTimersNotifier.value = Map.from(_exerciseElapsedSeconds);
    });
  }

  /// Update the persistent notification with current workout info.
  void _updateNotification() {
    if (_activeWorkout == null) return;
    
    // Gather rich info for the notification
    int totalSets = 0;
    String? currentExName;
    for (var ex in _activeExercises) {
      totalSets += ex.sets.where((s) => s.completed).length;
    }
    
    // Use the currently viewed exercise if available
    if (_currentViewingExerciseIndex >= 0 && _currentViewingExerciseIndex < _activeExercises.length) {
      currentExName = _activeExercises[_currentViewingExerciseIndex].exercise.name;
    } else if (_activeExercises.isNotEmpty) {
      // Fallback: last exercise with no end time
      for (var ex in _activeExercises) {
        if (ex.exercise.endTime == null) {
          currentExName = ex.exercise.name;
        }
      }
    }
    
    _notificationService.showWorkoutNotification(
      workoutName: _activeWorkout!.name,
      elapsedSeconds: _workoutElapsedSeconds,
      lastSetInfo: _lastSetInfo,
      exerciseCount: _activeExercises.length,
      totalSets: totalSets,
      restTimerSeconds: _restTimerSeconds,
      currentExerciseName: currentExName,
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ==================== REST TIMER ====================

  void startRestTimer(int durationSeconds) {
    _restTimerSeconds = durationSeconds;
    _restTimerTotalSeconds = durationSeconds;
    _restTimerStartedAt = DateTime.now();
    restTimerNotifier.value = _restTimerSeconds;
    // Show rest started notification
    _notificationService.showRestTimerNotification(
      remainingSeconds: _restTimerSeconds,
      totalSeconds: _restTimerTotalSeconds,
    );
    notifyListeners(); // Notify once to show rest timer UI
  }

  void stopRestTimer() {
    _restTimerSeconds = 0;
    _restTimerTotalSeconds = 0;
    _restTimerStartedAt = null;
    restTimerNotifier.value = 0;
    _notificationService.cancelRestTimerNotification();
    notifyListeners();
  }

  // ==================== DETAIL ====================

  Future<Map<String, dynamic>> loadWorkoutDetail(int id) async {
    final workout = await _db.getWorkoutById(id);
    if (workout == null) return {'workout': null, 'exercises': <Map<String, dynamic>>[]};

    final exercisesWithSets = await _db.getExercisesWithSets(id);
    return {'workout': workout, 'exercises': exercisesWithSets};
  }

  // ==================== EXERCISE HISTORY ====================

  /// Get exercise history for a specific exercise name (for detail screen)
  Future<List<Map<String, dynamic>>> getExerciseHistory(String exerciseName) async {
    return _db.getExerciseHistory(exerciseName);
  }

  // ==================== WORKOUT PLANS ====================

  List<WorkoutPlan> _workoutPlans = [];
  List<WorkoutPlan> get workoutPlans => _workoutPlans;

  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {
    if (plan.id == null) {
      await _db.insertWorkoutTemplate(plan);
    } else {
      await _db.updateWorkoutTemplate(plan);
    }
    _workoutPlans = await _db.getAllWorkoutTemplates();
    notifyListeners();
  }

  Future<void> deleteWorkoutPlan(int id) async {
    await _db.deleteWorkoutTemplate(id);
    _workoutPlans = await _db.getAllWorkoutTemplates();
    notifyListeners();
  }

  // ==================== OFF DAYS ====================

  List<DateTime> _offDays = [];
  List<DateTime> get offDays => _offDays;

  Future<void> toggleOffDay(DateTime date) async {
    await _db.toggleOffDay(date);
    _offDays = await _db.getOffDays();
    notifyListeners();
  }

  bool isOffDay(DateTime date) {
    return _offDays.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
  }

  // ==================== STATS ====================

  Future<Map<String, num>> getStats() async {
    return _db.getWorkoutStats();
  }

  Future<List<Map<String, dynamic>>> getExerciseStats() async {
    return _db.getExerciseStats();
  }

  Future<List<Map<String, dynamic>>> getWorkoutSessionStats() async {
    return _db.getWorkoutSessionStats();
  }

  Future<Map<String, List<double>>> getWeeklyAllStats() async {
    return _db.getWeeklyAllStats();
  }

  Future<List<Map<String, dynamic>>> getExerciseSetCountsByPeriod(String? startDate) async {
    return _db.getExerciseSetCountsByPeriod(startDate);
  }

  Future<List<Map<String, dynamic>>> getCaloriesPerWorkout(String? startDate) async {
    return _db.getCaloriesPerWorkout(startDate);
  }
}
