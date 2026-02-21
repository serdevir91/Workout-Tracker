import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/workout_plan_models.dart';
import '../models/workout_models.dart';
import '../providers/workout_provider.dart';
import '../utils/formatters.dart';
import 'active_workout_screen.dart';
import 'workout_detail_screen.dart';
import 'stats_screen.dart';
import 'exercise_library_screen.dart';

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
  bool _isWorkoutsTabSelected = false;
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadWeeklyData();
  }
  
  void _loadWeeklyData() async {
    final provider = context.read<WorkoutProvider>();
    final volumes = await provider.getWeeklyVolumeStats();
    final reps = await provider.getWeeklyRepsStats();
    final sets = await provider.getWeeklySetsStats();
    if (mounted) {
      setState(() {
        _weeklyVolumes = volumes;
        _weeklyReps = reps;
        _weeklySets = sets;
      });
    }
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _selectedIndex == 1 ? null : AppBar(
        title: const Text('Workouts'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.fitness_center, color: Color(0xFF6C63FF)),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded, color: Color(0xFF00D4AA)),
            tooltip: 'Exercise Library',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeDashboard(context),
          const StatsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
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
            _buildTopTabs(),
            const SizedBox(height: 24),
            if (!_isWorkoutsTabSelected) ...[
              const Text(
                'Next training',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6B8D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ..._buildNextTrainingCards(context),
              
              const SizedBox(height: 32),
              _buildChartSection(),
              
              const SizedBox(height: 32),
              const Text(
                'Workout schedule',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B6B8D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              _buildCalendar(provider),
              if (_selectedDay != null) ...[
                const SizedBox(height: 16),
                ..._buildWorkoutsForDay(provider, _selectedDay!),
              ],
            ] else ...[
              _buildWorkoutsTabContent(context, provider),
            ],
            const SizedBox(height: 100), // Scroll fixing space at bottom
          ],
        );
      },
    );
  }

  Widget _buildTopTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isWorkoutsTabSelected = false),
            child: _buildTabChip('Dashboard', !_isWorkoutsTabSelected),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isWorkoutsTabSelected = true),
            child: _buildTabChip('Workouts', _isWorkoutsTabSelected),
          ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? Colors.transparent : const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF222222),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFFA0A0C0),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
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
                      Text(formatDuration(provider.workoutElapsedSeconds), style: const TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontSize: 12)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () async {
            await provider.startWorkout('Custom Workout');
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
            );
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Start Empty Workout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4AA),
            foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 24),
        const Text('All Past Workouts', style: TextStyle(color: Color(0xFF6B6B8D), fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        if (provider.workouts.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No workouts found', style: TextStyle(color: Color(0xFF6B6B8D)))))
        else
          ...provider.workouts.map((workout) => _buildWorkoutHistoryCard(context, workout)),
      ],
    );
  }

  Widget _buildWorkoutHistoryCard(BuildContext context, Workout workout) {
     return GestureDetector(
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
          
          final targetDayIndex = (DateTime.now().weekday - 1 - (6 - index)) % 7;
          final label = days[targetDayIndex < 0 ? targetDayIndex + 7 : targetDayIndex];
          
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

  List<Widget> _buildNextTrainingCards(BuildContext context) {
    return defaultWorkoutPlans.map((plan) {
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
                      'Day ${plan.dayNumber}',
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

  Widget _buildCalendar(WorkoutProvider provider) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
        markerBuilder: (context, date, events) {
          final workouts = provider.getWorkoutsForDay(date);
          if (workouts.isNotEmpty) {
            return const Positioned(
              bottom: 4,
              child: Icon(
                Icons.fitness_center,
                size: 14,
                color: Color(0xFF00D4AA),
              ),
            );
          }
          return null;
        },
      ),
    );
  }

  List<Widget> _buildWorkoutsForDay(WorkoutProvider provider, DateTime day) {
    final workouts = provider.getWorkoutsForDay(day);
    if (workouts.isEmpty && isSameDay(day, DateTime.now())) {
      return [
         const SizedBox(height: 16),
         ElevatedButton.icon(
            onPressed: () {
                final name = 'Workout';
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
      ];
    }
    
    return workouts.map((workout) {
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
    }).toList();
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
              child: Icon(Icons.fitness_center),
            ),
            label: 'Workouts',
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
        },
      ),
    );
  }
}
