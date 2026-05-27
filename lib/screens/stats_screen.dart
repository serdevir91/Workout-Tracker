import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/streak_achievements.dart';
import '../utils/body_composition.dart';
import '../utils/formatters.dart';
import '../widgets/entitlement_badge.dart';
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
  Map<String, dynamic> _streak = <String, dynamic>{};
  Set<String> _unlockedAchievementKeys = <String>{};
  int _totalCompletedSets = 0;
  int _completionThreshold = 80;

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
      final settings = context.read<SettingsProvider>();
      final sessions = await provider.getWorkoutSessionStats();
      final insights = await provider.getStatsInsights(
        workoutDays: settings.workoutDays,
        completionThreshold: 80,
      );
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _streak = insights['streak'] as Map<String, dynamic>? ??
            <String, dynamic>{};
        _unlockedAchievementKeys =
            insights['unlockedAchievementKeys'] as Set<String>? ??
                <String>{};
        _totalCompletedSets =
          (insights['totalCompletedSets'] as num?)?.toInt() ??
          (insights['totalCompletedReps'] as num?)?.toInt() ??
          0;
        _completionThreshold =
            (insights['completionThreshold'] as num?)?.toInt() ?? 80;
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

  String _movementTypeLabel(Translations t, String type) {
    switch (type) {
      case 'Push':
        return t.get('movement_type_push');
      case 'Pull':
        return t.get('movement_type_pull');
      case 'Legs':
        return t.get('movement_type_legs');
      case 'Core':
        return t.get('movement_type_core');
      case 'Cardio':
        return t.get('movement_type_cardio');
      case 'Other':
      default:
        return t.get('movement_type_other');
    }
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

  String _movementType(String exerciseName) {
    final name = exerciseName.toLowerCase();
    if (ActiveExercise.detectCardio(name)) {
      return 'Cardio';
    }

    const pushWords = <String>[
      'bench',
      'press',
      'dip',
      'push',
      'tricep',
      'shoulder',
      'chest',
      'fly',
    ];
    const pullWords = <String>[
      'row',
      'pull',
      'chin',
      'lat',
      'back',
      'bicep',
      'curl',
      'deadlift',
    ];
    const legWords = <String>[
      'squat',
      'leg',
      'lunge',
      'hamstring',
      'quad',
      'calf',
      'glute',
      'hip thrust',
    ];
    const coreWords = <String>[
      'plank',
      'crunch',
      'sit up',
      'ab',
      'core',
      'twist',
    ];

    if (pushWords.any(name.contains)) return 'Push';
    if (pullWords.any(name.contains)) return 'Pull';
    if (legWords.any(name.contains)) return 'Legs';
    if (coreWords.any(name.contains)) return 'Core';
    return 'Other';
  }

  List<Map<String, dynamic>> _bestByMovementType(
    List<MapEntry<String, Map<String, num>>> exercises,
  ) {
    final byType = <String, MapEntry<String, Map<String, num>>>{};
    for (final exercise in exercises) {
      final type = _movementType(exercise.key);
      final current = byType[type];
      if (current == null || _d(exercise.value['vol']) > _d(current.value['vol'])) {
        byType[type] = exercise;
      }
    }

    const order = ['Push', 'Pull', 'Legs', 'Core', 'Cardio', 'Other'];
    return order
        .where(byType.containsKey)
        .map((type) => {
              'type': type,
              'name': byType[type]!.key,
              'sets': _i(byType[type]!.value['sets']),
              'reps': _i(byType[type]!.value['reps']),
              'vol': _d(byType[type]!.value['vol']),
            })
        .toList();
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
    final allTopExercises = _topExercises(data);
    final top = allTopExercises.take(12).toList();
    final movementHighlights = _bestByMovementType(allTopExercises);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('stats')),
        elevation: 0,
        actions: [
          ...buildEntitlementBadgeActions(context),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
                    Theme.of(context).colorScheme.secondary.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.get('performance_dashboard'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s['totalWorkouts']} ${t.get('workouts').toLowerCase()} | ${s['activeDays']} ${t.get('active_days')}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _StatsRange.values
                  .map(
                    (r) => ChoiceChip(
                      label: Text(_rangeLabel(t, r)),
                      selected: _selectedRange == r,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedRange = r),
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.18),
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
            _buildBodyCompositionCard(context, settings),
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
                  '${s['activeDays']} ${t.get('active_days')}',
                ),
                _tile(
                  context,
                  Icons.monitor_weight_outlined,
                  t.get('total_volume'),
                  settings.formatWeight(_d(s['totalVolume'])),
                  '${settings.formatWeight(_d(s['avgVolume']))} ${t.get('per_workout')}',
                ),
                _tile(
                  context,
                  Icons.timer_outlined,
                  t.get('total_duration'),
                  formatDuration(_i(s['totalDuration'])),
                  '${formatDuration(_i(s['avgDuration']))} ${t.get('per_workout')}',
                ),
                _tile(
                  context,
                  Icons.show_chart,
                  t.get('consistency'),
                  '${(_d(s['workoutsPerWeek'])).toStringAsFixed(1)} ${t.get('per_week')}',
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
                      t.get('avg_sets_per_workout'),
                      (_d(s['avgSets'])).toStringAsFixed(1),
                    ),
                    _chip(
                      context,
                      t.get('avg_reps_per_set'),
                      (_d(s['avgRepsPerSet'])).toStringAsFixed(1),
                    ),
                    _chip(
                      context,
                      t.get('avg_completion'),
                      '${_d(s['avgCompletion']).toStringAsFixed(0)}%',
                    ),
                    _chip(
                      context,
                      t.get('total_calories'),
                      _d(s['totalCalories']).toStringAsFixed(0),
                    ),
                    _chip(context, t.get('total_reps'), '${s['totalReps']}'),
                    _chip(
                      context,
                      t.get('longest_session_label'),
                      formatDuration(_i(s['longestDuration'])),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.get('streak_and_rewards'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildStreakCard(context, t),
            const SizedBox(height: 10),
            _buildAchievementsCard(context, t),
            const SizedBox(height: 14),
            Text(
              t.get('movement_highlights'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildMovementHighlightsCard(
              context,
              t,
              settings,
              movementHighlights,
              s,
            ),
            const SizedBox(height: 14),
            Text(
              t.get('top_exercises'),
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
                        t.get('no_exercise_detail_period'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      children: List.generate(top.take(6).length, (i) {
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
              '${t.get('workout_sessions')} (${data.length})',
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
                    t.get('no_workout_sessions_period'),
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

  Widget _buildStreakCard(BuildContext context, Translations t) {
    final int currentStreakDays = _i(_streak['currentStreakDays']);
    final int longestStreakDays = _i(_streak['longestStreakDays']);
    final int recentRequiredDays = _i(_streak['recentRequiredDays']);
    final int recentCompletedDays = _i(_streak['recentCompletedDays']);
    final double adherenceRate = _d(_streak['recentAdherenceRate']);
    final int? nextMilestoneDays = (_streak['nextMilestoneDays'] as num?)
        ?.toInt();
    final bool scheduledToday = _streak['scheduledToday'] == true;
    final bool completedToday = _streak['completedToday'] == true;
    final bool offDayToday = _streak['offDayToday'] == true;

    String todayStatus;
    if (offDayToday) {
      todayStatus = t.get('streak_off_day_today');
    } else if (scheduledToday && completedToday) {
      todayStatus = t.get('streak_completed_today');
    } else if (scheduledToday) {
      todayStatus = '${t.get('streak_pending_today')} >= $_completionThreshold%';
    } else {
      todayStatus = t.get('streak_no_planned_today');
    }

    final double progressToNext = nextMilestoneDays == null
        ? 1
        : (currentStreakDays / nextMilestoneDays).clamp(0.0, 1.0);

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  t.get('current_streak'),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$currentStreakDays ${t.get('day').toLowerCase()}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              todayStatus,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(
                  context,
                  t.get('longest_streak'),
                  '$longestStreakDays ${t.get('day').toLowerCase()}',
                ),
                _chip(
                  context,
                  t.get('adherence_last_4_weeks'),
                  '${(adherenceRate * 100).toStringAsFixed(0)}%',
                ),
                _chip(
                  context,
                  t.get('completed_planned_days'),
                  '$recentCompletedDays/$recentRequiredDays',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              nextMilestoneDays == null
                  ? t.get('all_streak_milestones_unlocked')
                  : '${t.get('next_milestone')}: ${_streakMilestoneLabel(t, nextMilestoneDays)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progressToNext,
                backgroundColor: Theme.of(context).colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard(BuildContext context, Translations t) {
    final int currentStreakDays = _i(_streak['currentStreakDays']);

    final List<Map<String, dynamic>> trophies = <Map<String, dynamic>>[
      ...kSetMilestones.map((int threshold) {
        final String key = setAchievementKey(threshold);
        return <String, dynamic>{
          'key': key,
          'label': _setMilestoneLabel(t, threshold),
          'valueLabel': '$threshold ${t.get('sets').toLowerCase()}',
          'unlocked': _unlockedAchievementKeys.contains(key),
          'icon': Icons.emoji_events_rounded,
          'progress': _totalCompletedSets >= threshold
              ? 1.0
              : (_totalCompletedSets / threshold).clamp(0.0, 1.0),
        };
      }),
      ...kStreakMilestones.map((int threshold) {
        final String key = streakAchievementKey(threshold);
        return <String, dynamic>{
          'key': key,
          'label': _streakMilestoneLabel(t, threshold),
          'valueLabel': '$threshold ${t.get('day').toLowerCase()}',
          'unlocked': _unlockedAchievementKeys.contains(key),
          'icon': Icons.local_fire_department_rounded,
          'progress': currentStreakDays >= threshold
              ? 1.0
              : (currentStreakDays / threshold).clamp(0.0, 1.0),
        };
      }),
    ];

    return Card(
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
              t.get('trophies'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final int columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 640
                        ? 3
                        : 2;
                return GridView.builder(
                  itemCount: trophies.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.06,
                  ),
                  itemBuilder: (context, index) {
                    final trophy = trophies[index];
                    final bool unlocked = trophy['unlocked'] == true;
                    final double progress = _d(trophy['progress']);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: unlocked
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.55)
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                trophy['icon'] as IconData,
                                size: 18,
                                color: unlocked
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              const Spacer(),
                              Icon(
                                unlocked
                                    ? Icons.check_circle_rounded
                                    : Icons.lock_outline_rounded,
                                size: 16,
                                color: unlocked
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            trophy['label'] as String,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            trophy['valueLabel'] as String,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: progress,
                              backgroundColor:
                                  Theme.of(context).colorScheme.surfaceContainerHigh,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                unlocked
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovementHighlightsCard(
    BuildContext context,
    Translations t,
    SettingsProvider settings,
    List<Map<String, dynamic>> movementHighlights,
    Map<String, dynamic> summary,
  ) {
    return Card(
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
            if (movementHighlights.isEmpty)
              Text(
                t.get('no_exercise_detail_period'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = constraints.maxWidth >= 920
                      ? 3
                      : constraints.maxWidth >= 420
                          ? 2
                          : 1;
                  final double itemWidth =
                      (constraints.maxWidth - ((columns - 1) * 10)) / columns;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: movementHighlights.map((entry) {
                      final name = entry['name'] as String;
                      final sets = _i(entry['sets']);
                      final reps = _i(entry['reps']);
                      final vol = _d(entry['vol']);
                      return Container(
                        width: itemWidth,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _movementTypeLabel(t, entry['type'] as String),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$sets ${t.get('sets').toLowerCase()} | $reps ${t.get('reps').toLowerCase()}',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              settings.formatWeight(vol),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 10),
            Text(
              '${t.get('best_volume_session')}: ${summary['bestName']} (${settings.formatWeight(_d(summary['bestVolume']))})',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${t.get('longest_session_label')}: ${summary['longestName']} (${formatDuration(_i(summary['longestDuration']))})',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _setMilestoneLabel(Translations t, int threshold) {
    switch (threshold) {
      case 50:
        return t.get('reps_trophy_50');
      case 100:
        return t.get('reps_trophy_100');
      case 1000:
        return t.get('reps_trophy_1000');
      default:
        return '$threshold ${t.get('sets').toLowerCase()}';
    }
  }

  String _streakMilestoneLabel(Translations t, int days) {
    switch (days) {
      case 7:
        return t.get('streak_milestone_1_week');
      case 14:
        return t.get('streak_milestone_2_weeks');
      case 30:
        return t.get('streak_milestone_1_month');
      default:
        return '$days ${t.get('day').toLowerCase()}';
    }
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

  Widget _buildBodyCompositionCard(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final composition = settings.gender == null
        ? null
        : BodyCompositionCalculator.calculate(
            gender: settings.gender!,
            heightCm: settings.height,
            weightKg: settings.weight,
            waistCm: settings.waistCircumference,
            neckCm: settings.neckCircumference,
            hipCm: settings.hipCircumference,
          );

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: composition == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.get('body_composition'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.get('body_composition_hint'),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Text(t.get('complete_body_stats')),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.get('body_composition'),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _chip(
                        context,
                        t.get('body_fat'),
                        '${composition.bodyFatPercentage.toStringAsFixed(1)}%',
                      ),
                      _chip(
                        context,
                        t.get('fat_mass'),
                        settings.formatWeight(composition.fatMassKg),
                      ),
                      _chip(
                        context,
                        t.get('lean_mass'),
                        settings.formatWeight(composition.leanMassKg),
                      ),
                      _chip(
                        context,
                        t.get('bmi'),
                        composition.bmi.toStringAsFixed(1),
                      ),
                      _chip(
                        context,
                        t.get('weight_status'),
                        _bmiStatusLabel(t, composition.bmiCategory),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  String _bmiStatusLabel(Translations t, BmiCategory category) {
    switch (category) {
      case BmiCategory.underweight:
        return t.get('underweight');
      case BmiCategory.normal:
        return t.get('normal_weight');
      case BmiCategory.overweight:
        return t.get('overweight');
      case BmiCategory.obese:
        return t.get('obese');
    }
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
