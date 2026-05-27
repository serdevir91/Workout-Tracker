import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/premade_programs.dart';
import '../models/workout_plan_models.dart';
import '../providers/workout_provider.dart';
import '../providers/monetization_provider.dart';
import '../l10n/translations.dart';
import 'paywall_screen.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  String _selectedCategory = 'All';

  List<String> get _categories {
    final cats = premadePrograms.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<PremadeProgram> get _filteredPrograms {
    if (_selectedCategory == 'All') return premadePrograms;
    return premadePrograms.where((p) => p.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('premade_programs')),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: colorScheme.secondary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredPrograms.length,
              itemBuilder: (context, index) {
                return _ProgramCard(program: _filteredPrograms[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends StatefulWidget {
  final PremadeProgram program;

  const _ProgramCard({required this.program});

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.program.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.program.difficulty,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.program.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.program.plans.length} ${t.get('days')}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.fitness_center, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        widget.program.category,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            ...widget.program.plans.asMap().entries.map((entry) {
              return _PlanPreviewTile(
                plan: entry.value,
                onAdd: () => _addPlanToRoutines(entry.value),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _addPlanToRoutines(WorkoutPlan plan) async {
    final t = Translations.of(context);
    final provider = context.read<WorkoutProvider>();
    final monetization = context.read<MonetizationProvider>();

    if (!monetization.canCreateUnlimitedRoutines &&
        provider.workoutPlans.length >= MonetizationProvider.freeRoutineLimit) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaywallScreen(
              reason: t.get('free_routine_limit_reached'),
            ),
          ),
        );
      }
      return;
    }

    await provider.saveWorkoutPlan(plan.copyWith(id: null));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${plan.name} ${t.get('added_to_routines')}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _PlanPreviewTile extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onAdd;

  const _PlanPreviewTile({required this.plan, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = Translations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.targetMuscles,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: Text(t.get('add_to_routines')),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...plan.exercises.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${ex.sets}x${ex.reps} ${ex.name}${ex.weight > 0 ? ' (${ex.weight}kg)' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Divider(height: 16, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }
}
