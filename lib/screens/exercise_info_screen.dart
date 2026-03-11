import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout_models.dart';
import '../models/workout_plan_models.dart';
import '../utils/exercise_db.dart';
import '../utils/formatters.dart';
import '../l10n/translations.dart';

/// Full exercise detail screen matching the app design.
/// Can be opened from:
/// - ExerciseLibraryScreen (view-only mode, no exerciseId)
/// - ActiveWorkoutScreen (interactive mode, exerciseId provided for adding sets)
class ExerciseInfoScreen extends StatefulWidget {
  final String exerciseName;

  /// List of image URLs (typically 2: start and end position).
  final List<String> imageUrls;

  /// If provided, sets can be added to this exercise in the active workout.
  final int? exerciseId;

  /// Target sets from the workout plan (shown in title as "done/total").
  final int targetSets;

  /// Target reps from the workout plan (shown in "Repeats required" circle).
  final int targetReps;

  /// Target weight from the workout plan.
  final double targetWeight;

  /// Rest duration in seconds from the workout plan.
  final int restSeconds;

  /// Current exercise position inside the swipeable workout flow.
  final int? currentExerciseIndex;

  /// Total exercise count inside the swipeable workout flow.
  final int? totalExerciseCount;

  /// Override cardio detection. If null, auto-detected from library + keywords.
  final bool? isCardio;

  const ExerciseInfoScreen({
    super.key,
    required this.exerciseName,
    this.imageUrls = const [],
    this.exerciseId,
    this.targetSets = 0,
    this.targetReps = 0,
    this.targetWeight = 0,
    this.restSeconds = 60,
    this.currentExerciseIndex,
    this.totalExerciseCount,
    this.isCardio,
  });

  @override
  State<ExerciseInfoScreen> createState() => _ExerciseInfoScreenState();
}

