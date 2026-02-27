import 'package:flutter/material.dart';
import '../utils/formatters.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final String name;
  final int duration;
  final int setsCompleted;
  final double volume;
  final int calories;

  const WorkoutSummaryScreen({
    super.key,
    required this.name,
    required this.duration,
    required this.setsCompleted,
    required this.volume,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
              const SizedBox(height: 24),
              const Text(
                'Workout Completed!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Color(0xFF00D4AA)),
              ),
              const SizedBox(height: 60),
              _buildStatRow('Duration', formatDuration(duration), Icons.timer),
              _buildStatRow('Total Volume', '${volume.toStringAsFixed(1)} kg', Icons.fitness_center),
              _buildStatRow('Sets Completed', '$setsCompleted', Icons.check_circle),
              _buildStatRow('Est. Calories', '$calories kcal', Icons.local_fire_department),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF222222)),
            ),
            child: Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFFA0A0C0))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}
