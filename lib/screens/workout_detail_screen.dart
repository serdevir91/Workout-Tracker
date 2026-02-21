import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../utils/formatters.dart';
import '../utils/image_mapper.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<WorkoutProvider>();
    final data = await provider.loadWorkoutDetail(widget.workoutId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00D4AA))),
      );
    }

    if (_data == null || _data!['workout'] == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Workout Details'), backgroundColor: Colors.black),
        body: const Center(child: Text('Workout not found', style: TextStyle(color: Colors.white))),
      );
    }

    final workout = _data!['workout'];
    final exercises = _data!['exercises'] as List<Map<String, dynamic>>;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(workout.name),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(workout),
          const SizedBox(height: 24),
          const Text(
            'Exercises',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 12),
          ...exercises.map((exData) => _buildExerciseCard(exData)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(dynamic workout) {
    final duration = workout.totalDuration ?? 0;
    return Card(
      color: const Color(0xFF0F0F12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF222222))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryColumn('Date', formatDate(workout.startTime), Icons.calendar_today, const Color(0xFF6C63FF)),
            _buildSummaryColumn('Time', formatTime(workout.startTime), Icons.access_time, const Color(0xFF00D4AA)),
            _buildSummaryColumn('Duration', formatDuration(duration), Icons.timer, const Color(0xFFFF6B6B)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 12)),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exData) {
    final exercise = exData['exercise'];
    final sets = exData['sets'] as List<dynamic>;

    // Calculate total volume for this exercise
    double volume = 0;
    for (var s in sets) {
      volume += (s.weight * s.reps);
    }

    return Card(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF222222))),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          ImageMapper.getImageForExercise(exercise.name),
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${volume.toStringAsFixed(0)} kg',
                  style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (sets.isEmpty)
              const Text('No sets completed', style: TextStyle(color: Color(0xFF6B6B8D), fontStyle: FontStyle.italic))
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0F0F12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text('Set', style: TextStyle(color: Color(0xFF6B6B8D), fontWeight: FontWeight.w600, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Weight', style: TextStyle(color: Color(0xFF6B6B8D), fontWeight: FontWeight.w600, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Reps', style: TextStyle(color: Color(0xFF6B6B8D), fontWeight: FontWeight.w600, fontSize: 12))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF222222)),
                    ...sets.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(flex: 1, child: Text('${s.setNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          Expanded(flex: 2, child: Text('${s.weight} kg', style: const TextStyle(color: Colors.white))),
                          Expanded(flex: 2, child: Text('${s.reps}', style: const TextStyle(color: Colors.white))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
