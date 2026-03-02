import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan_models.dart';
import '../providers/workout_provider.dart';
import '../utils/exercise_db.dart';
import 'exercise_info_screen.dart';
import 'settings_screen.dart';

/// Modern exercise library with grid/list view, GIF thumbnails,
/// category tabs with counts, and smooth search.
class ExerciseLibraryScreen extends StatefulWidget {
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
  bool _isGridView = true;
  String _selectedCategory = 'All';

  // Ordered categories with their metadata
  static const List<_CategoryMeta> _categoryDefs = [
    _CategoryMeta('All', Icons.apps_rounded, Color(0xFF6C63FF)),
    _CategoryMeta('Chest', Icons.expand_rounded, Color(0xFFFF6B6B)),
    _CategoryMeta('Back', Icons.swap_horiz_rounded, Color(0xFF4ECDC4)),
    _CategoryMeta('Shoulders', Icons.accessibility_new_rounded, Color(0xFFFFBE0B)),
    _CategoryMeta('Arms', Icons.sports_martial_arts_rounded, Color(0xFFFF006E)),
    _CategoryMeta('Forearms', Icons.front_hand_rounded, Color(0xFFFF8500)),
    _CategoryMeta('Core', Icons.center_focus_strong_rounded, Color(0xFF8338EC)),
    _CategoryMeta('Legs', Icons.directions_walk_rounded, Color(0xFF00D4AA)),
    _CategoryMeta('Glutes & Hips', Icons.airline_seat_legroom_extra_rounded, Color(0xFFFB5607)),
    _CategoryMeta('Calves', Icons.do_not_step_rounded, Color(0xFF3A86FF)),
    _CategoryMeta('Neck', Icons.person_rounded, Color(0xFFADB5BD)),
    _CategoryMeta('Cardio', Icons.directions_run_rounded, Color(0xFF2EC4B6)),
    _CategoryMeta('Plyometrics', Icons.flash_on_rounded, Color(0xFFE63946)),
    _CategoryMeta('Full Body', Icons.fitness_center_rounded, Color(0xFFFFB703)),
    _CategoryMeta('Stretches', Icons.self_improvement_rounded, Color(0xFF90BE6D)),
  ];

  Map<String, int> _categoryCounts = {};

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
      // Use shared cache from ExerciseDB (avoids re-loading JSON)
      final data = await ExerciseDB.getAllExercises();
      final exercises = data
          .where((e) => (e['name'] as String).length > 2)
          .toList()
        ..sort((a, b) => (a['name'] as String)
            .toLowerCase()
            .compareTo((b['name'] as String).toLowerCase()));

      // Build category counts
      final counts = <String, int>{'All': exercises.length};
      for (final ex in exercises) {
        final cat = ex['muscle_group'] as String? ?? 'Other';
        counts[cat] = (counts[cat] ?? 0) + 1;
      }

