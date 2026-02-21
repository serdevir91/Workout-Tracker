import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'exercise_info_screen.dart';

/// A screen that loads all ExRx exercises from JSON and allows
/// searching/filtering by muscle group category and viewing exercise info.
class ExerciseLibraryScreen extends StatefulWidget {
  /// If true, the screen acts as a picker — tapping an exercise returns it.
  final bool pickMode;

  const ExerciseLibraryScreen({super.key, this.pickMode = false});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  // Category icons and colors
  static const Map<String, IconData> _categoryIcons = {
    'All': Icons.apps,
    'Back': Icons.arrow_back,
    'Chest': Icons.expand,
    'Shoulders': Icons.accessibility_new,
    'Arms': Icons.sports_martial_arts,
    'Forearms': Icons.front_hand,
    'Core': Icons.center_focus_strong,
    'Glutes & Hips': Icons.airline_seat_legroom_extra,
    'Legs': Icons.directions_walk,
    'Calves': Icons.do_not_step,
    'Neck': Icons.person,
    'Full Body': Icons.fitness_center,
    'Plyometrics': Icons.flash_on,
    'Cardio': Icons.directions_run,
  };

  static const Map<String, Color> _categoryColors = {
    'All': Color(0xFF6C63FF),
    'Back': Color(0xFF4ECDC4),
    'Chest': Color(0xFFFF6B6B),
    'Shoulders': Color(0xFFFFBE0B),
    'Arms': Color(0xFFFF006E),
    'Forearms': Color(0xFFFF8500),
    'Core': Color(0xFF8338EC),
    'Glutes & Hips': Color(0xFFFB5607),
    'Legs': Color(0xFF00D4AA),
    'Calves': Color(0xFF3A86FF),
    'Neck': Color(0xFFADB5BD),
    'Full Body': Color(0xFFFFB703),
    'Plyometrics': Color(0xFFE63946),
    'Cardio': Color(0xFF2EC4B6),
  };

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _searchController.addListener(_filterExercises);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/exrx_exercises.json');
      final List<dynamic> data = json.decode(jsonStr);
      final exercises = data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((e) => (e['name'] as String).length > 2)
          .toList()
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      // Extract unique categories
      final catSet = <String>{};
      for (final ex in exercises) {
        final cat = ex['muscle_group'] as String? ?? 'Other';
        // Only add base category (not stretch variants)
        final baseCat = cat.replaceAll(' (Stretch)', '');
        catSet.add(baseCat);
      }

      final cats = catSet.toList()..sort();
      cats.insert(0, 'All');

      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _categories = cats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterExercises() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        // Category filter
        if (_selectedCategory != 'All') {
          final cat = ex['muscle_group'] as String? ?? 'Other';
          final baseCat = cat.replaceAll(' (Stretch)', '');
          if (baseCat != _selectedCategory) return false;
        }

        // Search filter
        if (query.isNotEmpty) {
          return (ex['name'] as String).toLowerCase().contains(query);
        }
        return true;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: Text(
          widget.pickMode ? 'Choose Exercise' : 'Exercise Library',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search ${_allExercises.length} exercises...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.4)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1A2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : Column(
              children: [
                // Category chips
                SizedBox(
                  height: 48,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                        PointerDeviceKind.trackpad,
                      },
                    ),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        final color = _categoryColors[cat] ?? const Color(0xFF6C63FF);
                        final icon = _categoryIcons[cat] ?? Icons.fitness_center;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 14,
                                    color: isSelected ? Colors.white : color),
                                const SizedBox(width: 4),
                                Text(cat, style: TextStyle(fontSize: 12,
                                    color: isSelected ? Colors.white : color)),
                              ],
                            ),
                            onSelected: (_) => _selectCategory(cat),
                            selectedColor: color,
                            backgroundColor: color.withValues(alpha: 0.1),
                            side: BorderSide(color: color.withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Exercise list
                Expanded(
                  child: _filteredExercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 48,
                                  color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                'No exercises found',
                                style: TextStyle(color: Color(0xFF8888AA), fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredExercises.length,
                          padding: const EdgeInsets.only(top: 4, bottom: 100),
                          itemBuilder: (context, index) {
                            final exercise = _filteredExercises[index];
                            final name = exercise['name'] as String;
                            final url = exercise['url'] as String;
                            final gifUrl = exercise['gif_url'] as String? ?? '';
                            final muscleGroup = exercise['muscle_group'] as String? ?? '';
                            final baseCat = muscleGroup.replaceAll(' (Stretch)', '');
                            final catColor = _categoryColors[baseCat] ?? const Color(0xFF6C63FF);

                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 8,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: catColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: muscleGroup.isNotEmpty
                                  ? Text(
                                      muscleGroup,
                                      style: TextStyle(
                                        color: catColor.withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                    )
                                  : null,
                              trailing: widget.pickMode
                                  ? const Icon(Icons.add_circle_outline,
                                      color: Color(0xFF6C63FF), size: 20)
                                  : Icon(
                                      gifUrl.isNotEmpty
                                          ? Icons.play_circle_fill
                                          : Icons.open_in_new,
                                      color: const Color(0xFF00D4AA),
                                      size: 20),
                              onTap: () {
                                if (widget.pickMode) {
                                  Navigator.pop(context, name);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ExerciseInfoScreen(
                                        exerciseName: name,
                                        exrxUrl: url,
                                        gifUrl: gifUrl,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
