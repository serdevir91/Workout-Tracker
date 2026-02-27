import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_models.dart';
import '../providers/workout_provider.dart';
import '../utils/formatters.dart';
import '../utils/exrx_url_matcher.dart';
import 'active_workout_screen.dart';
import 'workout_detail_screen.dart';
import 'stats_screen.dart';
import 'exercise_library_screen.dart';
import 'create_routine_screen.dart';
import 'settings_screen.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<double> _weeklyVolumes = [];
  List<double> _weeklyReps = [];
  List<double> _weeklySets = [];
  String _selectedChartType = 'Volume'; // Volume, Reps, Sets
  int _selectedIndex = 0;

  // Dashboard chart data
  String _muscleGroupPeriod = 'All time';
  String _caloriesPeriod = 'All time';
  Map<String, double> _muscleGroupData = {};
  List<Map<String, dynamic>> _caloriesData = [];

  // Track workout count to detect changes and refresh charts
  int _lastKnownWorkoutCount = -1;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeeklyData();
      _loadDashboardCharts();
    });
  }
  
  void _loadWeeklyData() async {
    try {
      final provider = context.read<WorkoutProvider>();
      final stats = await provider.getWeeklyAllStats();
      if (mounted) {
        setState(() {
          _weeklyVolumes = stats['volume']!;
          _weeklyReps = stats['reps']!;
          _weeklySets = stats['sets']!;
        });
      }
    } catch (e) {
      debugPrint('Error loading weekly data: $e');
    }
  }

  String? _periodToStartDate(String period) {
    final now = DateTime.now();
    switch (period) {
      case 'Last':
        return now.subtract(const Duration(days: 1)).toIso8601String();
      case 'Week':
        return now.subtract(const Duration(days: 7)).toIso8601String();
      case 'Month':
        return DateTime(now.year, now.month - 1, now.day).toIso8601String();
      case 'All time':
      default:
        return null;
    }
  }

  Future<void> _loadDashboardCharts() async {
    await _loadMuscleGroupData();
    await _loadCaloriesData();
    if (mounted) setState(() {});
  }

  Future<void> _loadMuscleGroupData() async {
    final provider = context.read<WorkoutProvider>();
    final startDate = _periodToStartDate(_muscleGroupPeriod);
    final exerciseSets = await provider.getExerciseSetCountsByPeriod(startDate);
    final muscleMap = await ExrxUrlMatcher.buildMuscleGroupMap();

    final Map<String, double> grouped = {};
    for (final row in exerciseSets) {
      final name = (row['name'] as String).toLowerCase();
      final sets = (row['total_sets'] as num).toDouble();
      final group = muscleMap[name] ?? 'Other';
      grouped[group] = (grouped[group] ?? 0) + sets;
    }
    if (mounted) setState(() => _muscleGroupData = grouped);
  }

  Future<void> _loadCaloriesData() async {
    final provider = context.read<WorkoutProvider>();
    final startDate = _periodToStartDate(_caloriesPeriod);
    final data = await provider.getCaloriesPerWorkout(startDate);
    if (mounted) setState(() => _caloriesData = data.reversed.toList());
  }

  void _startWorkoutFromPlan(BuildContext context, WorkoutPlan plan) async {
    final provider = context.read<WorkoutProvider>();
    await provider.startWorkoutFromPlan(plan);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutProvider>();

    // Auto-refresh charts when workout list changes (e.g., after finish/cancel/delete)
    final currentCount = provider.workouts.length;
    if (currentCount != _lastKnownWorkoutCount) {
      _lastKnownWorkoutCount = currentCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWeeklyData();
        _loadDashboardCharts();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _wrapWithScaffold('Home', _buildHomeDashboard(context), actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Color(0xFF6C63FF)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            )
          ]),
          _wrapWithScaffold('Workouts', _buildWorkoutsTabContent(context, provider)),
          const ExerciseLibraryScreen(),
          const StatsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _wrapWithScaffold(String title, Widget content, {List<Widget>? actions}) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: actions,
      ),
      body: content,
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    return Consumer2<WorkoutProvider, SettingsProvider>(
      builder: (context, provider, settings, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 16),
            if (provider.isWorkoutActive) ...[
              _buildActiveWorkoutBanner(context, provider),
              const SizedBox(height: 16),
            ],
            // Calendar at top
            _buildCalendar(provider, settings),
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              ..._buildWorkoutsForDay(provider, settings, _selectedDay!),
            ],
            const SizedBox(height: 32),
            const Text(
              'Next training',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6B8D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildNextTrainingCards(provider, settings),
              
              const SizedBox(height: 32),
              _buildMuscleGroupChartSection(),

              const SizedBox(height: 32),
              _buildChartSection(),

              const SizedBox(height: 32),
              _buildCaloriesChartSection(),
              
            const SizedBox(height: 100), // Scroll fixing space at bottom
          ],
        );
      },
    );
  }

  Widget _buildActiveWorkoutBanner(BuildContext context, WorkoutProvider provider) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fitness_center, color: Color(0xFF6C63FF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Workout in progress', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(provider.activeWorkout!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 14, color: Color(0xFF00D4AA)),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<int>(
                        valueListenable: provider.elapsedSecondsNotifier,
                        builder: (_, elapsed, __) => Text(
                          formatDuration(elapsed),
                          style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF6C63FF), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutsTabContent(BuildContext context, WorkoutProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 32),
        const Text('My Workout', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (provider.workoutPlans.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No routines created yet. Create one to get started!', style: TextStyle(color: Color(0xFF6B6B8D))),
          )
        else
          ...provider.workoutPlans.map((plan) => _buildRoutineCard(context, provider, plan)),

        const SizedBox(height: 32),
        const Text('All Past Workouts', style: TextStyle(color: Color(0xFF6B6B8D), fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (provider.workouts.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No workouts found', style: TextStyle(color: Color(0xFF6B6B8D)))))
        else
          ...provider.workouts.map((workout) => _buildWorkoutHistoryCard(context, workout)),
      ],
    );
  }

  Widget _buildRoutineCard(BuildContext context, WorkoutProvider provider, WorkoutPlan plan) {
     return Card(
       key: ValueKey('plan_${plan.id}'),
       color: const Color(0xFF0F0F12),
       margin: const EdgeInsets.only(bottom: 12),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF222222))),
       child: ListTile(
         contentPadding: const EdgeInsets.all(16),
         title: Text(plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
         subtitle: Text('${plan.exercises.length} exercises', style: const TextStyle(color: Color(0xFF6B6B8D))),
         trailing: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             IconButton(
               icon: const Icon(Icons.edit, color: Color(0xFFA0A0C0)),
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => CreateRoutineScreen(existingPlan: plan)));
               },
             ),
             IconButton(
               icon: const Icon(Icons.play_arrow, color: Color(0xFF00D4AA)),
               onPressed: () => _startWorkoutFromPlan(context, plan),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildWorkoutHistoryCard(BuildContext context, Workout workout) {
     return GestureDetector(
       key: ValueKey('workout_${workout.id}'),
       onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: workout.id!)),
          );
       },
       child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                    color: const Color(0xFF00D4AA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                 ),
                 child: const Icon(Icons.check_circle_outline, color: Color(0xFF00D4AA)),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(workout.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(formatDate(workout.startTime), style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 13)),
                   ],
                 ),
               ),
               const Icon(Icons.chevron_right, color: Color(0xFF6B6B8D)),
            ],
          ),
       ),
     );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Weekly Overview',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                _buildChartTab('Volume'),
                _buildChartTab('Reps'),
                _buildChartTab('Sets'),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildWeeklyChart(),
      ],
    );
  }

  Widget _buildChartTab(String type) {
    final isSelected = _selectedChartType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF333333),
          ),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF8888AA),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklyVolumes.isEmpty) return const SizedBox.shrink();
    
    List<double> activeData;
    String prefix = '';
    
    switch (_selectedChartType) {
      case 'Reps':
        activeData = _weeklyReps;
        break;
      case 'Sets':
        activeData = _weeklySets;
        break;
      case 'Volume':
      default:
        activeData = _weeklyVolumes;
        prefix = 'kg';
        break;
    }

    double maxVal = 10; // prev default
    for (var v in activeData) {
      if (v > maxVal) maxVal = v;
    }

    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Container(
      height: 180, // Increased height to prevent overflow
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF15151A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262630), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final val = activeData[index];
          final heightFactor = val / maxVal;
          final isToday = index == 6; // Last item is today
          
          final targetDayIndex = ((DateTime.now().weekday - 1 - (6 - index)) % 7 + 7) % 7;
          final label = days[targetDayIndex];
          
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (val > 0) 
                  Container(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${val.toStringAsFixed(0)}${prefix.isNotEmpty ? ' $prefix' : ''}',
                      style: TextStyle(
                        color: isToday ? const Color(0xFF6C63FF) : const Color(0xFF00D4AA), 
                        fontSize: 9, 
                        fontWeight: FontWeight.bold
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                  )
                else
                  const SizedBox(height: 18),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: 24,
                      height: heightFactor > 0 ? (heightFactor * 90).clamp(2.0, 90.0) : 2.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday 
                            ? [const Color(0xFF8338EC), const Color(0xFF6C63FF)]
                            : [const Color(0xFF00D4AA), const Color(0xFF00A383)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isToday ? Colors.white : const Color(0xFF6B6B8D),
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  MUSCLE GROUP DISTRIBUTION - Donut Chart
  // ═══════════════════════════════════════════════════════════

  static const Map<String, Color> _muscleColors = {
    'Chest': Color(0xFF7ED321),
    'Back': Color(0xFF4ECDC4),
    'Shoulders': Color(0xFFFFBE0B),
    'Arms': Color(0xFFFF006E),
    'Forearms': Color(0xFFFF8500),
    'Core': Color(0xFF8338EC),
    'Legs': Color(0xFF00D4AA),
    'Glutes & Hips': Color(0xFFFB5607),
    'Calves': Color(0xFF3A86FF),
    'Neck': Color(0xFFADB5BD),
    'Cardio': Color(0xFF6B6B8D),
    'Plyometrics': Color(0xFFE63946),
    'Full Body': Color(0xFFFFB703),
    'Stretches': Color(0xFF90BE6D),
    'Other': Color(0xFF555555),
  };

  Widget _buildMuscleGroupChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Muscle groups',
              style: TextStyle(fontSize: 16, color: Color(0xFF00D4AA), fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: const Text('More', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPeriodSelector(_muscleGroupPeriod, (p) {
          setState(() => _muscleGroupPeriod = p);
          _loadMuscleGroupData();
        }),
        const SizedBox(height: 16),
        _muscleGroupData.isEmpty
            ? _buildEmptyChartPlaceholder('No workout data yet')
            : _buildDonutChart(_muscleGroupData, _muscleColors),
      ],
    );
  }

  Widget _buildPeriodSelector(String selected, ValueChanged<String> onSelect) {
    const periods = ['Last', 'Week', 'Month', 'All time'];
    return Row(
      children: periods.map((p) {
        final isSelected = selected == p;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : const Color(0xFF111111),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF333333),
                ),
              ),
              child: Text(
                p,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF8888AA),
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDonutChart(Map<String, double> data, Map<String, Color> colorMap) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return _buildEmptyChartPlaceholder('No data');

    // Sort by value descending, take top groups
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    // Build segments with percentages
    final segments = <_ChartSegment>[];
    for (final e in sorted) {
      final pct = (e.value / total * 100);
      if (pct < 1) continue; // Skip tiny segments
      segments.add(_ChartSegment(
        label: e.key,
        value: e.value,
        percentage: pct,
        color: colorMap[e.key] ?? Color((e.key.hashCode & 0x00FFFFFF) | 0xFF444444),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF15151A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262630), width: 1.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _DonutPainter(segments: segments),
                ),
                // Center text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      total.toStringAsFixed(0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'sets',
                      style: TextStyle(color: Color(0xFF6B6B8D), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: segments.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${s.label} ${s.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Color(0xFFA0A0C0), fontSize: 12),
                ),
              ],
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CALORIES BURNED - Dot/Line Chart
  // ═══════════════════════════════════════════════════════════

  Widget _buildCaloriesChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Calories burned, kcal',
              style: TextStyle(fontSize: 16, color: Color(0xFF00D4AA), fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: const Text('More', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPeriodSelector(_caloriesPeriod, (p) {
          setState(() => _caloriesPeriod = p);
          _loadCaloriesData();
        }),
        const SizedBox(height: 16),
        _caloriesData.isEmpty
            ? _buildEmptyChartPlaceholder('No calorie data yet')
            : _buildCaloriesChart(),
      ],
    );
  }

  Widget _buildCaloriesChart() {
    final maxCal = _caloriesData
        .map((d) => (d['calories'] as num).toDouble())
        .fold(10.0, (a, b) => b > a ? b : a);
    final yMax = ((maxCal / 20).ceil() * 20).toDouble().clamp(20.0, double.infinity);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF15151A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262630), width: 1.5),
      ),
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          size: Size.infinite,
          painter: _CaloriesChartPainter(
            data: _caloriesData,
            yMax: yMax,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChartPlaceholder(String message) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF15151A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262630), width: 1.5),
      ),
      child: Center(
        child: Text(message, style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 14)),
      ),
    );
  }

  List<Widget> _buildNextTrainingCards(WorkoutProvider provider, SettingsProvider settings) {
    final plans = provider.workoutPlans;
    
    if (plans.isEmpty) {
       return [
         Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: const Color(0xFF15151A), borderRadius: BorderRadius.circular(16)),
           child: const Center(child: Text("No routines created. Tap 'Workouts' tab to create.", style: TextStyle(color: Color(0xFF6B6B8D)))),
         )
       ];
    }
    
    return plans.map((plan) {
      final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return GestureDetector(
        onTap: () => _startWorkoutFromPlan(context, plan),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.autoPositioning ? 'Auto Scheduled' : 'Every ${days[plan.dayNumber - 1]}',
                      style: const TextStyle(
                        color: Color(0xFF6B6B8D),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.name.toLowerCase().replaceAll(' ', '+'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Right dot indicator
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D4AA),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<WorkoutPlan> _getPlansForDay(DateTime date, WorkoutProvider provider, SettingsProvider settings) {
    if (provider.workoutPlans.isEmpty) return [];

    if (settings.autoPositioning) {
      if (!settings.workoutDays.contains(date.weekday)) return [];
      final sortedDays = List<int>.from(settings.workoutDays)..sort();
      final dayIndex = sortedDays.indexOf(date.weekday);
      final planIndex = dayIndex % provider.workoutPlans.length;
      return [provider.workoutPlans[planIndex]];
    } else {
      return provider.workoutPlans.where((p) => p.dayNumber == date.weekday).toList();
    }
  }

  Widget _buildCalendar(WorkoutProvider provider, SettingsProvider settings) {
    return TableCalendar(
      // Only respond to taps, let vertical swipes pass to parent scroll view
      availableGestures: AvailableGestures.none,
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      holidayPredicate: (day) => provider.isOffDay(day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronIcon: const Icon(Icons.arrow_back, color: Color(0xFF00D4AA), size: 20),
        rightChevronIcon: const Icon(Icons.arrow_forward, color: Color(0xFF00D4AA), size: 20),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Color(0xFF6B6B8D), fontWeight: FontWeight.w600),
        weekendStyle: TextStyle(color: Color(0xFF6B6B8D), fontWeight: FontWeight.w600),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        weekendTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
        outsideTextStyle: const TextStyle(color: Color(0xFF333333)),
        todayDecoration: const BoxDecoration(
          color: Color(0xFF222222),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF00D4AA)),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          final isOff = provider.isOffDay(date);
          final plans = _getPlansForDay(date, provider, settings);
          final hasPlan = !isOff && plans.isNotEmpty;
          
          return Container(
            margin: const EdgeInsets.all(4),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                color: hasPlan ? const Color(0xFF00D4AA) : Colors.white,
                fontWeight: hasPlan ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          );
        },
        holidayBuilder: (context, day, focusedDay) {
          return Center(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6C63FF), width: 1.5),
              ),
              margin: const EdgeInsets.all(6.0),
              width: 35,
              height: 35,
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
        markerBuilder: (context, date, events) {
          final workouts = settings.displayAllData ? provider.getWorkoutsForDay(date) : [];
          final plans = _getPlansForDay(date, provider, settings);
          final isOff = provider.isOffDay(date);

          List<Widget> markers = [];
          if (workouts.isNotEmpty) {
            final w = workouts.first;
            if (w.completionPercentage >= 100.0) {
              markers.add(const Icon(Icons.check_circle, size: 14, color: Color(0xFF00D4AA)));
            } else {
              markers.add(Text('${w.completionPercentage.toInt()}%', style: const TextStyle(color: Color(0xFF00D4AA), fontSize: 10, fontWeight: FontWeight.bold)));
            }
          } else if (!isOff && plans.isNotEmpty && date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
            markers.add(const Icon(Icons.fitness_center, size: 12, color: Color(0xFF6B6B8D)));
          }
          
          if (markers.isNotEmpty) {
             return Positioned(
               bottom: 4,
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: markers,
               ),
             );
          }
          return null;
        },
      ),
    );
  }

  List<Widget> _buildWorkoutsForDay(WorkoutProvider provider, SettingsProvider settings, DateTime day) {
    final workouts = settings.displayAllData ? provider.getWorkoutsForDay(day) : [];
    final isOffDay = provider.isOffDay(day);
    List<Widget> children = [];

    final plannedRoutines = _getPlansForDay(day, provider, settings);

    if (workouts.isEmpty && isSameDay(day, DateTime.now())) {
      children.add(
         ElevatedButton.icon(
            onPressed: () {
                const name = 'Workout';
                provider.startWorkout(name);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
                );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Free Workout Now'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF6C63FF),
            ),
         )
      );
    }
    
    if (!isOffDay && plannedRoutines.isNotEmpty) {
       children.add(const SizedBox(height: 16));
       children.add(const Text('Scheduled Routines', style: TextStyle(color: Color(0xFFA0A0C0), fontSize: 13, fontWeight: FontWeight.bold)));
       children.add(const SizedBox(height: 8));
       children.addAll(plannedRoutines.map((plan) => Card(
          color: const Color(0xFF15151A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF6C63FF), width: 1)),
          child: ListTile(
             leading: const Icon(Icons.assignment, color: Color(0xFF6C63FF)),
             title: Text(plan.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
             subtitle: Text('${plan.exercises.length} exercises', style: const TextStyle(color: Color(0xFF6B6B8D))),
             trailing: IconButton(
                icon: const Icon(Icons.play_arrow, color: Color(0xFF00D4AA)),
                onPressed: () => _startWorkoutFromPlan(context, plan),
             ),
          ),
       )));
    }
    
    if (workouts.isNotEmpty) {
       children.add(const SizedBox(height: 16));
       children.add(const Text('Completed Workouts', style: TextStyle(color: Color(0xFFA0A0C0), fontSize: 13, fontWeight: FontWeight.bold)));
       children.add(const SizedBox(height: 8));
      children.addAll(workouts.map((workout) {
        return Card(
          color: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF222222)),
          ),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Color(0xFF00D4AA)),
            title: Text(workout.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${formatDate(workout.startTime)} • ${formatDuration(workout.totalDuration)}',
              style: const TextStyle(color: Color(0xFFA0A0C0), fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B6B8D)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: workout.id!)),
            ),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A2E),
                  title: const Text('Delete', style: TextStyle(color: Colors.white)),
                  content: Text('Delete "${workout.name}" workout?',
                      style: const TextStyle(color: Color(0xFFA0A0C0))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        provider.deleteWorkout(workout.id!);
                        setState(() {
                           _loadWeeklyData(); // refresh chart
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Delete', style: TextStyle(color: Color(0xFFFF6B6B))),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }).toList());
    } else if (isOffDay) {
       children.add(
         const Center(
           child: Padding(
             padding: EdgeInsets.all(16.0),
             child: Text('Rest Day 😌', style: TextStyle(color: Color(0xFF00D4AA), fontSize: 16, fontWeight: FontWeight.bold)),
           ),
         )
       );
    }

    return children;
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF222222), width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.black,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF00D4AA),
        unselectedItemColor: const Color(0xFF6B6B8D),
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_filled),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.fitness_center),
            ),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.menu_book_rounded),
            ),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.bar_chart),
            ),
            label: 'Stats',
          ),
        ],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Refresh charts when returning to Home tab
          if (index == 0) {
            _loadWeeklyData();
            _loadDashboardCharts();
          }
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Chart data classes & painters
// ═══════════════════════════════════════════════════════════

