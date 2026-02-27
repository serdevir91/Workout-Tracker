/// Workout model - A single training session
class Workout {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalDuration; // seconds
  final double calories; // kcal
  final double completionPercentage;

  Workout({
    this.id,
    required this.name,
    required this.startTime,
    this.endTime,
    this.totalDuration = 0,
    this.calories = 0,
    this.completionPercentage = 100.0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'total_duration': totalDuration,
        'calories': calories,
        'completion_percentage': completionPercentage,
      };

  factory Workout.fromMap(Map<String, dynamic> map) => Workout(
        id: map['id'] as int,
        name: map['name'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        totalDuration: map['total_duration'] as int? ?? 0,
        calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
        completionPercentage: (map['completion_percentage'] as num?)?.toDouble() ?? 100.0,
      );

  Workout copyWith({
    int? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? totalDuration,
    double? calories,
    double? completionPercentage,
  }) =>
      Workout(
        id: id ?? this.id,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        totalDuration: totalDuration ?? this.totalDuration,
        calories: calories ?? this.calories,
        completionPercentage: completionPercentage ?? this.completionPercentage,
      );
}

/// Exercise model - A movement within a workout
class Exercise {
  final int? id;
  final int workoutId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // seconds
  final int exerciseOrder;

  Exercise({
    this.id,
    required this.workoutId,
    required this.name,
    required this.startTime,
    this.endTime,
    this.duration = 0,
    required this.exerciseOrder,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'workout_id': workoutId,
        'name': name,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration': duration,
        'exercise_order': exerciseOrder,
      };

  factory Exercise.fromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as int,
        workoutId: map['workout_id'] as int,
        name: map['name'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        duration: map['duration'] as int? ?? 0,
        exerciseOrder: map['exercise_order'] as int,
      );

  Exercise copyWith({
    int? id,
    int? workoutId,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    int? duration,
    int? exerciseOrder,
  }) =>
      Exercise(
        id: id ?? this.id,
        workoutId: workoutId ?? this.workoutId,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        duration: duration ?? this.duration,
        exerciseOrder: exerciseOrder ?? this.exerciseOrder,
      );
}

/// ExerciseSet model - One set of an exercise
class ExerciseSet {
  final int? id;
  final int exerciseId;
  final int setNumber;
  final double weight; // kg
  final int reps;
  final bool completed;

  ExerciseSet({
    this.id,
    required this.exerciseId,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.completed = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'exercise_id': exerciseId,
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        'completed': completed ? 1 : 0,
      };

  factory ExerciseSet.fromMap(Map<String, dynamic> map) => ExerciseSet(
        id: map['id'] as int,
        exerciseId: map['exercise_id'] as int,
        setNumber: map['set_number'] as int,
        weight: (map['weight'] as num).toDouble(),
        reps: map['reps'] as int,
        completed: (map['completed'] as int? ?? 0) == 1,
      );
}

