import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/settings_provider.dart';
import '../l10n/translations.dart';
import '../utils/formatters.dart';
import 'settings_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, num>? _stats;
  List<Map<String, dynamic>> _sessionStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider = context.read<WorkoutProvider>();
    try {
      final stats = await provider.getStats();
      final sessionStats = await provider.getWorkoutSessionStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _sessionStats = sessionStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading stats: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary)),
      );
    }

    final totalWorkouts = _stats?['totalWorkouts']?.toInt() ?? 0;
    final totalDuration = _stats?['totalDuration']?.toInt() ?? 0;
    final totalVolume = _stats?['totalVolume']?.toDouble() ?? 0.0;
    final totalSets = _stats?['totalSets']?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(Translations.of(context).get('stats')),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dashboard Grid
          Text(
            'Overview',
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildExpandableStatCard(Translations.of(context).get('total_workouts'), '$totalWorkouts', Icons.fitness_center, Theme.of(context).colorScheme.primary, ''),
              _buildExpandableStatCard(Translations.of(context).get('total_volume'), context.read<SettingsProvider>().formatWeight(totalVolume), Icons.monitor_weight_outlined, Theme.of(context).colorScheme.secondary, ''),
              _buildExpandableStatCard(Translations.of(context).get('total_duration'), formatDuration(totalDuration), Icons.timer_outlined, const Color(0xFFFF6B6B), ''),
              _buildExpandableStatCard(Translations.of(context).get('total_sets'), '$totalSets', Icons.repeat, const Color(0xFFFFAE42), ''),
            ],
          ),
          const SizedBox(height: 32),
          
          // Workout Sessions Breakdown
          Text(
            'Workout Sessions Breakdown',
            style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_sessionStats.isEmpty)
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 32),
               child: Center(child: Text('No workout session data yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
             )
          else
            ..._sessionStats.map((sess) => _buildSessionStatCard(sess)),
        ],
      ),
    );
  }

  Widget _buildExpandableStatCard(String title, String value, IconData icon, Color color, String details) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconColor: Theme.of(context).colorScheme.onSurface,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 72, right: 16, bottom: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 4),
                    Text(details, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }


  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildSessionStatCard(Map<String, dynamic> sess) {
    final name = sess['name'] as String;
    final date = DateTime.parse(sess['start_time'] as String);
    final totalExercises = sess['total_exercises'] as int;
    final totalSets = sess['total_sets'] as int;
    final totalVolume = (sess['total_volume'] as num).toDouble();
    final totalReps = sess['total_reps'] as int;
    final duration = sess['total_duration'] as int;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
          iconColor: Theme.of(context).colorScheme.onSurface,
          title: Row(
            children: [
              Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface))),
              Text('${totalVolume.toStringAsFixed(0)} kg', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
            ],
          ),
          subtitle: Text('${date.day}/${date.month}/${date.year} • ${formatDuration(duration)}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildMiniStat('Exercises', '$totalExercises', const Color(0xFFFF6B6B)),
                   _buildMiniStat('Sets', '$totalSets', Theme.of(context).colorScheme.primary),
                   _buildMiniStat('Reps', '$totalReps', const Color(0xFFFFAE42)),
                ],
              ),
            ),
            if (sess['exercises'] != null && (sess['exercises'] as List).isNotEmpty) ...[
            Divider(color: Theme.of(context).colorScheme.outline, height: 1),
              ...((sess['exercises'] as List).map((ex) {
                final exName = ex['name'] as String;
                final exSets = ex['sets'] as int;
                final exReps = ex['reps'] as int;
                final maxWeight = (ex['max_weight'] as num?)?.toDouble() ?? 0.0;
                final duration = (ex['duration'] as int?) ?? 0;
                final durationStr = '${(duration ~/ 60).toString().padLeft(2, '0')}:${(duration % 60).toString().padLeft(2, '0')}';
                final isCardioEx = ActiveExercise.detectCardio(exName) || (maxWeight == 0 && exReps > 0 && exSets <= 2);
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            if (isCardioEx)
                              Text('$exSets Sets  •  $exReps min  •  $durationStr', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))
                            else
                              Text('$exSets Sets  •  $exReps Reps  •  $durationStr', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: isCardioEx
                          ? Text('$exReps min', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right)
                          : Text('${maxWeight.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')} kg', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList()),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
