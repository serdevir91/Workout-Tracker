/// Represents a pre-built workout plan template
class WorkoutPlan {
  final int dayNumber;
  final String name;
  final String targetMuscles;
  final List<PlanExercise> exercises;

  const WorkoutPlan({
    required this.dayNumber,
    required this.name,
    required this.targetMuscles,
    required this.exercises,
  });
}

/// Represents an exercise within a workout plan
class PlanExercise {
  final String name;
  final int sets;
  final int reps;
  final double weight;
  final int? durationMinutes; // for cardio exercises

  const PlanExercise({
    required this.name,
    required this.sets,
    required this.reps,
    this.weight = 0,
    this.durationMinutes,
  });

  String get displayInfo {
    if (durationMinutes != null) {
      return '$durationMinutes min.';
    }
    if (weight > 0) {
      final weightStr = weight == weight.truncateToDouble()
          ? weight.toInt().toString()
          : weight.toString();
      return '${sets}x$reps × $weightStr kg';
    }
    return '${sets}x$reps';
  }
}

/// All 5 workout day plans extracted from user's training images
const List<WorkoutPlan> defaultWorkoutPlans = [
  // Day 1 - Push A (Chest/Shoulder/Triceps)
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

  // Day 2 - Pull (Back/Biceps)
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

  // Day 3 - Legs
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

  // Day 4 - Push B (variant)
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

  // Day 5 - Full Body (Pull + Legs)
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