      setState(() {
        _allExercises = exercises;
        _filteredExercises = exercises;
        _categoryCounts = counts;
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
        if (_selectedCategory != 'All') {
          final cat = ex['muscle_group'] as String? ?? 'Other';
          if (cat != _selectedCategory) return false;
        }
        if (query.isNotEmpty) {
          final name = (ex['name'] as String).toLowerCase();
          final group = (ex['muscle_group'] as String? ?? '').toLowerCase();
          return name.contains(query) || group.contains(query);
        }
        return true;
      }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() => _selectedCategory = category);
    _filterExercises();
  }

  _CategoryMeta _getMeta(String cat) {
    return _categoryDefs.firstWhere(
      (m) => m.name == cat,
      orElse: () =>
          _CategoryMeta('Other', Icons.fitness_center, Theme.of(context).colorScheme.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // Sliver app bar with search
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  expandedHeight: 120,
                  title: Text(
                    widget.pickMode ? 'Choose Exercise' : 'Exercise Library',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: -0.3,
                    ),
                  ),
                  actions: [
                    // Grid/List toggle (available in both browse and pick modes)
                    IconButton(
                      icon: Icon(
                        _isGridView
                            ? Icons.view_list_rounded
                            : Icons.grid_view_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() => _isGridView = !_isGridView),
                      tooltip: _isGridView ? 'List view' : 'Grid view',
                    ),
                    if (!widget.pickMode)
                      IconButton(
                        icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      ),
                    const SizedBox(width: 4),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 8, top: 0),
                      child: _buildSearchBar(),
                    ),
                  ),
                ),

                // Category chips
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    categories: _categoryDefs
                        .where((m) =>
                            m.name == 'All' ||
                            (_categoryCounts[m.name] ?? 0) > 0)
                        .toList(),
                    counts: _categoryCounts,
                    selected: _selectedCategory,
                    onSelect: _selectCategory,
                  ),
                ),
              ],
              body: _filteredExercises.isEmpty
                  ? _buildEmptyState()
                  : _isGridView
                      ? _buildGridView()
                      : _buildListView(),
            ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Search ${_allExercises.length} exercises...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
        prefixIcon: Icon(Icons.search_rounded,
            color: Colors.white.withValues(alpha: 0.35), size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: Colors.white54, size: 18),
                onPressed: () => _searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 56, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          Text(
            'No exercises found',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search or category',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  GRID VIEW - Cards with GIF thumbnails
  // ═══════════════════════════════════════════
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) =>
          _buildGridCard(_filteredExercises[index]),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String;
    final imageUrl = exercise['image_url'] as String? ?? '';
    final muscleGroup = exercise['muscle_group'] as String? ?? '';
    final meta = _getMeta(muscleGroup);

    return GestureDetector(
      onTap: () => _onExerciseTap(exercise),
      onLongPress: () => _onExerciseLongPress(exercise),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: meta.color.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // GIF thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Theme.of(context).colorScheme.surface),
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      cacheWidth: (120 * MediaQuery.devicePixelRatioOf(context)).toInt(),
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.fitness_center_rounded,
                            color: meta.color.withValues(alpha: 0.3),
                            size: 36),
                      ),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: meta.color.withValues(alpha: 0.5),
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    )
                  else
                    Center(
                      child: Icon(Icons.fitness_center_rounded,
                          color: meta.color.withValues(alpha: 0.3), size: 36),
                    ),
                  // Category badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: meta.color.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        muscleGroup,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Pick mode add button
                  if (widget.pickMode)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, {'name': name, 'muscle_group': muscleGroup}),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Name section
            Expanded(
              flex: 1,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  LIST VIEW - Compact rows with thumbnails
  // ═══════════════════════════════════════════
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: _filteredExercises.length,
      itemBuilder: (context, index) =>
          _buildListTile(_filteredExercises[index]),
    );
  }

  Widget _buildListTile(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String;
    final imageUrl = exercise['image_url'] as String? ?? '';
    final muscleGroup = exercise['muscle_group'] as String? ?? '';
    final meta = _getMeta(muscleGroup);

    return InkWell(
      onTap: () => _onExerciseTap(exercise),
      onLongPress: () => _onExerciseLongPress(exercise),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            // GIF thumbnail (small)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(Icons.fitness_center_rounded,
                            color: meta.color.withValues(alpha: 0.4),
                            size: 22),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.fitness_center_rounded,
                          color: meta.color.withValues(alpha: 0.4), size: 22),
                    ),
            ),
            const SizedBox(width: 12),
            // Name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      muscleGroup,
                      style: TextStyle(
                        color: meta.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Action
            if (widget.pickMode)
              IconButton(
                icon: Icon(Icons.add_circle_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () =>
                    Navigator.pop(context, {'name': name, 'muscle_group': muscleGroup}),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.25), size: 22),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  Navigation
  // ═══════════════════════════════════════════
  void _onExerciseTap(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String;
    final images = (exercise['images'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList() ?? [];

    if (widget.pickMode) {
      final muscleGroup = exercise['muscle_group'] as String? ?? 'Other';
      Navigator.pop(context, {'name': name, 'muscle_group': muscleGroup});
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseInfoScreen(
          exerciseName: name,
          imageUrls: images,
        ),
      ),
    );
  }

  /// Show an "Add to workout plan" dialog for exercises tapped via long press
  void _onExerciseLongPress(Map<String, dynamic> exercise) {
    final name = exercise['name'] as String;
    if (widget.pickMode) return; // no long press action in pick mode

    final provider = context.read<WorkoutProvider>();
    final plans = provider.workoutPlans;

    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Create a workout plan first'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add "$name" to workout plan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.outline),
            ...plans.map((plan) => ListTile(
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('D${plan.dayNumber}', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 12))),
              ),
              title: Text(plan.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              subtitle: Text('${plan.exercises.length} exercises', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
              onTap: () async {
                Navigator.pop(ctx);
                // Add exercise to the plan
                final updatedPlan = plan.copyWith(
                  exercises: [...plan.exercises, PlanExercise(name: name, sets: 3, reps: 10, weight: 0)],
                );
                await provider.saveWorkoutPlan(updatedPlan);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "$name" to ${plan.name}'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                }
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Category metadata
// ═══════════════════════════════════════════════
class _CategoryMeta {
  final String name;
  final IconData icon;
  final Color color;
  const _CategoryMeta(this.name, this.icon, this.color);
}

// ═══════════════════════════════════════════════
//  Sticky category header delegate
// ═══════════════════════════════════════════════
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<_CategoryMeta> categories;
  final Map<String, int> counts;
  final String selected;
  final ValueChanged<String> onSelect;

  const _CategoryHeaderDelegate({
    required this.categories,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  double get minExtent => 56;
  @override
  double get maxExtent => 56;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = selected == cat.name;
            final count = counts[cat.name] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(cat.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cat.color
                        : cat.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? cat.color
                          : cat.color.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cat.color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cat.icon,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : cat.color.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : cat.color.withValues(alpha: 0.8),
                        ),
                      ),
                      if (cat.name != 'All') ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : cat.color.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return selected != oldDelegate.selected || counts != oldDelegate.counts;
  }
}