class _ExerciseInfoScreenState extends State<ExerciseInfoScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _manualDurationController =
      TextEditingController();
  late String _exerciseName;
  late List<String> _imageUrls;
  late bool _isCardio;
  bool _useManualDuration = false;
  int _currentImageIndex = 0;
  Timer? _imageCycleTimer;

  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = true;
  bool _showComment = false;

  @override
  void initState() {
    super.initState();
    _exerciseName = widget.exerciseName;
    _imageUrls = List<String>.from(widget.imageUrls);
    // Use provided isCardio if available, otherwise keyword-based detection initially
    _isCardio =
        widget.isCardio ?? ActiveExercise.detectCardio(_exerciseName);
    _loadHistory();
    _startImageCycle();

    // Async lookup from exercise library for more accurate cardio detection
    if (widget.isCardio == null) {
      _detectCardioFromLibrary();
    }

    // If in active workout mode, pre-fill weight/reps from draft or plan
    if (widget.exerciseId != null && !_isCardio) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<WorkoutProvider>();
        final draftW = provider.getDraftWeight(widget.exerciseId!);
        final draftR = provider.getDraftReps(widget.exerciseId!);

        // Use draft if available, otherwise fall back to plan values
        if (draftW.isNotEmpty) {
          _weightController.text = draftW;
        } else if (widget.targetWeight > 0) {
          _weightController.text =
              widget.targetWeight == widget.targetWeight.toInt()
              ? widget.targetWeight.toInt().toString()
              : widget.targetWeight.toStringAsFixed(1);
        }

        if (draftR.isNotEmpty) {
          _repsController.text = draftR;
        } else if (widget.targetReps > 0) {
          _repsController.text = widget.targetReps.toString();
        }
      });
    }
  }

  @override
  void dispose() {
    _imageCycleTimer?.cancel();
    _weightController.dispose();
    _repsController.dispose();
    _commentController.dispose();
    _manualDurationController.dispose();
    super.dispose();
  }

  /// Start auto-cycling between exercise images (GIF-like effect).
  void _startImageCycle() {
    if (_imageUrls.length <= 1) return;
    _imageCycleTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted) {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % _imageUrls.length;
        });
      }
    });
  }

  Future<void> _detectCardioFromLibrary() async {
    final muscleGroup = await ExerciseDB.findMuscleGroup(_exerciseName);
    final result = ActiveExercise.detectCardio(
      _exerciseName,
      muscleGroup: muscleGroup,
    );
    if (result != _isCardio && mounted) {
      setState(() {
        _isCardio = result;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final provider = context.read<WorkoutProvider>();
      final history = await provider.getExerciseHistory(_exerciseName);
      if (mounted) {
        setState(() {
          _history = history;
          _historyLoading = false;
        });
      }
    } catch (e, _) {
      debugPrint('Error loading history for "$_exerciseName": $e');
      if (mounted) {
        setState(() {
          _historyLoading = false;
          // Keep _history empty, will show "No history yet"
        });
      }
    }
  }

  /// Toggle between exercise images (start/end position).
  /// Also resets the auto-cycle timer so the next auto-switch doesn't come too soon.
  void _toggleImage() {
    if (_imageUrls.length <= 1) return;
    setState(() {
      _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
    });
    // Reset timer on manual tap
    _imageCycleTimer?.cancel();
    _startImageCycle();
  }

  /// Show a bottom sheet with alternative exercises from the same muscle group.
  Future<void> _showAlternativeExercises(
    BuildContext context,
    WorkoutProvider provider,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);

    // 1. Find current exercise's muscle group
    final muscleGroup = await ExerciseDB.findMuscleGroup(_exerciseName);
    if (!mounted) return;
    if (muscleGroup.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Could not find muscle group for this exercise'),
          backgroundColor: theme.colorScheme.surfaceContainer,
        ),
      );
      return;
    }

    // 2. Get all exercises in the same muscle group
    final alternatives = await ExerciseDB.getExercisesByMuscleGroup(
      muscleGroup,
    );
    // Remove current exercise from alternatives
    alternatives.removeWhere(
      (e) =>
          (e['name'] as String).toLowerCase() ==
          _exerciseName.toLowerCase(),
    );

    if (!mounted) return;

    if (alternatives.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('No alternative exercises found for $muscleGroup'),
          backgroundColor: theme.colorScheme.surfaceContainer,
        ),
      );
      return;
    }

    // 3. Show bottom sheet with alternatives
    showModalBottomSheet(
      context: context, // ignore: use_build_context_synchronously
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alternative exercises ($muscleGroup)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outline),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: alternatives.length,
                itemBuilder: (_, i) {
                  final alt = alternatives[i];
                  final name = alt['name'] as String;
                  final imageUrl = (alt['image_url'] ?? '').toString();
                  return ListTile(
                    leading: imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fitness_center,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.fitness_center,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                    title: Text(
                      name,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _swapToAlternative(
                        alternative: alt,
                        muscleGroup: muscleGroup,
                        provider: provider,
                        messenger: messenger,
                        theme: theme,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _swapToAlternative({
    required Map<String, dynamic> alternative,
    required String muscleGroup,
    required WorkoutProvider provider,
    required ScaffoldMessengerState messenger,
    required ThemeData theme,
  }) async {
    final exerciseId = widget.exerciseId;
    if (exerciseId == null) return;

    final newName = (alternative['name'] as String?)?.trim() ?? '';
    if (newName.isEmpty) return;

    await provider.replaceExercise(
      exerciseId,
      newName,
      muscleGroup: muscleGroup,
    );

    List<String> newImages = [];
    final rawImages = alternative['images'];
    if (rawImages is List) {
      newImages = rawImages
          .map((img) => img.toString())
          .where((img) => img.isNotEmpty)
          .toList();
    }
    if (newImages.isEmpty) {
      final fallback = (alternative['image_url'] as String?) ?? '';
      if (fallback.isNotEmpty) {
        newImages = [fallback];
      }
    }
    if (newImages.isEmpty) {
      final dbExercise = await ExerciseDB.findExercise(newName);
      final dbImages = (dbExercise?['images'] as List<dynamic>?)
          ?.map((img) => img.toString())
          .where((img) => img.isNotEmpty)
          .toList();
      if (dbImages != null && dbImages.isNotEmpty) {
        newImages = dbImages;
      }
    }

    final nextCardio = ActiveExercise.detectCardio(
      newName,
      muscleGroup: muscleGroup,
    );

    _imageCycleTimer?.cancel();
    if (!mounted) return;

    final targetWeightText = widget.targetWeight > 0
        ? (widget.targetWeight == widget.targetWeight.toInt()
              ? widget.targetWeight.toInt().toString()
              : widget.targetWeight.toStringAsFixed(1))
        : '';
    final targetRepsText =
        widget.targetReps > 0 ? widget.targetReps.toString() : '';
    _weightController.text = targetWeightText;
    _repsController.text = targetRepsText;
    _manualDurationController.clear();
    _commentController.clear();
    provider.setDraftWeight(exerciseId, targetWeightText);
    provider.setDraftReps(exerciseId, targetRepsText);

    setState(() {
      _exerciseName = newName;
      _imageUrls = newImages;
      _currentImageIndex = 0;
      _isCardio = nextCardio;
      _useManualDuration = false;
      _historyLoading = true;
    });

    await _loadHistory();
    _startImageCycle();

    messenger.showSnackBar(
      SnackBar(
        content: Text('Swapped to: $newName'),
        backgroundColor: theme.colorScheme.secondary,
      ),
    );
  }

  void _addSet(WorkoutProvider provider) {
    if (widget.exerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot add sets in view-only mode. Open an active workout first.',
          ),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    if (_isCardio) {
      int mins;
      if (_useManualDuration) {
        // Manual duration mode: read from text field
        mins = int.tryParse(_manualDurationController.text) ?? 0;
        if (mins <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a valid duration in minutes'),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            ),
          );
          return;
        }
      } else {
        // Timer mode: save elapsed timer duration as reps (minutes), weight = 0
        final elapsed =
            provider.exerciseElapsedSeconds[widget.exerciseId!] ?? 0;
        mins = elapsed ~/ 60;
        if (mins <= 0) mins = 1;
        if (provider.isCardioTimerActive(widget.exerciseId!)) {
          provider.stopCardioTimer(widget.exerciseId!);
        }
        provider.resetCardioElapsed(widget.exerciseId!);
      }
      provider.addSet(widget.exerciseId!, 0, mins);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duration saved: $mins min'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
      if (_useManualDuration) _manualDurationController.clear();
      return;
    }

    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter reps'),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        ),
      );
      return;
    }

    // Add set to provider (async operation)
    provider.addSet(widget.exerciseId!, weight, reps);
    provider.setDraftWeight(widget.exerciseId!, _weightController.text);
    provider.setDraftReps(widget.exerciseId!, _repsController.text);
    // Start rest countdown using the plan's rest duration
    provider.startRestTimer(widget.restSeconds > 0 ? widget.restSeconds : 60);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Set added: ${weight > 0 ? "${weight}kg" : "BW"} × $reps reps',
        ),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Consumer<WorkoutProvider>(
      builder: (context, provider, _) {
        // Find this exercise's sets in the active workout (if interactive mode)
        List<ExerciseSet> currentSets = [];
        if (widget.exerciseId != null && provider.isWorkoutActive) {
          final matches = provider.activeExercises
              .where((e) => e.exercise.id == widget.exerciseId)
              .toList();
          if (matches.isNotEmpty) {
            currentSets = matches.first.sets;
          }
        }

        final bool isInteractive =
            widget.exerciseId != null && provider.isWorkoutActive;
        final int setsDone = currentSets.length;
        final theme = Theme.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Hero GIF App Bar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                stretch: true,
                backgroundColor: theme.colorScheme.surface,
                leading: _buildCircularButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.pop(context),
                  theme: theme,
                ),
                actions: const [SizedBox(width: 8)],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Tap-to-toggle exercise images (start/end position)
                      if (_imageUrls.isNotEmpty)
                        GestureDetector(
                          onTap: _toggleImage,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Image.network(
                              _imageUrls[_currentImageIndex],
                              key: ValueKey(
                                _imageUrls[_currentImageIndex],
                              ),
                              fit: BoxFit.cover,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: theme.colorScheme.surfaceContainerHigh,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                                progress.expectedTotalBytes!
                                          : null,
                                      color: theme.colorScheme.secondary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, e, st) =>
                                  _buildNoGifPlaceholder(),
                            ),
                          ),
                        )
                      else
                        _buildNoGifPlaceholder(),
                      // Image index indicator (1/2 dot)
                      if (_imageUrls.length > 1)
                        Positioned(
                          top:
                              kToolbarHeight +
                              MediaQuery.of(context).padding.top +
                              4,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              _imageUrls.length,
                              (i) => Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i == _currentImageIndex
                                      ? theme.colorScheme.secondary
                                      : Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Bottom gradient overlay for readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 170,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                theme.scaffoldBackgroundColor.withValues(
                                  alpha: 0.8,
                                ),
                                theme.scaffoldBackgroundColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _exerciseName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if ((widget.totalExerciseCount ?? 0) > 1 ||
                                (isInteractive && widget.targetSets > 0) ||
                                isInteractive) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if ((widget.totalExerciseCount ?? 0) > 1)
                                    _buildHeroMetaChip(
                                      theme: theme,
                                      icon: Icons.swipe,
                                      label:
                                          '${(widget.currentExerciseIndex ?? 0) + 1} / ${widget.totalExerciseCount} moves',
                                    ),
                                  if (isInteractive && widget.targetSets > 0)
                                    _buildHeroMetaChip(
                                      theme: theme,
                                      icon: Icons.check_circle_outline,
                                      label:
                                          '$setsDone / ${widget.targetSets} sets',
                                      accentColor: theme.colorScheme.secondary,
                                    ),
                                  if (isInteractive)
                                    _buildHeroActionChip(
                                      theme: theme,
                                      icon: Icons.swap_horiz,
                                      label: 'Alternative',
                                      accentColor: theme.colorScheme.primary,
                                      onTap: () => _showAlternativeExercises(
                                        context,
                                        provider,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Main Content ──────────────────────────────────────
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // ── Metric Cards Row ────────────────────────────
                    ValueListenableBuilder<int>(
                      valueListenable: provider.restTimerNotifier,
                      builder: (_, v, ch) => _buildMetricCards(
                        provider,
                        setsDone,
                        currentSets,
                        theme,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Input Section (interactive mode) ────────────
                    if (isInteractive) ...[
                      _buildInputSection(provider),
                      const SizedBox(height: 8),

                      // "Add comment" toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _showComment = !_showComment),
                          child: Row(
                            children: [
                              Icon(
                                _showComment
                                    ? Icons.chat_bubble
                                    : Icons.chat_bubble_outline,
                                size: 16,
                                color: theme.colorScheme.secondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add comment',
                                style: TextStyle(
                                  color: theme.colorScheme.secondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_showComment)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: TextField(
                            controller: _commentController,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Optional note for this set...',
                              hintStyle: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHigh,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),
                    ],

                    // ── "Add to Workout" button (library/view-only mode) ──
                    if (!isInteractive)
                      _buildAddToWorkoutButton(provider, t, theme),

                    // ── HISTORY Section ─────────────────────────────
                    _buildHistorySection(),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================== WIDGETS ========================

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroMetaChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
    Color? accentColor,
  }) {
    final chipColor = accentColor ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chipColor.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActionChip({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? accentColor,
  }) {
    final chipColor = accentColor ?? theme.colorScheme.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipColor.withValues(alpha: 0.42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: chipColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: chipColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Add to Workout" section shown in library view-only mode
  Widget _buildAddToWorkoutButton(
    WorkoutProvider provider,
    Translations t,
    ThemeData theme,
  ) {
    final plans = provider.workoutPlans;
    if (plans.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.secondary.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showAddToWorkoutSheet(provider, t, theme),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: theme.colorScheme.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.get('add_to_workout'),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plans.length} ${plans.length == 1 ? 'workout' : 'workouts'} available',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddToWorkoutSheet(
    WorkoutProvider provider,
    Translations t,
    ThemeData theme,
  ) {
    final plans = provider.workoutPlans;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: theme.colorScheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t.get('add_to_workout')}: $_exerciseName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: theme.colorScheme.outline),
            ...plans.map(
              (plan) => ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'D${plan.dayNumber}',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  plan.name,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${plan.exercises.length} exercises',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.add, color: theme.colorScheme.secondary),
                onTap: () async {
                  Navigator.pop(ctx);
                  final updatedPlan = plan.copyWith(
                    exercises: [
                      ...plan.exercises,
                      PlanExercise(
                        name: _exerciseName,
                        sets: 3,
                        reps: 10,
                        weight: 0,
                      ),
                    ],
                  );
                  await provider.saveWorkoutPlan(updatedPlan);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Added "$_exerciseName" to ${plan.name}',
                        ),
                        backgroundColor: theme.colorScheme.secondary,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGifPlaceholder() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            'No animation available',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCards(
    WorkoutProvider provider,
    int setsDone,
    List<ExerciseSet> currentSets,
    ThemeData theme,
  ) {
    if (_isCardio) {
      final elapsed =
          provider.exerciseElapsedSeconds[widget.exerciseId ?? -1] ?? 0;
      final isTimerRunning =
          widget.exerciseId != null &&
          provider.isCardioTimerActive(widget.exerciseId!);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.timer_outlined,
                label: 'Duration',
                value: elapsed > 0 ? '${elapsed ~/ 60}m' : '–',
                theme: theme,
                isActive: isTimerRunning,
                accentColor: isTimerRunning
                    ? theme.colorScheme.secondary
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: isTimerRunning
                    ? Icons.play_circle_fill
                    : Icons.pause_circle_filled,
                label: 'Status',
                value: isTimerRunning ? 'Running' : 'Paused',
                theme: theme,
                isActive: isTimerRunning,
                accentColor: isTimerRunning
                    ? theme.colorScheme.secondary
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.check_circle_outline,
                label: 'Entries',
                value: '$setsDone',
                theme: theme,
                accentColor: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    // Non-cardio metrics
    int displayReps = widget.targetReps;
    if (displayReps <= 0 && _history.isNotEmpty) {
      final lastSession = _history.first;
      final sets = lastSession['sets'] as List<dynamic>?;
      if (sets != null && sets.isNotEmpty) {
        final lastSet = sets.last as Map<String, dynamic>;
        displayReps = (lastSet['reps'] as int?) ?? 0;
      }
    }
    if (displayReps <= 0) {
      displayReps = int.tryParse(_repsController.text) ?? 0;
    }

    final inputWeight = double.tryParse(_weightController.text) ?? 0;
    final restSecs = provider.restTimerSeconds;
    final restActive = provider.isRestTimerActive || restSecs > 0;
    final restDisplay = restActive
        ? formatDuration(restSecs)
        : formatDuration(widget.restSeconds > 0 ? widget.restSeconds : 60);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildMetricCard(
              icon: Icons.repeat,
              label: 'Reps',
              value: displayReps > 0 ? '$displayReps' : '–',
              theme: theme,
              accentColor: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              icon: Icons.hourglass_bottom,
              label: 'Rest',
              value: restDisplay,
              theme: theme,
              isActive: restActive,
              accentColor: restActive ? theme.colorScheme.primary : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildMetricCard(
              icon: inputWeight > 0
                  ? Icons.fitness_center
                  : Icons.check_circle_outline,
              label: inputWeight > 0
                  ? '${inputWeight.toStringAsFixed(inputWeight == inputWeight.toInt() ? 0 : 1)} kg'
                  : 'Sets',
              value: '$setsDone',
              theme: theme,
              accentColor: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
    bool isActive = false,
    Color? accentColor,
  }) {
    final color = accentColor ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: value.length > 4 ? 16 : 20,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(WorkoutProvider provider) {
    if (_isCardio) {
      return _buildCardioInputSection(provider);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Kilograms button/field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      onChanged: (val) {
                        provider.setDraftWeight(widget.exerciseId!, val);
                        setState(() {});
                      },
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: 'kg',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Kilograms',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Reps button/field
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repsController,
                      onChanged: (val) {
                        provider.setDraftReps(widget.exerciseId!, val);
                        setState(() {});
                      },
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      'Repeats',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // "+" add set button
          GestureDetector(
            onTap: () => _addSet(provider),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardioInputSection(WorkoutProvider provider) {
    final exerciseId = widget.exerciseId!;
    final isTimerActive = provider.isCardioTimerActive(exerciseId);
    final elapsed = provider.exerciseElapsedSeconds[exerciseId] ?? 0;

    return ValueListenableBuilder<Map<int, int>>(
      valueListenable: provider.exerciseTimersNotifier,
      builder: (_, exerciseTimers, _) {
        final currentElapsed = exerciseTimers[exerciseId] ?? elapsed;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isTimerActive
                      ? Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isTimerActive
                        ? Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: isTimerActive
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDuration(currentElapsed),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isTimerActive
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Toggle: Timer vs Manual input
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useManualDuration = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_useManualDuration
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.15)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: !_useManualDuration
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              size: 18,
                              color: !_useManualDuration
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Timer',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: !_useManualDuration
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useManualDuration = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _useManualDuration
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.15)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHigh,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border.all(
                            color: _useManualDuration
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 18,
                              color: _useManualDuration
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Manual',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _useManualDuration
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Conditional: Timer buttons OR Manual input
              if (_useManualDuration) ...[
                // Manual duration input
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _manualDurationController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                'Minutes',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _addSet(provider),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(
                          isTimerActive ? Icons.stop : Icons.play_arrow,
                        ),
                        onPressed: () {
                          if (isTimerActive) {
                            provider.stopCardioTimer(exerciseId);
                          } else {
                            provider.startCardioTimer(exerciseId);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTimerActive
                              ? const Color(0xFFFF6B6B)
                              : Theme.of(context).colorScheme.secondary,
                          foregroundColor: isTimerActive
                              ? Colors.white
                              : Colors.black,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          isTimerActive ? 'Stop' : 'Start',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        onPressed: currentElapsed > 0
                            ? () => _addSet(provider)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Theme.of(
                            context,
                          ).colorScheme.outline,
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        label: Text(
                          'Save (${currentElapsed ~/ 60} min)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _canEditCurrentSessionSets(WorkoutProvider provider) {
    final activeWorkout = provider.activeWorkout;
    if (widget.exerciseId == null ||
        !provider.isWorkoutActive ||
        activeWorkout == null) {
      return false;
    }
    return _isSameDate(activeWorkout.startTime, DateTime.now());
  }

  Future<void> _editCurrentSessionSet({
    required WorkoutProvider provider,
    required ExerciseSet set,
  }) async {
    if (!_canEditCurrentSessionSets(provider) ||
        widget.exerciseId == null ||
        set.id == null) {
      return;
    }

    final weightController = TextEditingController(
      text: set.weight > 0 ? set.weight.toString() : '',
    );
    final repsController = TextEditingController(text: set.reps.toString());
    final theme = Theme.of(context);

    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outline),
          ),
          title: Text(
            'Edit Set #${set.setNumber}',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isCardio) ...[
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _isCardio ? 'Minutes' : 'Reps',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            TextButton(
              onPressed: () async {
                final reps = int.tryParse(repsController.text.trim()) ?? 0;
                final weight = _isCardio
                    ? 0.0
                    : (double.tryParse(weightController.text.trim()) ?? 0.0);

                if (reps <= 0) {
                  return;
                }

                await provider.updateSet(
                  widget.exerciseId!,
                  set.id!,
                  weight,
                  reps,
                );
                if (!mounted || !ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: Text(
                'Save',
                style: TextStyle(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } finally {
      weightController.dispose();
      repsController.dispose();
    }
  }

  Widget _buildHistorySection() {
    final theme = Theme.of(context);
    final provider = context.read<WorkoutProvider>();
    List<ExerciseSet> currentSets = [];
    if (widget.exerciseId != null && provider.isWorkoutActive) {
      final matches = provider.activeExercises
          .where((e) => e.exercise.id == widget.exerciseId)
          .toList();
      if (matches.isNotEmpty) {
        currentSets = matches.first.sets.where((s) => s.completed).toList();
      }
    }
    final hasCurrentSets = currentSets.isNotEmpty;
    final canEditCurrentSets = _canEditCurrentSessionSets(provider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                'HISTORY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_historyLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.secondary,
                  strokeWidth: 2,
                ),
              ),
            )
          else if (!hasCurrentSets && _history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 36,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No history yet',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (hasCurrentSets)
              _buildCurrentSessionCard(
                currentSets,
                theme,
                provider,
                canEditCurrentSets,
              ),
            ..._history.map(
              (session) => _buildHistorySessionCard(session, theme),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentSessionCard(
    List<ExerciseSet> sets,
    ThemeData theme,
    WorkoutProvider provider,
    bool canEditCurrentSets,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Current Session',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.secondary,
                ),
              ),
              if (canEditCurrentSets) ...[
                const SizedBox(width: 8),
                Text(
                  'Tap set to edit',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ...sets.map((s) {
            final setDescription = _isCardio
                ? '${s.reps} min'
                : '${s.weight > 0 ? '${s.weight.toStringAsFixed(s.weight == s.weight.toInt() ? 0 : 1)} kg' : 'BW'} x ${s.reps} reps';
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: canEditCurrentSets
                  ? () => _editCurrentSessionSet(provider: provider, set: s)
                  : null,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '#${s.setNumber}',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        setDescription,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (canEditCurrentSets)
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  Widget _buildHistorySessionCard(
    Map<String, dynamic> session,
    ThemeData theme,
  ) {
    final startTimeStr = session['start_time'] as String;
    final date = DateTime.tryParse(startTimeStr) ?? DateTime.now();
    final sets = session['sets'] as List;

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[date.weekday - 1];
    final dateStr =
        '$dayName, ${date.day}/${date.month}/${date.year.toString().substring(2)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sets.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final weight = (s['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = s['reps'] as int? ?? 0;
            final setNum = s['set_number'] as int? ?? (i + 1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#$setNum',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isCardio
                          ? '$reps min'
                          : '${weight > 0 ? "${weight.toStringAsFixed(weight == weight.toInt() ? 0 : 1)} kg" : "BW"} × $reps reps',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}