class _ChartSegment {
  final String label;
  final double value;
  final double percentage;
  final Color color;

  const _ChartSegment({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });
}

class _DonutPainter extends CustomPainter {
  final List<_ChartSegment> segments;
  static const double strokeWidth = 32;
  static const double gap = 2; // degrees gap between segments

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final totalGap = gap * segments.length;
    final availableDegrees = 360.0 - totalGap;
    final total = segments.fold(0.0, (a, s) => a + s.value);
    if (total == 0) return;

    double startAngle = -90.0; // Start from top

    for (int i = 0; i < segments.length; i++) {
      final s = segments[i];
      final sweepAngle = (s.value / total) * availableDegrees;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = s.color;

      canvas.drawArc(
        rect,
        startAngle * math.pi / 180,
        sweepAngle * math.pi / 180,
        false,
        paint,
      );

      // Draw percentage label
      if (s.percentage >= 5) {
        final midAngle = (startAngle + sweepAngle / 2) * math.pi / 180;
        final labelRadius = radius + strokeWidth / 2 + 18;
        final labelX = center.dx + labelRadius * math.cos(midAngle);
        final labelY = center.dy + labelRadius * math.sin(midAngle);

        // Background pill
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${s.percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final bgRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(labelX, labelY),
            width: textPainter.width + 10,
            height: textPainter.height + 6,
          ),
          const Radius.circular(6),
        );

        canvas.drawRRect(
          bgRect,
          Paint()..color = s.color.withValues(alpha: 0.85),
        );

        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    if (oldDelegate.segments.length != segments.length) return true;
    for (int i = 0; i < segments.length; i++) {
      if (oldDelegate.segments[i].value != segments[i].value ||
          oldDelegate.segments[i].color != segments[i].color) {
        return true;
      }
    }
    return false;
  }
}

