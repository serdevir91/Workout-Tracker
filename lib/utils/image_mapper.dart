class ImageMapper {
  static const Map<String, List<String>> _keywordsToImages = {
    'chest.png': ['chest', 'göğüs', 'press', 'fly', 'pec', 'bench', 'pushup'],
    'back.png': ['back', 'sırt', 'pull', 'row', 'lat', 'kanat', 'chin'],
    'legs.png': ['leg', 'bacak', 'squat', 'curl', 'lunge', 'calf', 'extension', 'press'],
    'shoulders.png': ['shoulder', 'omuz', 'deltoid', 'lateral', 'raise', 'military'],
    'arms.png': ['arm', 'kol', 'bicep', 'tricep', 'curl', 'extension', 'pazu', 'arka'],
    'core.png': ['core', 'abs', 'karın', 'mekik', 'crunch', 'plank', 'oblique'],
    'cardio.png': ['cardio', 'kardiyo', 'bike', 'bisiklet', 'run', 'koşu', 'treadmill', 'yürüyüş'],
  };

  static const Map<String, String> _specificExercises = {
    'exercise bike': 'exercise_bike.png',
    '30° incline dumbbell bench press': '30_degree_incline_dumbbell_bench_press.png',
    'seated pec fly': 'seated_pec_fly.png',
    'horizontal barbell bench press': 'horizontal_barbell_bench_press.png',
    'machine shoulder press': 'machine_shoulder_press.png',
    'one-arm cable lateral raise': 'one_arm_cable_lateral_raise.png',
    'incline prone dumbbell row': 'incline_prone_dumbbell_row.png',
    'wide grip lat pulldown': 'wide_grip_lat_pulldown.png',
    'bent-over dumbbell row': 'bent_over_dumbbell_row.png',
    'narrow grip seated row': 'narrow_grip_seated_row.png',
    'standing rope pullover': 'standing_rope_pullover.png',
    'universal lat pulldown machine': 'universal_lat_pulldown_machine.png',
    'romanian deadlift': 'romanian_deadlift.png',
    'triceps pushdown': 'triceps_pushdown.png',
    'standing dumbbell curls': 'standing_dumbbell_curls.png',
    'one-arm scott dumbbell curl': 'one_arm_scott_dumbbell_curl.png',
    'air squats': 'air_squats.png',
    'narrow stance leg press': 'narrow_stance_leg_press.png',
    'seated leg curls': 'seated_leg_curls.png',
    'seated calf raises': 'seated_calf_raises.png',
  };

  static String getImageForExercise(String exerciseName) {
    if (exerciseName.isEmpty) return 'assets/images/exercises/default_workout.png';
    
    final lowerName = exerciseName.toLowerCase();
    
    // First try to find a specific exact match or contained match
    for (var entry in _specificExercises.entries) {
      if (lowerName.contains(entry.key)) {
        return 'assets/images/exercises/${entry.value}';
      }
    }
    
    
    for (var entry in _keywordsToImages.entries) {
      final imageName = entry.key;
      final keywords = entry.value;
      
      for (var keyword in keywords) {
        if (lowerName.contains(keyword)) {
          return 'assets/images/exercises/$imageName';
        }
      }
    }
    
    return 'assets/images/exercises/default_workout.png';
  }
}
