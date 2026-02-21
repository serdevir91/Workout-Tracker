import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan_models.dart';
import '../providers/workout_provider.dart';
import 'active_workout_screen.dart';
import '../utils/image_mapper.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plans'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: defaultWorkoutPlans.length,
        itemBuilder: (context, index) {
          final plan = defaultWorkoutPlans[index];
          return _buildPlanCard(context, plan);
        },
      ),
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
                colors: _getDayColors(plan.dayNumber),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'D${plan.dayNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
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
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFA0A0C0),
              ),
            ),
          ),
          children: [
            const Divider(color: Color(0xFF252547)),
            ...plan.exercises.map((ex) => _buildExerciseRow(ex)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startFromPlan(context, plan),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: const Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRow(PlanExercise exercise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              ImageMapper.getImageForExercise(exercise.name),
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
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
              color: const Color(0xFF252547),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              exercise.displayInfo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00D4AA),
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

  List<Color> _getDayColors(int day) {
    switch (day) {
      case 1:
        return [const Color(0xFF6C63FF), const Color(0xFF9B59B6)];
      case 2:
        return [const Color(0xFF00D4AA), const Color(0xFF00B894)];
      case 3:
        return [const Color(0xFFFF6B6B), const Color(0xFFE17055)];
      case 4:
        return [const Color(0xFFFFA502), const Color(0xFFFF6348)];
      case 5:
        return [const Color(0xFF3498DB), const Color(0xFF2980B9)];
      default:
        return [const Color(0xFF6C63FF), const Color(0xFF9B59B6)];
    }
  }
}
