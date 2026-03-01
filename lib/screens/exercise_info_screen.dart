import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/workout_provider.dart';
import '../models/workout_models.dart';
import '../utils/exrx_url_matcher.dart';
import '../utils/formatters.dart';


/// Full exercise detail screen matching the app design.
/// Can be opened from:
/// - ExerciseLibraryScreen (view-only mode, no exerciseId)
/// - ActiveWorkoutScreen (interactive mode, exerciseId provided for adding sets)
class ExerciseInfoScreen extends StatefulWidget {
  final String exerciseName;
  final String exrxUrl;
  final String gifUrl;

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

  /// Override cardio detection. If null, auto-detected from library + keywords.
  final bool? isCardio;

  const ExerciseInfoScreen({
    super.key,
    required this.exerciseName,
    required this.exrxUrl,
    this.gifUrl = '',
    this.exerciseId,
    this.targetSets = 0,
    this.targetReps = 0,
    this.targetWeight = 0,
    this.restSeconds = 60,
    this.isCardio,
  });


  @override
  State<ExerciseInfoScreen> createState() => _ExerciseInfoScreenState();
}

class _ExerciseInfoScreenState extends State<ExerciseInfoScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _repsController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  late bool _isCardio;

  List<Map<String, dynamic>> _history = [];
  bool _historyLoading = true;
  bool _showComment = false;

  @override
  void initState() {
    super.initState();
    // Use provided isCardio if available, otherwise keyword-based detection initially
    _isCardio = widget.isCardio ?? ActiveExercise.detectCardio(widget.exerciseName);
    _loadHistory();

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
          _weightController.text = widget.targetWeight == widget.targetWeight.toInt()
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
    _weightController.dispose();
    _repsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _detectCardioFromLibrary() async {
    final muscleGroup = await ExrxUrlMatcher.findMuscleGroup(widget.exerciseName);
    final result = ActiveExercise.detectCardio(widget.exerciseName, muscleGroup: muscleGroup);
    if (result != _isCardio && mounted) {
      setState(() {
        _isCardio = result;
      });
    }
  }

  Future<void> _loadHistory() async {
    try {
      final provider = context.read<WorkoutProvider>();
      final history = await provider.getExerciseHistory(widget.exerciseName);
      if (mounted) {
        setState(() {
          _history = history;
          _historyLoading = false;
        });
      }
    } catch (e, _) {
      debugPrint('⚠️ Error loading history for "${widget.exerciseName}": $e');
      if (mounted) {
        setState(() {
          _historyLoading = false;
          // Keep _history empty, will show "No history yet"
        });
      }
    }
  }

  Future<void> _launchUrl() async {
    if (widget.exrxUrl.isEmpty) return;
    final uri = Uri.parse(widget.exrxUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _addSet(WorkoutProvider provider) {
    if (widget.exerciseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot add sets in view-only mode. Open an active workout first.'),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

    if (_isCardio) {
      // Cardio: save elapsed timer duration as reps (minutes), weight = 0
      final elapsed = provider.exerciseElapsedSeconds[widget.exerciseId!] ?? 0;
      int mins = elapsed ~/ 60;
      if (mins <= 0) mins = 1;
      if (provider.isCardioTimerActive(widget.exerciseId!)) {
        provider.stopCardioTimer(widget.exerciseId!);
      }
      provider.addSet(widget.exerciseId!, 0, mins);
      provider.resetCardioElapsed(widget.exerciseId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duration saved: $mins min'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter reps'), backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
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
        content: Text('Set added: ${weight > 0 ? "${weight}kg" : "BW"} × $reps reps'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

        final bool isInteractive = widget.exerciseId != null && provider.isWorkoutActive;
        final int setsDone = currentSets.length;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              '${widget.targetSets > 0 ? "$setsDone/${widget.targetSets}" : (setsDone > 0 ? "$setsDone" : "")} ${widget.exerciseName}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (isInteractive)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFFF6B6B), size: 18),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── GIF Section ──────────────────────────────────────
                      _buildGifSection(),

                      const SizedBox(height: 16),

                      // ── Exercise Name & Recommended Weight ─────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.exerciseName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            if (!isInteractive) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Tap on ExRx.net for full details',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(Icons.info_outline,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── 3 Metric Circles (Reps / Rest / Sets) ──────────
                      ValueListenableBuilder<int>(
                        valueListenable: provider.restTimerNotifier,
                        builder: (_, _, _) => _buildMetricCircles(provider, setsDone, currentSets),
                      ),

                      const SizedBox(height: 20),

                      // ── Input Section (only in interactive mode) ────────
                      if (isInteractive) ...[
                        _buildInputSection(provider),
                        const SizedBox(height: 12),

                        // "Add comment" row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GestureDetector(
                            onTap: () => setState(() => _showComment = !_showComment),
                            child: Text(
                              'Add comment',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (_showComment)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: TextField(
                              controller: _commentController,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                              maxLines: 2,
                              decoration: InputDecoration(
                                hintText: 'Optional note for this set...',
                                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                                filled: true,
                                fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),
                      ],

                      // ── HISTORY Section ─────────────────────────────────
                      _buildHistorySection(),

                      const SizedBox(height: 100), // space for bottom button
                    ],
                  ),
                ),
              ),

              // ── ExRx.net Button at the Bottom ──────────────────────────
              _buildExRxButton(),
            ],
          ),
        );
      },
    );
  }

  // ======================== WIDGETS ========================

  Widget _buildGifSection() {
    final hasGif = widget.gifUrl.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 280,
      child: hasGif
          ? Image.network(
              widget.gifUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Theme.of(context).colorScheme.secondary,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildNoGifPlaceholder();
              },
            )
          : _buildNoGifPlaceholder(),
    );
  }

  Widget _buildNoGifPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text(
            'No animation available',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCircles(
      WorkoutProvider provider, int setsDone, List<ExerciseSet> currentSets) {

    if (_isCardio) {
      // For cardio exercises: show Duration / Timer / Entries
      final elapsed = provider.exerciseElapsedSeconds[widget.exerciseId ?? -1] ?? 0;
      final isTimerRunning = widget.exerciseId != null && provider.isCardioTimerActive(widget.exerciseId!);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: _buildCircleMetric(
                label: 'Duration',
                value: elapsed > 0 ? '${elapsed ~/ 60}m' : '–',
                color: isTimerRunning ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                progress: isTimerRunning ? 1.0 : 0.0,
                isActive: isTimerRunning,
              ),
            ),
            Expanded(
              child: _buildCircleMetric(
                label: 'Status',
                value: isTimerRunning ? '⏱️' : '⏸️',
                color: isTimerRunning ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                progress: isTimerRunning ? 1.0 : 0.0,
                isActive: isTimerRunning,
              ),
            ),
            Expanded(
              child: _buildCircleMetric(
                label: 'Entries\nsaved',
                value: setsDone > 0 ? '$setsDone' : '0',
                color: Theme.of(context).colorScheme.secondary,
                progress: setsDone > 0 ? 1.0 : 0.0,
              ),
            ),
          ],
        ),
      );
    }

    // Non-cardio: Repeats / Rest / Sets
    // "Repeats required" always uses the plan target (widget.targetReps).
    // If no plan target (manual exercise), use the last historical reps value.
    int displayReps = widget.targetReps;
    if (displayReps <= 0 && _history.isNotEmpty) {
      // Get last recorded reps from history
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
    final restDisplay = restActive ? formatDuration(restSecs) : formatDuration(widget.restSeconds > 0 ? widget.restSeconds : 60);
    final maxRestSecs = widget.restSeconds > 0 ? widget.restSeconds : 60;

    // Sets label shows plan target sets if available
    final String setsLabel = 'Sets\ndone';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCircleMetric(
              label: 'Repeats\nrequired',
              value: displayReps > 0 ? '$displayReps' : '–',
              color: Theme.of(context).colorScheme.secondary,
              progress: displayReps > 0 ? 1.0 : 0.0,
            ),
          ),
          Expanded(
            child: _buildCircleMetric(
              label: 'Rest',
              value: restDisplay,
              color: restActive ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
              progress: restActive ? (restSecs / maxRestSecs).clamp(0.0, 1.0) : 0.8,
              isActive: restActive,
            ),
          ),
          Expanded(
            child: _buildCircleMetric(
              label: inputWeight > 0 ? '${inputWeight.toStringAsFixed(inputWeight == inputWeight.toInt() ? 0 : 1)} kg' : setsLabel,
              value: setsDone > 0 ? '$setsDone' : '0',
              color: Theme.of(context).colorScheme.secondary,
              progress: setsDone > 0 ? (setsDone / (setsDone + 1)).clamp(0.0, 1.0) : 0.0,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCircleMetric({
    required String label,
    required String value,
    required Color color,
    required double progress,
    bool isActive = false,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 88,
          height: 88,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 5,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isActive ? color : color.withValues(alpha: 0.8),
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: value.length > 4 ? 14 : 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.3,
          ),
        ),
      ],
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
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'kg',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text('Kilograms', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
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
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text('Repeats', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
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
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isTimerActive
                      ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isTimerActive
                        ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer,
                      color: isTimerActive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      formatDuration(currentElapsed),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isTimerActive ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(isTimerActive ? Icons.stop : Icons.play_arrow),
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
                        foregroundColor: isTimerActive ? Colors.white : Colors.black,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(
                        isTimerActive ? 'Stop' : 'Start',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      onPressed: currentElapsed > 0 ? () => _addSet(provider) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Theme.of(context).colorScheme.outline,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      label: Text(
                        'Save (${currentElapsed ~/ 60} min)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistorySection() {
    // Provider is available from the outer Consumer — no need for a nested one
    final provider = context.read<WorkoutProvider>();
        // Get current active sets for this exercise (if active workout is open)
        List<ExerciseSet> currentSets = [];
        if (widget.exerciseId != null && provider.isWorkoutActive) {
          final matches = provider.activeExercises
              .where((e) => e.exercise.id == widget.exerciseId)
              .toList();
          if (matches.isNotEmpty) {
            currentSets = matches.first.sets.where((s) => s.completed).toList();
          }
        }

        // Build display list: current session first, then past sessions
        bool hasCurrentSets = currentSets.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Theme.of(context).colorScheme.outline, height: 1),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'HISTORY',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_historyLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary, strokeWidth: 2),
                ),
              )
            else if (!hasCurrentSets && _history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Text(
                    'No history yet. Start your first set!',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                  ),
                ),
              )
            else
              ...[
                // Show current session if sets exist
                if (hasCurrentSets)
                  _buildCurrentSessionWidget(currentSets),
                // Show past sessions from history
                ..._history.map((session) => _buildHistorySession(session)),
              ],
          ],
        );
  }

  Widget _buildCurrentSessionWidget(List<ExerciseSet> sets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY (CURRENT)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...sets.asMap().entries.map((entry) {
            final s = entry.value;
            final weight = s.weight;
            final reps = s.reps;
            final setNum = s.setNumber;

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#$setNum',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    _isCardio
                        ? '$reps min'
                        : '${weight > 0 ? "${weight.toStringAsFixed(weight == weight.toInt() ? 0 : 1)} kg" : "BW"} x $reps reps',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'live',
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySession(Map<String, dynamic> session) {
    final startTimeStr = session['start_time'] as String;
    final date = DateTime.tryParse(startTimeStr) ?? DateTime.now();
    final sets = session['sets'] as List;

    // Format date: "Wed, 2/25/26"
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = dayNames[date.weekday - 1];
    final dateStr = '$dayName, ${date.month}/${date.day}/${date.year.toString().substring(2)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...sets.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final weight = (s['weight'] as num?)?.toDouble() ?? 0.0;
            final reps = s['reps'] as int? ?? 0;
            final setNum = s['set_number'] as int? ?? (i + 1);

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#$setNum',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                  Text(
                    _isCardio
                        ? '$reps min'
                        : '${weight > 0 ? "${weight.toStringAsFixed(weight == weight.toInt() ? 0 : 1)} kg" : "BW"} x $reps reps',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildExRxButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _launchUrl,
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text(
            'Full Details on ExRx.net',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
