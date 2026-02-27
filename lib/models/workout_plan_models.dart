/// Represents a pre-built workout plan template
class WorkoutPlan {
  final int? id;
  final int dayNumber;
  final String name;
  final String targetMuscles;
  final List<PlanExercise> exercises;

  const WorkoutPlan({
    this.id,
    required this.dayNumber,
    required this.name,
    required this.targetMuscles,
    required this.exercises,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'day_number': dayNumber,
        'name': name,
        'target_muscles': targetMuscles,
      };

  factory WorkoutPlan.fromMap(Map<String, dynamic> map, List<PlanExercise> exercises) {
    return WorkoutPlan(
      id: map['id'] as int,
      dayNumber: map['day_number'] as int,
      name: map['name'] as String,
      targetMuscles: map['target_muscles'] as String,
      exercises: exercises,
    );
  }
  
  WorkoutPlan copyWith({
    int? id,
    int? dayNumber,
    String? name,
    String? targetMuscles,
    List<PlanExercise>? exercises,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      name: name ?? this.name,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      exercises: exercises ?? this.exercises,
    );
  }
}

/// Represents an exercise within a workout plan template
class PlanExercise {
  final int? id;
  final int? templateId;
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final int? durationMinutes;
  final int restSeconds;

  const PlanExercise({
    this.id,
    this.templateId,
    required this.name,
    required this.sets,
    required this.reps,
    this.weight = 0,
    this.durationMinutes,
    this.restSeconds = 60,
  });

  String get displayInfo {
    if (durationMinutes != null) {
      return '$durationMinutes min.';
    }
    if (weight > 0) {
      final weightStr = weight == weight.truncateToDouble()
          ? weight.toInt().toString()
          : weight.toString();
      return '${sets}x$reps × $weightStr kg • $restSeconds s';
    }
    return '${sets}x$reps • $restSeconds s';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'template_id': templateId,
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
        'duration_minutes': durationMinutes,
        'rest_seconds': restSeconds,
      };

  factory PlanExercise.fromMap(Map<String, dynamic> map) {
    return PlanExercise(
      id: map['id'] as int?,
      templateId: map['template_id'] as int?,
      name: map['name'] as String,
      sets: (map['sets'] as num?)?.toInt() ?? 1,
      reps: (map['reps'] as num?)?.toInt() ?? 0,
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: map['duration_minutes'] as int?,
      restSeconds: (map['rest_seconds'] as num?)?.toInt() ?? 60,
    );
  }
  
  PlanExercise copyWith({
    int? id,
    int? templateId,
    String? name,
    int? sets,
    int? reps,
    double? weight,
    int? durationMinutes,
    int? restSeconds,
  }) {
    return PlanExercise(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}

/// Keep the default plans to seed the DB initially
const List<WorkoutPlan> defaultWorkoutPlans = [
  WorkoutPlan(
    dayNumber: 1,
    name: 'Push A',
    targetMuscles: 'Chest, Shoulders, Triceps',
    exercises: [
      PlanExercise(name: 'Exercise Bike', sets: 1, reps: 1, durationMinutes: 15),
      PlanExercise(name: '30° Incline Dumbbell Bench Press', sets: 4, reps: 8, weight: 15),
      PlanExercise(name: 'Seated Pec Fly', sets: 3, reps: 12, weight: 15),
      PlanExercise(name: 'Machine Shoulder Press', sets: 4, reps: 10, weight: 40),
      PlanExercise(name: 'One-arm Cable Lateral Raise', sets: 3, reps: 8, weight: 10),
      PlanExercise(name: 'Incline Prone Dumbbell Row', sets: 3, reps: 12, weight: 10),
      PlanExercise(name: 'Triceps Pushdown', sets: 4, reps: 10, weight: 40),
    ],
  ),
  WorkoutPlan(
    dayNumber: 2,
    name: 'Pull',
    targetMuscles: 'Back, Biceps',
    exercises: [
      PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 4, reps: 10, weight: 45),
      PlanExercise(name: 'Bent-over Dumbbell Row', sets: 4, reps: 10, weight: 25),
      PlanExercise(name: 'Narrow Grip Seated Row', sets: 3, reps: 12, weight: 55),
      PlanExercise(name: 'Standing Rope Pullover', sets: 3, reps: 12, weight: 40),
      PlanExercise(name: 'Universal Lat Pulldown Machine', sets: 3, reps: 6),
      PlanExercise(name: 'Standing Dumbbell Curls', sets: 4, reps: 8, weight: 15),
      PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 4, reps: 8, weight: 10),
    ],
  ),
  WorkoutPlan(
    dayNumber: 3,
    name: 'Legs',
    targetMuscles: 'Quads, Hamstrings, Calves',
    exercises: [
      PlanExercise(name: 'Exercise Bike', sets: 1, reps: 1, durationMinutes: 15),
      PlanExercise(name: 'Air Squats', sets: 4, reps: 10),
      PlanExercise(name: 'Narrow Stance Leg Press', sets: 4, reps: 10, weight: 100),
      PlanExercise(name: 'Seated Leg Curls', sets: 5, reps: 12, weight: 45),
      PlanExercise(name: 'Seated Calf Raises', sets: 4, reps: 20, weight: 25),
    ],
  ),
  WorkoutPlan(
    dayNumber: 4,
    name: 'Push B',
    targetMuscles: 'Chest, Shoulders, Triceps',
    exercises: [
      PlanExercise(name: 'Horizontal Barbell Bench Press', sets: 4, reps: 8, weight: 20),
      PlanExercise(name: '30° Incline Dumbbell Bench Press', sets: 4, reps: 8, weight: 15),
      PlanExercise(name: 'Seated Pec Fly', sets: 3, reps: 12, weight: 15),
      PlanExercise(name: 'Machine Shoulder Press', sets: 4, reps: 8, weight: 12),
      PlanExercise(name: 'One-arm Cable Lateral Raise', sets: 4, reps: 12, weight: 10),
      PlanExercise(name: 'Incline Prone Dumbbell Row', sets: 3, reps: 12, weight: 8),
      PlanExercise(name: 'Triceps Pushdown', sets: 4, reps: 10, weight: 35),
    ],
  ),
  WorkoutPlan(
    dayNumber: 5,
    name: 'Full Body',
    targetMuscles: 'Back, Biceps, Legs',
    exercises: [
      PlanExercise(name: 'Exercise Bike', sets: 1, reps: 1, durationMinutes: 15),
      PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 4, reps: 10, weight: 40),
      PlanExercise(name: 'Narrow Grip Seated Row', sets: 4, reps: 12, weight: 50),
      PlanExercise(name: 'Romanian Deadlift', sets: 4, reps: 8, weight: 20),
      PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 4, reps: 8, weight: 8),
      PlanExercise(name: 'Narrow Stance Leg Press', sets: 5, reps: 8, weight: 100),
      PlanExercise(name: 'Seated Calf Raises', sets: 4, reps: 20),
    ],
  ),
];
