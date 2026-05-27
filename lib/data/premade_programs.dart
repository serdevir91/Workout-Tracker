import '../models/workout_plan_models.dart';

class PremadeProgram {
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final List<WorkoutPlan> plans;

  const PremadeProgram({
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.plans,
  });
}

const List<PremadeProgram> premadePrograms = [
  // PPL
  PremadeProgram(
    name: 'Push / Pull / Legs',
    description: 'Classic 3-day bodybuilding split. Hit each muscle group twice per week with 6 sessions, or once with 3.',
    category: 'Hypertrophy',
    difficulty: 'Intermediate',
    plans: [
      WorkoutPlan(
        dayNumber: 1,
        name: 'Push Day A',
        targetMuscles: 'Chest, Shoulders, Triceps',
        exercises: [
          PlanExercise(name: 'Horizontal Barbell Bench Press', sets: 4, reps: 8, weight: 20),
          PlanExercise(name: '30° Incline Dumbbell Bench Press', sets: 3, reps: 10, weight: 15),
          PlanExercise(name: 'Machine Shoulder Press', sets: 4, reps: 10, weight: 12),
          PlanExercise(name: 'One-arm Cable Lateral Raise', sets: 3, reps: 15, weight: 8),
          PlanExercise(name: 'Seated Pec Fly', sets: 3, reps: 12, weight: 15),
          PlanExercise(name: 'Triceps Pushdown', sets: 3, reps: 12, weight: 30),
        ],
      ),
      WorkoutPlan(
        dayNumber: 2,
        name: 'Pull Day A',
        targetMuscles: 'Back, Biceps, Rear Delts',
        exercises: [
          PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 4, reps: 10, weight: 40),
          PlanExercise(name: 'Narrow Grip Seated Row', sets: 4, reps: 10, weight: 50),
          PlanExercise(name: 'Incline Prone Dumbbell Row', sets: 3, reps: 12, weight: 10),
          PlanExercise(name: 'Face Pull', sets: 3, reps: 15, weight: 15),
          PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 3, reps: 10, weight: 8),
          PlanExercise(name: 'Incline Dumbbell Curl', sets: 3, reps: 12, weight: 6),
        ],
      ),
      WorkoutPlan(
        dayNumber: 3,
        name: 'Legs Day A',
        targetMuscles: 'Quads, Hamstrings, Glutes, Calves',
        exercises: [
          PlanExercise(name: 'Narrow Stance Leg Press', sets: 4, reps: 10, weight: 100),
          PlanExercise(name: 'Romanian Deadlift', sets: 4, reps: 10, weight: 30),
          PlanExercise(name: 'Leg Extension', sets: 3, reps: 12, weight: 40),
          PlanExercise(name: 'Seated Leg Curl', sets: 3, reps: 12, weight: 35),
          PlanExercise(name: 'Bulgarian Split Squat', sets: 3, reps: 10, weight: 10),
          PlanExercise(name: 'Seated Calf Raises', sets: 4, reps: 20, weight: 30),
        ],
      ),
    ],
  ),

  // Upper/Lower
  PremadeProgram(
    name: 'Upper / Lower Split',
    description: '4-day split alternating upper and lower body. Great for balanced strength and muscle growth.',
    category: 'Strength',
    difficulty: 'Intermediate',
    plans: [
      WorkoutPlan(
        dayNumber: 1,
        name: 'Upper Body A',
        targetMuscles: 'Chest, Back, Shoulders, Arms',
        exercises: [
          PlanExercise(name: 'Horizontal Barbell Bench Press', sets: 4, reps: 6, weight: 25),
          PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 4, reps: 8, weight: 45),
          PlanExercise(name: 'Machine Shoulder Press', sets: 3, reps: 8, weight: 15),
          PlanExercise(name: 'Narrow Grip Seated Row', sets: 3, reps: 10, weight: 50),
          PlanExercise(name: 'Seated Pec Fly', sets: 3, reps: 12, weight: 15),
          PlanExercise(name: 'Triceps Pushdown', sets: 3, reps: 10, weight: 30),
          PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 3, reps: 10, weight: 8),
        ],
      ),
      WorkoutPlan(
        dayNumber: 2,
        name: 'Lower Body A',
        targetMuscles: 'Quads, Hamstrings, Glutes, Calves',
        exercises: [
          PlanExercise(name: 'Narrow Stance Leg Press', sets: 4, reps: 8, weight: 120),
          PlanExercise(name: 'Romanian Deadlift', sets: 4, reps: 8, weight: 35),
          PlanExercise(name: 'Leg Extension', sets: 3, reps: 12, weight: 40),
          PlanExercise(name: 'Seated Leg Curl', sets: 3, reps: 12, weight: 35),
          PlanExercise(name: 'Hip Thrust', sets: 3, reps: 10, weight: 40),
          PlanExercise(name: 'Seated Calf Raises', sets: 4, reps: 20, weight: 30),
        ],
      ),
      WorkoutPlan(
        dayNumber: 3,
        name: 'Upper Body B',
        targetMuscles: 'Chest, Back, Shoulders, Arms',
        exercises: [
          PlanExercise(name: '30° Incline Dumbbell Bench Press', sets: 4, reps: 10, weight: 15),
          PlanExercise(name: 'Incline Prone Dumbbell Row', sets: 4, reps: 10, weight: 10),
          PlanExercise(name: 'One-arm Cable Lateral Raise', sets: 3, reps: 15, weight: 8),
          PlanExercise(name: 'Cable Row', sets: 3, reps: 10, weight: 40),
          PlanExercise(name: 'Incline Dumbbell Curl', sets: 3, reps: 12, weight: 6),
          PlanExercise(name: 'Overhead Triceps Extension', sets: 3, reps: 12, weight: 8),
        ],
      ),
      WorkoutPlan(
        dayNumber: 4,
        name: 'Lower Body B',
        targetMuscles: 'Quads, Hamstrings, Glutes, Calves',
        exercises: [
          PlanExercise(name: 'Narrow Stance Leg Press', sets: 4, reps: 10, weight: 100),
          PlanExercise(name: 'Romanian Deadlift', sets: 4, reps: 10, weight: 30),
          PlanExercise(name: 'Bulgarian Split Squat', sets: 3, reps: 10, weight: 10),
          PlanExercise(name: 'Lying Leg Curl', sets: 3, reps: 12, weight: 30),
          PlanExercise(name: 'Standing Calf Raises', sets: 4, reps: 15, weight: 40),
        ],
      ),
    ],
  ),

  // Full Body
  PremadeProgram(
    name: 'Full Body 3x',
    description: '3-day full body routine. Perfect for beginners or those with limited gym time.',
    category: 'Beginner',
    difficulty: 'Beginner',
    plans: [
      WorkoutPlan(
        dayNumber: 1,
        name: 'Full Body A',
        targetMuscles: 'Full Body',
        exercises: [
          PlanExercise(name: 'Horizontal Barbell Bench Press', sets: 3, reps: 10, weight: 20),
          PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 3, reps: 10, weight: 40),
          PlanExercise(name: 'Narrow Stance Leg Press', sets: 3, reps: 12, weight: 80),
          PlanExercise(name: 'Machine Shoulder Press', sets: 3, reps: 10, weight: 12),
          PlanExercise(name: 'Leg Extension', sets: 2, reps: 15, weight: 30),
          PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 2, reps: 12, weight: 6),
          PlanExercise(name: 'Triceps Pushdown', sets: 2, reps: 12, weight: 25),
        ],
      ),
      WorkoutPlan(
        dayNumber: 3,
        name: 'Full Body B',
        targetMuscles: 'Full Body',
        exercises: [
          PlanExercise(name: '30° Incline Dumbbell Bench Press', sets: 3, reps: 10, weight: 12),
          PlanExercise(name: 'Narrow Grip Seated Row', sets: 3, reps: 10, weight: 45),
          PlanExercise(name: 'Romanian Deadlift', sets: 3, reps: 10, weight: 25),
          PlanExercise(name: 'One-arm Cable Lateral Raise', sets: 3, reps: 12, weight: 6),
          PlanExercise(name: 'Seated Leg Curl', sets: 2, reps: 15, weight: 30),
          PlanExercise(name: 'Incline Dumbbell Curl', sets: 2, reps: 12, weight: 5),
          PlanExercise(name: 'Overhead Triceps Extension', sets: 2, reps: 12, weight: 6),
        ],
      ),
      WorkoutPlan(
        dayNumber: 5,
        name: 'Full Body C',
        targetMuscles: 'Full Body',
        exercises: [
          PlanExercise(name: 'Horizontal Barbell Bench Press', sets: 3, reps: 10, weight: 20),
          PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 3, reps: 10, weight: 40),
          PlanExercise(name: 'Bulgarian Split Squat', sets: 3, reps: 10, weight: 8),
          PlanExercise(name: 'Seated Pec Fly', sets: 2, reps: 15, weight: 12),
          PlanExercise(name: 'Incline Prone Dumbbell Row', sets: 2, reps: 12, weight: 8),
          PlanExercise(name: 'Seated Calf Raises', sets: 3, reps: 20, weight: 25),
          PlanExercise(name: 'Plank', sets: 3, reps: 1, durationMinutes: 1),
        ],
      ),
    ],
  ),

  // Chest & Arms
  PremadeProgram(
    name: 'Chest & Arms Focus',
    description: '3-day upper body specialization. Extra volume for chest, biceps, and triceps.',
    category: 'Hypertrophy',
    difficulty: 'Intermediate',
    plans: [
      WorkoutPlan(
        dayNumber: 1,
        name: 'Chest & Triceps',
        targetMuscles: 'Chest, Triceps',
        exercises: [
          PlanExercise(name: 'Horizontal Barbell Bench Press', sets: 4, reps: 8, weight: 25),
          PlanExercise(name: '30° Incline Dumbbell Bench Press', sets: 4, reps: 10, weight: 15),
          PlanExercise(name: 'Seated Pec Fly', sets: 3, reps: 12, weight: 15),
          PlanExercise(name: 'Cable Crossover', sets: 3, reps: 15, weight: 10),
          PlanExercise(name: 'Triceps Pushdown', sets: 4, reps: 10, weight: 30),
          PlanExercise(name: 'Overhead Triceps Extension', sets: 3, reps: 12, weight: 10),
        ],
      ),
      WorkoutPlan(
        dayNumber: 3,
        name: 'Back & Biceps',
        targetMuscles: 'Back, Biceps',
        exercises: [
          PlanExercise(name: 'Wide Grip Lat Pulldown', sets: 4, reps: 10, weight: 45),
          PlanExercise(name: 'Narrow Grip Seated Row', sets: 4, reps: 10, weight: 50),
          PlanExercise(name: 'Incline Prone Dumbbell Row', sets: 3, reps: 12, weight: 10),
          PlanExercise(name: 'Face Pull', sets: 3, reps: 15, weight: 15),
          PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 4, reps: 10, weight: 8),
          PlanExercise(name: 'Incline Dumbbell Curl', sets: 3, reps: 12, weight: 6),
          PlanExercise(name: 'Hammer Curl', sets: 3, reps: 12, weight: 8),
        ],
      ),
      WorkoutPlan(
        dayNumber: 5,
        name: 'Arms & Shoulders',
        targetMuscles: 'Biceps, Triceps, Shoulders',
        exercises: [
          PlanExercise(name: 'Machine Shoulder Press', sets: 4, reps: 10, weight: 15),
          PlanExercise(name: 'One-arm Cable Lateral Raise', sets: 4, reps: 15, weight: 8),
          PlanExercise(name: 'Face Pull', sets: 3, reps: 15, weight: 15),
          PlanExercise(name: 'One-arm Scott Dumbbell Curl', sets: 3, reps: 10, weight: 8),
          PlanExercise(name: 'Triceps Pushdown', sets: 3, reps: 10, weight: 30),
          PlanExercise(name: 'Hammer Curl', sets: 3, reps: 12, weight: 8),
          PlanExercise(name: 'Overhead Triceps Extension', sets: 3, reps: 12, weight: 10),
        ],
      ),
    ],
  ),

  // Legs Focus
  PremadeProgram(
    name: 'Leg Day Specialization',
    description: '3-day lower body focus with progressive volume. Build stronger, bigger legs.',
    category: 'Strength',
    difficulty: 'Intermediate',
    plans: [
      WorkoutPlan(
        dayNumber: 1,
        name: 'Quad Focus',
        targetMuscles: 'Quads, Glutes',
        exercises: [
          PlanExercise(name: 'Narrow Stance Leg Press', sets: 5, reps: 8, weight: 120),
          PlanExercise(name: 'Leg Extension', sets: 4, reps: 12, weight: 45),
          PlanExercise(name: 'Bulgarian Split Squat', sets: 4, reps: 10, weight: 12),
          PlanExercise(name: 'Hip Thrust', sets: 3, reps: 12, weight: 50),
          PlanExercise(name: 'Seated Calf Raises', sets: 4, reps: 20, weight: 35),
        ],
      ),
      WorkoutPlan(
        dayNumber: 3,
        name: 'Hamstring Focus',
        targetMuscles: 'Hamstrings, Glutes, Lower Back',
        exercises: [
          PlanExercise(name: 'Romanian Deadlift', sets: 4, reps: 10, weight: 35),
          PlanExercise(name: 'Seated Leg Curl', sets: 4, reps: 12, weight: 40),
          PlanExercise(name: 'Lying Leg Curl', sets: 3, reps: 12, weight: 35),
          PlanExercise(name: 'Hip Thrust', sets: 4, reps: 10, weight: 50),
          PlanExercise(name: 'Standing Calf Raises', sets: 4, reps: 15, weight: 45),
        ],
      ),
      WorkoutPlan(
        dayNumber: 5,
        name: 'Full Legs',
        targetMuscles: 'Quads, Hamstrings, Glutes, Calves',
        exercises: [
          PlanExercise(name: 'Narrow Stance Leg Press', sets: 4, reps: 10, weight: 100),
          PlanExercise(name: 'Romanian Deadlift', sets: 4, reps: 10, weight: 30),
          PlanExercise(name: 'Leg Extension', sets: 3, reps: 15, weight: 35),
          PlanExercise(name: 'Seated Leg Curl', sets: 3, reps: 15, weight: 30),
          PlanExercise(name: 'Bulgarian Split Squat', sets: 3, reps: 10, weight: 10),
          PlanExercise(name: 'Seated Calf Raises', sets: 4, reps: 20, weight: 30),
        ],
      ),
    ],
  ),

  // Home Workout
  PremadeProgram(
    name: 'Home Workout (No Equipment)',
    description: '3-day bodyweight routine you can do anywhere. No gym needed.',
    category: 'Home',
    difficulty: 'Beginner',
    plans: [
      WorkoutPlan(
        dayNumber: 1,
        name: 'Upper Body (Bodyweight)',
        targetMuscles: 'Chest, Back, Shoulders, Arms',
        exercises: [
          PlanExercise(name: 'Push-Up', sets: 4, reps: 15),
          PlanExercise(name: 'Diamond Push-Up', sets: 3, reps: 10),
          PlanExercise(name: 'Inverted Row', sets: 4, reps: 12),
          PlanExercise(name: 'Pike Push-Up', sets: 3, reps: 10),
          PlanExercise(name: 'Plank', sets: 3, reps: 1, durationMinutes: 1),
          PlanExercise(name: 'Superman', sets: 3, reps: 15),
        ],
      ),
      WorkoutPlan(
        dayNumber: 3,
        name: 'Lower Body (Bodyweight)',
        targetMuscles: 'Quads, Hamstrings, Glutes, Calves',
        exercises: [
          PlanExercise(name: 'Bodyweight Squat', sets: 4, reps: 20),
          PlanExercise(name: 'Lunge', sets: 3, reps: 15),
          PlanExercise(name: 'Glute Bridge', sets: 4, reps: 20),
          PlanExercise(name: 'Wall Sit', sets: 3, reps: 1, durationMinutes: 1),
          PlanExercise(name: 'Calf Raise', sets: 4, reps: 25),
          PlanExercise(name: 'Side Plank', sets: 3, reps: 1, durationMinutes: 1),
        ],
      ),
      WorkoutPlan(
        dayNumber: 5,
        name: 'Full Body (Bodyweight)',
        targetMuscles: 'Full Body',
        exercises: [
          PlanExercise(name: 'Burpee', sets: 3, reps: 10),
          PlanExercise(name: 'Push-Up', sets: 3, reps: 15),
          PlanExercise(name: 'Bodyweight Squat', sets: 3, reps: 20),
          PlanExercise(name: 'Inverted Row', sets: 3, reps: 12),
          PlanExercise(name: 'Lunge', sets: 3, reps: 12),
          PlanExercise(name: 'Plank', sets: 3, reps: 1, durationMinutes: 1),
          PlanExercise(name: 'Mountain Climber', sets: 3, reps: 20),
        ],
      ),
    ],
  ),
];
