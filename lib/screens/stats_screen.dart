import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/formatters.dart';
import 'settings_screen.dart';

enum _StatsRange { week, month, all }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  int _lastKnownWorkoutCount = -1;
  _StatsRange _selectedRange = _StatsRange.month;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.watch<WorkoutProvider>();
    final count = provider.workouts.length;
    if (_lastKnownWorkoutCount != -1 && _lastKnownWorkoutCount != count) {
      _loadStats();
    }
    _lastKnownWorkoutCount = count;
  }

  Future<void> _loadStats() async {
    try {
      final provider = context.read<WorkoutProvider>();
      final sessions = await provider.getWorkoutSessionStats();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  DateTime _date(Map<String, dynamic> s) =>
      DateTime.tryParse(s['start_time'] as String? ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);
  int _i(dynamic v) => v is num ? v.toInt() : 0;
  double _d(dynamic v) => v is num ? v.toDouble() : 0;

  DateTime? _rangeStart() {
    final now = DateTime.now();
    switch (_selectedRange) {
      case _StatsRange.week:
        return now.subtract(const Duration(days: 7));
      case _StatsRange.month:
        return now.subtract(const Duration(days: 30));
      case _StatsRange.all:
        return null;
    }
  }

  List<Map<String, dynamic>> _filtered() {
    final start = _rangeStart();
    if (start == null) return List<Map<String, dynamic>>.from(_sessions);
    return _sessions.where((s) => !_date(s).isBefore(start)).toList();
  }

  Map<String, dynamic> _summary(List<Map<String, dynamic>> data) {
    final totalWorkouts = data.length;
    final totalDuration = data.fold<int>(
      0,
      (a, s) => a + _i(s['total_duration']),
    );
    final totalVolume = data.fold<double>(
      0,
      (a, s) => a + _d(s['total_volume']),
    );
    final totalSets = data.fold<int>(0, (a, s) => a + _i(s['total_sets']));
    final totalReps = data.fold<int>(0, (a, s) => a + _i(s['total_reps']));
    final totalCalories = data.fold<double>(0, (a, s) => a + _d(s['calories']));
    final avgCompletion = totalWorkouts == 0
        ? 0
        : data.fold<double>(0, (a, s) => a + _d(s['completion_percentage'])) /
              totalWorkouts;

    final avgDuration = totalWorkouts == 0
        ? 0
        : (totalDuration / totalWorkouts).round();
    final avgSets = totalWorkouts == 0 ? 0 : totalSets / totalWorkouts;
    final avgRepsPerSet = totalSets == 0 ? 0 : totalReps / totalSets;
    final avgVolume = totalWorkouts == 0 ? 0 : totalVolume / totalWorkouts;

    final uniqueDays = <String>{};
    for (final s in data) {
      final d = _date(s);
      uniqueDays.add('${d.year}-${d.month}-${d.day}');
    }
    final activeDays = uniqueDays.length;

    final byVolume = data.isEmpty
        ? null
        : data.reduce(
            (a, b) => _d(a['total_volume']) >= _d(b['total_volume']) ? a : b,
          );
    final longest = data.isEmpty
        ? null
        : data.reduce(
            (a, b) =>
                _i(a['total_duration']) >= _i(b['total_duration']) ? a : b,
          );

    final start =
        _rangeStart() ?? (data.isEmpty ? DateTime.now() : _date(data.last));
    final daysSpan = math.max(
      1,
      DateTime.now()
              .difference(DateTime(start.year, start.month, start.day))
              .inDays +
          1,
    );
    final workoutsPerWeek = totalWorkouts / (daysSpan / 7);

    return {
      'totalWorkouts': totalWorkouts,
      'totalDuration': totalDuration,
      'totalVolume': totalVolume,
      'totalSets': totalSets,
      'totalReps': totalReps,
      'totalCalories': totalCalories,
      'avgCompletion': avgCompletion,
      'avgDuration': avgDuration,
      'avgSets': avgSets,
      'avgRepsPerSet': avgRepsPerSet,
      'avgVolume': avgVolume,
      'activeDays': activeDays,
      'workoutsPerWeek': workoutsPerWeek,
      'bestName': byVolume?['name'] ?? '-',
      'bestVolume': byVolume == null ? 0.0 : _d(byVolume['total_volume']),
      'longestName': longest?['name'] ?? '-',
      'longestDuration': longest == null ? 0 : _i(longest['total_duration']),
    };
  }

  List<MapEntry<String, Map<String, num>>> _topExercises(
    List<Map<String, dynamic>> data,
  ) {
    final map = <String, Map<String, num>>{};
    for (final s in data) {
      final exs = s['exercises'] as List<dynamic>? ?? const [];
      for (final raw in exs) {
        final ex = raw as Map<String, dynamic>;
        final name = (ex['name'] as String?)?.trim();
        if (name == null || name.isEmpty) continue;
        final agg = map.putIfAbsent(
          name,
          () => {'sets': 0, 'reps': 0, 'vol': 0},
        );
        agg['sets'] = (agg['sets'] ?? 0) + _i(ex['sets']);
        agg['reps'] = (agg['reps'] ?? 0) + _i(ex['reps']);
        agg['vol'] = (agg['vol'] ?? 0) + _d(ex['total_volume']);
      }
    }
    final list = map.entries.toList()
      ..sort((a, b) => (b.value['vol'] ?? 0).compareTo(a.value['vol'] ?? 0));
    return list;
  }

  String _rangeLabel(Translations t, _StatsRange r) {
    switch (r) {
      case _StatsRange.week:
        return t.get('week');
      case _StatsRange.month:
        return t.get('month');
      case _StatsRange.all:
        return t.get('all_time');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      );
    }

    final t = Translations.of(context);
    final settings = context.watch<SettingsProvider>();
    final data = _filtered();
    final s = _summary(data);
    final top = _topExercises(data).take(6).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('stats')),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Performance Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _StatsRange.values
                  .map(
                    (r) => ChoiceChip(
                      label: Text(_rangeLabel(t, r)),
                      selected: _selectedRange == r,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedRange = r),
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.16),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHigh,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
              children: [
                _tile(
                  context,
                  Icons.fitness_center,
                  t.get('total_workouts'),
                  '${s['totalWorkouts']}',
                  '${s['activeDays']} active days',
                ),
                _tile(
                  context,
                  Icons.monitor_weight_outlined,
                  t.get('total_volume'),
                  settings.formatWeight(_d(s['totalVolume'])),
                  '${settings.formatWeight(_d(s['avgVolume']))} / workout',
                ),
                _tile(
                  context,
                  Icons.timer_outlined,
                  t.get('total_duration'),
                  formatDuration(_i(s['totalDuration'])),
                  '${formatDuration(_i(s['avgDuration']))} / workout',
                ),
                _tile(
                  context,
                  Icons.show_chart,
                  'Consistency',
                  '${(_d(s['workoutsPerWeek'])).toStringAsFixed(1)} / week',
                  '${s['totalSets']} sets',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      context,
                      'Avg sets/workout',
                      (_d(s['avgSets'])).toStringAsFixed(1),
                    ),
                    _chip(
                      context,
                      'Avg reps/set',
                      (_d(s['avgRepsPerSet'])).toStringAsFixed(1),
                    ),
                    _chip(
                      context,
                      'Avg completion',
                      '${_d(s['avgCompletion']).toStringAsFixed(0)}%',
                    ),
                    _chip(
                      context,
                      'Total calories',
                      _d(s['totalCalories']).toStringAsFixed(0),
                    ),
                    _chip(context, 'Total reps', '${s['totalReps']}'),
                    _chip(
                      context,
                      'Longest session',
                      formatDuration(_i(s['longestDuration'])),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Highlights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best volume session: ${s['bestName']} (${settings.formatWeight(_d(s['bestVolume']))})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Longest session: ${s['longestName']} (${formatDuration(_i(s['longestDuration']))})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Top Exercises',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              child: top.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No exercise detail available for this period.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(top.length, (i) {
                        final e = top[i];
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.18),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          title: Text(
                            e.key,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${e.value['sets']} sets | ${e.value['reps']} reps',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: Text(
                            settings.formatWeight(_d(e.value['vol'])),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              'Workout Sessions (${data.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            if (data.isEmpty)
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No workout sessions in this period.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...data.map((sess) => _sessionCard(context, settings, sess)),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    String subtitle,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionCard(
    BuildContext context,
    SettingsProvider settings,
    Map<String, dynamic> sess,
  ) {
    final date = _date(sess);
    final exs = sess['exercises'] as List<dynamic>? ?? const [];
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text(
          sess['name'] as String? ?? '-',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          formatDateWithTime(date, locale: settings.intlLocale),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        collapsedIconColor: Theme.of(context).colorScheme.onSurfaceVariant,
        iconColor: Theme.of(context).colorScheme.onSurface,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  context,
                  'Volume',
                  settings.formatWeight(_d(sess['total_volume'])),
                ),
                _chip(
                  context,
                  'Duration',
                  formatDuration(_i(sess['total_duration'])),
                ),
                _chip(context, 'Sets', '${_i(sess['total_sets'])}'),
                _chip(context, 'Reps', '${_i(sess['total_reps'])}'),
                _chip(
                  context,
                  'Calories',
                  _d(sess['calories']).toStringAsFixed(0),
                ),
                _chip(
                  context,
                  'Completion',
                  '${_d(sess['completion_percentage']).toStringAsFixed(0)}%',
                ),
              ],
            ),
          ),
          if (exs.isNotEmpty)
            Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          ...exs.map((raw) {
            final ex = raw as Map<String, dynamic>;
            final name = ex['name'] as String? ?? '-';
            final sets = _i(ex['sets']);
            final reps = _i(ex['reps']);
            final maxWeight = _d(ex['max_weight']);
            final duration = _i(ex['duration']);
            final isCardio =
                ActiveExercise.detectCardio(name) ||
                (maxWeight == 0 && reps > 0 && sets <= 2);
            return ListTile(
              dense: true,
              title: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                isCardio
                    ? '$sets sets | $reps min | ${formatDuration(duration)}'
                    : '$sets sets | $reps reps | ${formatDuration(duration)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                isCardio ? '$reps min' : settings.formatWeight(maxWeight),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