class _CaloriesChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double yMax;

  _CaloriesChartPainter({required this.data, required this.yMax});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final leftPad = 36.0;
    final bottomPad = 24.0;
    final chartWidth = size.width - leftPad - 16;
    final chartHeight = size.height - bottomPad - 10;

    // Draw Y axis gridlines
    final gridPaint = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.5;

    final ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final y = 10 + chartHeight - (chartHeight * i / ySteps);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - 16, y), gridPaint);

      final label = (yMax * i / ySteps).toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // X positions
    final itemWidth = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFFFF6B4A)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFFFF6B4A).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final cal = (data[i]['calories'] as num).toDouble();
      final x = leftPad + (data.length > 1 ? i * itemWidth : chartWidth / 2);
      final y = 10 + chartHeight - (cal / yMax * chartHeight).clamp(0, chartHeight);
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    // Draw dots and labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final cal = (data[i]['calories'] as num).toDouble();

      // Dashed vertical line
      for (double dy = pt.dy; dy < 10 + chartHeight; dy += 4) {
        canvas.drawLine(
          Offset(pt.dx, dy),
          Offset(pt.dx, (dy + 2).clamp(0, 10 + chartHeight)),
          dashPaint,
        );
      }

      // Dot
      canvas.drawCircle(pt, 5, Paint()..color = const Color(0xFFFF6B4A));
      canvas.drawCircle(pt, 3, Paint()..color = Colors.white);

      // Value label bubble
      if (cal > 0) {
        final text = cal.toStringAsFixed(0);
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final bgRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pt.dx, pt.dy - 16),
            width: tp.width + 12,
            height: tp.height + 8,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(bgRect, Paint()..color = const Color(0xFFFF6B4A));
        tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - 16 - tp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CaloriesChartPainter oldDelegate) {
    if (oldDelegate.yMax != yMax) return true;
    if (oldDelegate.data.length != data.length) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i]['calories'] != data[i]['calories']) return true;
    }
    return false;
  }
}
