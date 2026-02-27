import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan_models.dart';
import '../providers/workout_provider.dart';
import 'exercise_library_screen.dart';

class CreateRoutineScreen extends StatefulWidget {
  final WorkoutPlan? existingPlan;
  final int? defaultDayNumber;

  const CreateRoutineScreen({super.key, this.existingPlan, this.defaultDayNumber});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  List<PlanExercise> _exercises = [];
  Set<int> _selectedDays = {1};

  bool get _isEditing => widget.existingPlan != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingPlan != null) {
      _nameController.text = widget.existingPlan!.name;
      _exercises = List.from(widget.existingPlan!.exercises);
      _selectedDays = {widget.existingPlan!.dayNumber};
    } else if (widget.defaultDayNumber != null) {
      _selectedDays = {widget.defaultDayNumber!};
    }
  }

  void _saveRoutine() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a routine name')));
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one exercise')));
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one day')));
      return;
    }

    final provider = context.read<WorkoutProvider>();

    if (_isEditing) {
      // Editing existing plan — single day update
      final newPlan = WorkoutPlan(
        id: widget.existingPlan?.id,
        name: name,
        dayNumber: _selectedDays.first,
        targetMuscles: widget.existingPlan?.targetMuscles ?? '',
        exercises: _exercises,
      );
      provider.saveWorkoutPlan(newPlan);
    } else {
      // Creating new — save a plan for each selected day
      for (final dayNum in _selectedDays) {
        final newPlan = WorkoutPlan(
          name: name,
          dayNumber: dayNum,
          targetMuscles: '',
          exercises: _exercises,
        );
        provider.saveWorkoutPlan(newPlan);
      }
    }
    Navigator.pop(context);
  }

  void _addExercise() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen(pickMode: true)),
    );
    
    if (result != null && result['name']!.isNotEmpty) {
      final selectedName = result['name']!;
      final muscleGroup = result['muscle_group'];
      final isCardio = ActiveExercise.detectCardio(selectedName, muscleGroup: muscleGroup);
      setState(() {
        if (isCardio) {
          _exercises.add(PlanExercise(
            name: selectedName,
            sets: 1,
            reps: 1,
            durationMinutes: 15,
            restSeconds: 0,
            weight: 0,
          ));
        } else if (_exercises.isNotEmpty) {
          final last = _exercises.last;
          _exercises.add(PlanExercise(
            name: selectedName, 
            sets: last.sets, 
            reps: last.reps, 
            restSeconds: last.restSeconds, 
            weight: last.weight
          ));
        } else {
          _exercises.add(PlanExercise(name: selectedName, sets: 3, reps: 10, restSeconds: 60, weight: 0));
        }
      });
    }
  }

  void _updateExercise(int index, PlanExercise updatedEx) {
    setState(() {
      _exercises[index] = updatedEx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.existingPlan == null ? 'Create Workout' : 'Edit Workout'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: const Text('Save', style: TextStyle(color: Color(0xFF00D4AA), fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'Workout Name',
              hintStyle: TextStyle(color: Color(0xFF6B6B8D)),
              border: InputBorder.none,
            ),
          ),
          Text(
            _isEditing ? 'Select your workout day' : 'Select workout days',
            style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              // 0:Sun, 1:Mon, 2:Tue, 3:Wed, 4:Thu, 5:Fri, 6:Sat
              // WorkoutPlan dayNumber is 1-7 where 1=Monday, 7=Sunday
              int dayNum = index == 0 ? 7 : index;
              final isSelected = _selectedDays.contains(dayNum);
              final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_isEditing) {
                      // Single selection when editing
                      _selectedDays = {dayNum};
                    } else {
                      // Multi-select toggle when creating
                      if (_selectedDays.contains(dayNum)) {
                        if (_selectedDays.length > 1) {
                          _selectedDays.remove(dayNum);
                        }
                      } else {
                        _selectedDays.add(dayNum);
                      }
                    }
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF00D4AA) : const Color(0xFF222222),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : const Color(0xFFA0A0C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            _isEditing
                ? 'The highlighted day will be displayed in the calendar'
                : 'Tap multiple days to assign this workout to each',
            style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text('Exercises', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _exercises.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _exercises.removeAt(oldIndex);
                _exercises.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final ex = _exercises[index];
              return _ExerciseCard(
                key: ValueKey('${ex.name}_$index'),
                exercise: ex,
                onUpdate: (updatedEx) => _updateExercise(index, updatedEx),
                onRemove: () {
                  setState(() {
                    _exercises.removeAt(index);
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
              foregroundColor: const Color(0xFF6C63FF),
              side: const BorderSide(color: Color(0xFF6C63FF)),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (widget.existingPlan != null) ...[
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                context.read<WorkoutProvider>().deleteWorkoutPlan(widget.existingPlan!.id!);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: const Color(0xFFFF6B6B),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final PlanExercise exercise;
  final ValueChanged<PlanExercise> onUpdate;
  final VoidCallback onRemove;

  const _ExerciseCard({
    super.key,
    required this.exercise,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final bool _isCardio;
  late TextEditingController _setsCtrl;
  late TextEditingController _repsCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _restCtrl;
  late TextEditingController _durationCtrl;

  @override
  void initState() {
    super.initState();
    _isCardio = ActiveExercise.detectCardio(widget.exercise.name);
    _setsCtrl = TextEditingController(text: widget.exercise.sets.toString());
    _repsCtrl = TextEditingController(text: widget.exercise.reps.toString());
    _weightCtrl = TextEditingController(text: widget.exercise.weight.toString());
    _restCtrl = TextEditingController(text: widget.exercise.restSeconds.toString());
    _durationCtrl = TextEditingController(text: (widget.exercise.durationMinutes ?? 15).toString());
  }

  @override
  void dispose() {
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _weightCtrl.dispose();
    _restCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  void _notifyUpdate() {
    if (_isCardio) {
      final duration = int.tryParse(_durationCtrl.text) ?? widget.exercise.durationMinutes ?? 15;
      final rest = int.tryParse(_restCtrl.text) ?? widget.exercise.restSeconds;
      widget.onUpdate(widget.exercise.copyWith(
        sets: 1,
        reps: 1,
        weight: 0,
        durationMinutes: duration,
        restSeconds: rest,
      ));
    } else {
      final sets = int.tryParse(_setsCtrl.text) ?? widget.exercise.sets;
      final reps = int.tryParse(_repsCtrl.text) ?? widget.exercise.reps;
      final weight = double.tryParse(_weightCtrl.text) ?? widget.exercise.weight;
      final rest = int.tryParse(_restCtrl.text) ?? widget.exercise.restSeconds;
      widget.onUpdate(widget.exercise.copyWith(
        sets: sets,
        reps: reps,
        weight: weight,
        restSeconds: rest,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A3E)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.drag_indicator, color: Color(0xFF6B6B8D)),
                const SizedBox(width: 8),
                if (_isCardio) ...[
                  const Icon(Icons.directions_run, color: Color(0xFF00D4AA), size: 18),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    widget.exercise.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFFF6B6B)),
                  onPressed: widget.onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isCardio)
              Row(
                children: [
                  Expanded(flex: 2, child: _buildInput('Duration\n(min)', _durationCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput('Rest\n(s)', _restCtrl)),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildInput('Sets', _setsCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput('Reps', _repsCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput('Weight\n(kg)', _weightCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput('Rest\n(s)', _restCtrl)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B6B8D), fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF111111),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
          onChanged: (_) => _notifyUpdate(),
        ),
      ],
    );
  }
}
