import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_models.dart';
import '../providers/workout_provider.dart';
import '../utils/formatters.dart';
import '../utils/exrx_url_matcher.dart';
import '../l10n/translations.dart';
import '../db/database_helper.dart';
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
  String _selectedChartType = 'volume'; // volume, reps, sets
  int _selectedIndex = 0;

  // Dashboard chart data
  String _muscleGroupPeriod = 'all_time';
  String _caloriesPeriod = 'all_time';
  Map<String, double> _muscleGroupData = {};
  List<Map<String, dynamic>> _caloriesData = [];

  // Body progress chart data
  String _selectedBodyStat = 'weight';
  List<Map<String, dynamic>> _bodyProgressData = [];

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
      case 'last':
        return now.subtract(const Duration(days: 1)).toIso8601String();
      case 'week':
        return now.subtract(const Duration(days: 7)).toIso8601String();
      case 'month':
        return DateTime(now.year, now.month - 1, now.day).toIso8601String();
      case 'all_time':
      default:
        return null;
    }
  }

  Future<void> _loadDashboardCharts() async {
    await _loadMuscleGroupData();
    await _loadCaloriesData();
    await _loadBodyProgressData();
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

  Future<void> _loadBodyProgressData() async {
    final data = await DatabaseHelper().getBodyMeasurementHistory(_selectedBodyStat, limit: 20);
    if (mounted) setState(() => _bodyProgressData = data);
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _wrapWithScaffold(Translations.of(context).get('home'), _buildHomeDashboard(context), actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            )
          ]),
          _wrapWithScaffold(Translations.of(context).get('workouts'), _buildWorkoutsTabContent(context, provider), actions: [
            IconButton(
              icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            )
          ]),
          const ExerciseLibraryScreen(),
          const StatsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _wrapWithScaffold(String title, Widget content, {List<Widget>? actions}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
            Text(
              Translations.of(context).get('next_training'),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildNextTrainingCards(provider, settings),
              
              const SizedBox(height: 32),
              _buildMuscleGroupChartSection(),

              const SizedBox(height: 32),
              _buildBodyProgressSection(),

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
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Translations.of(context).get('workout_in_progress'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(provider.activeWorkout!.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer, size: 14, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 4),
                      ValueListenableBuilder<int>(
                        valueListenable: provider.elapsedSecondsNotifier,
                        builder: (_, elapsed, _) => Text(
                          formatDuration(elapsed),
                          style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.primary, size: 16),
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
          label: Text(Translations.of(context).get('add_workout'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 32),
        Text(Translations.of(context).get('my_workout'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (provider.workoutPlans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(Translations.of(context).get('no_routines_created'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          )
        else
          ..._getSortedPlans(provider).map((plan) => _buildRoutineCard(context, provider, plan)),

        const SizedBox(height: 32),
        Text(Translations.of(context).get('all_past_workouts'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (provider.workouts.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(Translations.of(context).get('no_workouts_found'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))))
        else
          ...provider.workouts.map((workout) => _buildWorkoutHistoryCard(context, workout)),
      ],
    );
  }

  /// Sort workout plans by day number, starting from the configured first day of the week.
  List<WorkoutPlan> _getSortedPlans(WorkoutProvider provider) {
    final settings = context.read<SettingsProvider>();
    final firstDay = settings.firstDayOfWeek;
    final plans = List<WorkoutPlan>.from(provider.workoutPlans);
    plans.sort((a, b) {
      // Adjust day numbers relative to first day of week
      final dayA = ((a.dayNumber - firstDay) % 7 + 7) % 7;
      final dayB = ((b.dayNumber - firstDay) % 7 + 7) % 7;
      return dayA.compareTo(dayB);
    });
    return plans;
  }

  Widget _buildRoutineCard(BuildContext context, WorkoutProvider provider, WorkoutPlan plan) {
     final settings = context.read<SettingsProvider>();
     final dayName = settings.getDayName(plan.dayNumber);
     return Card(
       key: ValueKey('plan_${plan.id}'),
       color: Theme.of(context).colorScheme.surfaceContainerHigh,
       margin: const EdgeInsets.only(bottom: 12),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outline)),
       child: ListTile(
         contentPadding: const EdgeInsets.all(16),
         leading: Container(
           width: 44,
           height: 44,
           decoration: BoxDecoration(
             color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
             borderRadius: BorderRadius.circular(10),
           ),
           child: Center(
             child: Text(
               dayName,
               style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
             ),
           ),
         ),
         title: Text(plan.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
         subtitle: Text('${plan.exercises.length} ${Translations.of(context).get('exercises_label')} • ${Translations.of(context).get('day')} ${plan.dayNumber}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
         trailing: Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             IconButton(
               icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurfaceVariant),
               onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => CreateRoutineScreen(existingPlan: plan)));
               },
             ),
             IconButton(
               icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.secondary),
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
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Row(
            children: [
               Container(
                 padding: const EdgeInsets.all(10),
                 decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                 ),
                 child: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.secondary),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(workout.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(formatDateWithTime(workout.startTime), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                   ],
                 ),
               ),
               Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
            Text(
              Translations.of(context).get('weekly_overview'),
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                _buildChartTab('volume', Translations.of(context).get('volume')),
                _buildChartTab('reps', Translations.of(context).get('reps')),
                _buildChartTab('sets', Translations.of(context).get('sets')),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildWeeklyChart(),
      ],
    );
  }

  Widget _buildChartTab(String key, String label) {
    final isSelected = _selectedChartType == key;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedChartType = key;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
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
      case 'reps':
        activeData = _weeklyReps;
        break;
      case 'sets':
        activeData = _weeklySets;
        break;
      case 'volume':
      default:
        final settings = context.read<SettingsProvider>();
        // Volumes are stored as kg × reps; convert to display unit
        if (settings.measurementSystem == 'imperial') {
          activeData = _weeklyVolumes.map((v) => settings.displayWeight(v)).toList();
        } else {
          activeData = _weeklyVolumes;
        }
        prefix = settings.unit;
        break;
    }

    double maxVal = 10; // prev default
    for (var v in activeData) {
      if (v > maxVal) maxVal = v;
    }

    final t = Translations.of(context);
    final days = [t.get('mon'), t.get('tue'), t.get('wed'), t.get('thu'), t.get('fri'), t.get('sat'), t.get('sun')];
    
    return Container(
      height: 180, // Increased height to prevent overflow
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
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
                        color: isToday ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, 
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
                            ? [const Color(0xFF8338EC), Theme.of(context).colorScheme.primary]
                            : [Theme.of(context).colorScheme.secondary, const Color(0xFF00A383)],
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
                    color: isToday ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
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
            Text(
              Translations.of(context).get('muscle_groups'),
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: Text(Translations.of(context).get('more'), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
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
            ? _buildEmptyChartPlaceholder(Translations.of(context).get('no_workout_data_yet'))
            : _buildDonutChart(_muscleGroupData, _muscleColors),
      ],
    );
  }

  Widget _buildPeriodSelector(String selected, ValueChanged<String> onSelect) {
    final t = Translations.of(context);
    final periodKeys = ['last', 'week', 'month', 'all_time'];
    return Row(
      children: periodKeys.map((key) {
        final isSelected = selected == key;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                t.get(key),
                style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
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

  // ═══════════════════════════════════════════════════════════
  //  BODY PROGRESS - Line Chart with measurement selector
  // ═══════════════════════════════════════════════════════════

  static const Map<String, String> _bodyStatKeys = {
    'weight': 'weight',
    'arm_circumference': 'arm_circumference',
    'waist_circumference': 'waist_circumference',
    'shoulder_width': 'shoulder_width',
    'chest_circumference': 'chest_circumference',
    'hip_circumference': 'hip_circumference',
    'thigh_circumference': 'thigh_circumference',
    'calf_circumference': 'calf_circumference',
    'neck_circumference': 'neck_circumference',
    'forearm_circumference': 'forearm_circumference',
  };

  Widget _buildBodyProgressSection() {
    final settings = context.read<SettingsProvider>();
    final t = Translations(settings.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.get('body_progress'),
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => _showBodyStatPicker(context, settings),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.get(_selectedBodyStat),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_bodyProgressData.isEmpty || _bodyProgressData.length < 2)
          _buildEmptyChartPlaceholder(t.get('no_measurements_yet'))
        else
          _buildBodyProgressChart(settings),
        const SizedBox(height: 10),
        // Quick update button
        Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(t.get('update_measurements'), style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBodyStatPicker(BuildContext context, SettingsProvider settings) {
    final t = Translations(settings.language);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
              ),
              Text(t.get('select_measurement'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    ..._bodyStatKeys.entries.map((entry) {
                      final isSelected = _selectedBodyStat == entry.key;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(t.get(entry.key), style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          trailing: isSelected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary, size: 20) : null,
                          onTap: () {
                            setState(() => _selectedBodyStat = entry.key);
                            _loadBodyProgressData();
                            Navigator.pop(ctx);
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyProgressChart(SettingsProvider settings) {
    final isWeight = _selectedBodyStat == 'weight';

    // Convert values for display
    final displayData = _bodyProgressData.map((d) {
      final rawValue = (d['value'] as num?)?.toDouble() ?? 0;
      final displayValue = isWeight
          ? settings.displayWeight(rawValue)
          : settings.displayLength(rawValue);
      return {'date': d['date'], 'value': displayValue};
    }).toList();

    double maxVal = 10;
    double minVal = double.infinity;
    for (final d in displayData) {
      final v = (d['value'] as num).toDouble();
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }
    if (minVal == double.infinity) minVal = 0;
    final range = maxVal - minVal;
    final yMin = (minVal - range * 0.1).clamp(0.0, double.infinity);
    final yMax = maxVal + range * 0.1;

    final unitLabel = isWeight ? settings.unit : settings.lengthUnit;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(8, 20, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _BodyProgressPainter(
          data: displayData,
          yMin: yMin,
          yMax: yMax,
          unitLabel: unitLabel,
          gridColor: Theme.of(context).colorScheme.outlineVariant,
          labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDonutChart(Map<String, double> data, Map<String, Color> colorMap) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    if (total == 0) return _buildEmptyChartPlaceholder(Translations.of(context).get('no_data'));

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
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Translations.of(context).get('sets_label'),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
            Text(
              Translations.of(context).get('calories_burned'),
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600),
            ),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 3),
              child: Text(Translations.of(context).get('more'), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w600)),
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
            ? _buildEmptyChartPlaceholder(Translations.of(context).get('no_calorie_data_yet'))
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
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
      ),
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          size: Size.infinite,
          painter: _CaloriesChartPainter(
            data: _caloriesData,
            yMax: yMax,
            gridColor: Theme.of(context).colorScheme.outlineVariant,
            labelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChartPlaceholder(String message) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline, width: 1.5),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
      ),
    );
  }

  List<Widget> _buildNextTrainingCards(WorkoutProvider provider, SettingsProvider settings) {
    final plans = _getSortedPlans(provider);
    
    if (plans.isEmpty) {
       return [
         Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
           child: Center(child: Text(Translations.of(context).get('no_routines'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
         )
       ];
    }
    
    return plans.map((plan) {
      final t = Translations.of(context);
      final days = [t.get('monday'), t.get('tuesday'), t.get('wednesday'), t.get('thursday'), t.get('friday'), t.get('saturday'), t.get('sunday')];
      return GestureDetector(
        onTap: () => _startWorkoutFromPlan(context, plan),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
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
                      settings.autoPositioning ? t.get('auto_scheduled') : '${t.get('every')} ${days[plan.dayNumber - 1]}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.name.toLowerCase().replaceAll(' ', '+'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
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
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
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
        leftChevronIcon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.secondary, size: 20),
        rightChevronIcon: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.secondary, size: 20),
        titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
        weekendStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
      calendarStyle: CalendarStyle(
        defaultTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
        outsideTextStyle: TextStyle(color: Theme.of(context).colorScheme.outlineVariant),
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.secondary),
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
                color: hasPlan ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
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
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 1.5),
              ),
              margin: const EdgeInsets.all(6.0),
              width: 35,
              height: 35,
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
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
              markers.add(Icon(Icons.check_circle, size: 14, color: Theme.of(context).colorScheme.secondary));
            } else {
              markers.add(Text('${w.completionPercentage.toInt()}%', style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.bold)));
            }
          } else if (!isOff && plans.isNotEmpty && date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
            markers.add(Icon(Icons.fitness_center, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant));
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
            label: Text(Translations.of(context).get('start_free_workout')),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
         )
      );
    }
    
    if (!isOffDay && plannedRoutines.isNotEmpty) {
       children.add(const SizedBox(height: 16));
       children.add(Text(Translations.of(context).get('scheduled_routines'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)));
       children.add(const SizedBox(height: 8));
       children.addAll(plannedRoutines.map((plan) => Card(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1)),
          child: ListTile(
             leading: Icon(Icons.assignment, color: Theme.of(context).colorScheme.primary),
             title: Text(plan.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
             subtitle: Text('${plan.exercises.length} ${Translations.of(context).get('exercises_label')}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
             trailing: IconButton(
                icon: Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.secondary),
                onPressed: () => _startWorkoutFromPlan(context, plan),
             ),
          ),
       )));
    }
    
    if (workouts.isNotEmpty) {
       children.add(const SizedBox(height: 16));
       children.add(Text(Translations.of(context).get('completed_workouts'), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.bold)));
       children.add(const SizedBox(height: 8));
      children.addAll(workouts.map((workout) {
        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: ListTile(
            leading: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.secondary),
            title: Text(workout.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${formatDate(workout.startTime)} • ${formatDuration(workout.totalDuration)}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
            ),
            trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workoutId: workout.id!)),
            ),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: Text(Translations.of(context).get('delete'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                  content: Text(Translations.of(context).get('delete_workout_confirm'),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(Translations.of(context).get('cancel')),
                    ),
                    TextButton(
                      onPressed: () {
                        provider.deleteWorkout(workout.id!);
                        setState(() {
                           _loadWeeklyData(); // refresh chart
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(Translations.of(context).get('delete'), style: const TextStyle(color: Color(0xFFFF6B6B))),
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
         Center(
           child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Text(Translations.of(context).get('rest_day'), style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 16, fontWeight: FontWeight.bold)),
           ),
         )
       );
    }

    return children;
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5)),
      ),
      child: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        items: [
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_filled),
            ),
            label: Translations.of(context).get('home'),
          ),
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.fitness_center),
            ),
            label: Translations.of(context).get('workouts'),
          ),
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.menu_book_rounded),
            ),
            label: Translations.of(context).get('library'),
          ),
          BottomNavigationBarItem(
            icon: const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.bar_chart),
            ),
            label: Translations.of(context).get('stats'),
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
  final Color gridColor;
  final Color labelColor;

  _CaloriesChartPainter({required this.data, required this.yMax, required this.gridColor, required this.labelColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final leftPad = 36.0;
    final bottomPad = 24.0;
    final chartWidth = size.width - leftPad - 16;
    final chartHeight = size.height - bottomPad - 10;

    // Draw Y axis gridlines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final ySteps = 4;
    for (int i = 0; i <= ySteps; i++) {
      final y = 10 + chartHeight - (chartHeight * i / ySteps);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - 16, y), gridPaint);

      final label = (yMax * i / ySteps).toStringAsFixed(0);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(color: labelColor, fontSize: 10),
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

// ═══════════════════════════════════════════════════════════
//  Body Progress Line Chart Painter
// ═══════════════════════════════════════════════════════════

class _BodyProgressPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double yMin;
  final double yMax;
  final String unitLabel;
  final Color gridColor;
  final Color labelColor;

  _BodyProgressPainter({
    required this.data,
    required this.yMin,
    required this.yMax,
    required this.unitLabel,
    required this.gridColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final leftPad = 44.0;
    final bottomPad = 28.0;
    final topPad = 14.0;
    final rightPad = 16.0;
    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - bottomPad - topPad;
    final yRange = (yMax - yMin).clamp(0.01, double.infinity);

    // Y-axis gridlines
    const ySteps = 4;
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    for (int i = 0; i <= ySteps; i++) {
      final y = topPad + chartHeight - (chartHeight * i / ySteps);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final val = yMin + yRange * i / ySteps;
      final tp = TextPainter(
        text: TextSpan(
          text: val.toStringAsFixed(1),
          style: TextStyle(color: labelColor, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // Unit label at top-left
    final unitTp = TextPainter(
      text: TextSpan(
        text: unitLabel,
        style: TextStyle(color: labelColor, fontSize: 9, fontStyle: FontStyle.italic),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    unitTp.paint(canvas, Offset(leftPad - unitTp.width - 6, topPad - unitTp.height - 2));

    // Compute points
    final itemWidth = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final v = (data[i]['value'] as num).toDouble();
      final x = leftPad + (data.length > 1 ? i * itemWidth : chartWidth / 2);
      final y = topPad + chartHeight - ((v - yMin) / yRange * chartHeight).clamp(0, chartHeight);
      points.add(Offset(x, y));
    }

    // Gradient fill under the line
    if (points.length >= 2) {
      final fillPath = Path()..moveTo(points.first.dx, topPad + chartHeight);
      for (final pt in points) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(points.last.dx, topPad + chartHeight);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF8338EC).withValues(alpha: 0.25),
          const Color(0xFF8338EC).withValues(alpha: 0.0),
        ],
      );
      final rect = Rect.fromLTWH(leftPad, topPad, chartWidth, chartHeight);
      final fillPaint = Paint()..shader = gradient.createShader(rect);
      canvas.drawPath(fillPath, fillPaint);
    }

    // Line
    if (points.length >= 2) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        // Smooth curve with cubic bezier
        final prev = points[i - 1];
        final curr = points[i];
        final cpx = (prev.dx + curr.dx) / 2;
        linePath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = const Color(0xFF8338EC)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }

    // Dots + value labels
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final v = (data[i]['value'] as num).toDouble();

      // Outer glow
      canvas.drawCircle(pt, 6, Paint()..color = const Color(0xFF8338EC).withValues(alpha: 0.25));
      // Dot
      canvas.drawCircle(pt, 4, Paint()..color = const Color(0xFF8338EC));
      canvas.drawCircle(pt, 2.5, Paint()..color = Colors.white);

      // Value bubble above dot
      final valText = v.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(
          text: valText,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy - 16), width: tp.width + 10, height: tp.height + 6),
        const Radius.circular(6),
      );
      canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF8338EC));
      tp.paint(canvas, Offset(pt.dx - tp.width / 2, pt.dy - 16 - tp.height / 2));

      // Date label below x-axis
      final rawDate = data[i]['date'] as String? ?? '';
      String dateStr = '';
      if (rawDate.length >= 10) {
        final dt = DateTime.tryParse(rawDate);
        if (dt != null) {
          dateStr = '${dt.day}/${dt.month}';
        }
      }
      final dateTp = TextPainter(
        text: TextSpan(text: dateStr, style: TextStyle(color: labelColor, fontSize: 8)),
        textDirection: TextDirection.ltr,
      )..layout();
      dateTp.paint(canvas, Offset(pt.dx - dateTp.width / 2, topPad + chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BodyProgressPainter oldDelegate) {
    if (oldDelegate.yMin != yMin || oldDelegate.yMax != yMax) return true;
    if (oldDelegate.data.length != data.length) return true;
    for (int i = 0; i < data.length; i++) {
      if (oldDelegate.data[i]['value'] != data[i]['value']) return true;
    }
    return false;
  }
}
