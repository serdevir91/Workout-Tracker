import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan_models.dart';
import '../providers/workout_provider.dart';
import 'active_workout_screen.dart';
import '../widgets/exercise_thumbnail.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final plans = provider.workoutPlans;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Workout Plans'),
          ),
          body: plans.isEmpty
              ? Center(child: Text('No custom plans found. Create one from the Home screen!', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    return _buildPlanCard(context, plan);
                  },
                ),
        );
      },
    );
  }

  Widget _buildPlanCard(BuildContext context, WorkoutPlan plan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getDayColors(context, plan.dayNumber),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][plan.dayNumber - 1],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          title: Text(
            plan.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              plan.targetMuscles,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            Divider(color: Theme.of(context).colorScheme.surfaceContainerHighest),
            ...plan.exercises.map((ex) => _buildExerciseRow(context, ex)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startFromPlan(context, plan),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(BuildContext context, PlanExercise exercise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ExerciseThumbnail(exerciseName: exercise.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exercise.name,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exercise.displayInfo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startFromPlan(BuildContext context, WorkoutPlan plan) async {
    final provider = context.read<WorkoutProvider>();
    await provider.startWorkoutFromPlan(plan);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
      );
    }
  }

  List<Color> _getDayColors(BuildContext context, int day) {
    switch (day) {
      case 1:
        return [Theme.of(context).colorScheme.primary, const Color(0xFF9B59B6)];
      case 2:
        return [Theme.of(context).colorScheme.secondary, const Color(0xFF00B894)];
      case 3:
        return [const Color(0xFFFF6B6B), const Color(0xFFE17055)];
      case 4:
        return [const Color(0xFFFFA502), const Color(0xFFFF6348)];
      case 5:
        return [const Color(0xFF3498DB), const Color(0xFF2980B9)];
      default:
        return [Theme.of(context).colorScheme.primary, const Color(0xFF9B59B6)];
    }
  }
}
