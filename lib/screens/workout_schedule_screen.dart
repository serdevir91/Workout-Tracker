import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/settings_provider.dart';

class WorkoutScheduleScreen extends StatefulWidget {
  const WorkoutScheduleScreen({super.key});

  @override
  State<WorkoutScheduleScreen> createState() => _WorkoutScheduleScreenState();
}

class _WorkoutScheduleScreenState extends State<WorkoutScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  late bool _showOnDashboard;
  late bool _displayAllData;
  late bool _autoPositioning;
  late List<int> _workoutDays;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _showOnDashboard = settings.showOnDashboard;
    _displayAllData = settings.displayAllData;
    _autoPositioning = settings.autoPositioning;
    _workoutDays = List.from(settings.workoutDays);
  }

  void _saveSettings() {
    context.read<SettingsProvider>().updateScheduleSettings(
      showOnDashboard: _showOnDashboard,
      displayAllData: _displayAllData,
      autoPositioning: _autoPositioning,
      workoutDays: _workoutDays,
    );
  }

  void _toggleDay(int day) {
    setState(() {
      if (_workoutDays.contains(day)) {
        if (_workoutDays.length > 1) { // prevent removing all days
          _workoutDays.remove(day);
        }
      } else {
        _workoutDays.add(day);
      }
      _workoutDays.sort();
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout schedule', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18)),
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Preview
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
                leftChevronIcon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.secondary),
                rightChevronIcon: Icon(Icons.arrow_forward, color: Theme.of(context).colorScheme.secondary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                weekendStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                weekendTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                todayDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, date, _) {
                  final isWorkoutDay = _workoutDays.contains(date.weekday);
                  return Container(
                    margin: const EdgeInsets.all(4),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isWorkoutDay ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isWorkoutDay ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isWorkoutDay)
                          Icon(Icons.fitness_center, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  );
                },
              ),
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Settings Toggles
            _buildToggle(
              'Show on Dashboard',
              _showOnDashboard,
              (val) {
                setState(() => _showOnDashboard = val);
                _saveSettings();
              },
            ),
            
            _buildToggleWithSubtitle(
              'Display all of the data from all workout programs',
              'This widget shows all workouts',
              _displayAllData,
              (val) {
                setState(() => _displayAllData = val);
                _saveSettings();
              },
            ),
            
            const SizedBox(height: 16),
            _buildToggle(
              'Automatic workout positioning',
              _autoPositioning,
              (val) {
                setState(() => _autoPositioning = val);
                _saveSettings();
              },
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Select your workout days', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
            ),
            const SizedBox(height: 16),
            
            // Days selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayBubble('Sun', 7),
                  _buildDayBubble('Mon', 1),
                  _buildDayBubble('Tue', 2),
                  _buildDayBubble('Wed', 3),
                  _buildDayBubble('Thu', 4),
                  _buildDayBubble('Fri', 5),
                  _buildDayBubble('Sat', 6),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'The highlighted days will be displayed in the calendar',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDayBubble(String label, int day) {
    final isSelected = _workoutDays.contains(day);
    return GestureDetector(
      onTap: () => _toggleDay(day),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.outline,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF888888),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleWithSubtitle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(child: Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Theme.of(context).colorScheme.secondary,
            inactiveTrackColor: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
}
