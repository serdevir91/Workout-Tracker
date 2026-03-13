import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../db/database_helper.dart';
import '../l10n/translations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Request storage permissions based on Android version.
  Future<bool> _requestStoragePermission(BuildContext context) async {
    if (await Permission.manageExternalStorage.isGranted) return true;

    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    if (context.mounted) {
      final t = Translations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t.get('storage_permission_required'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: t.get('open_settings'),
            textColor: Colors.white,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
    return false;
  }

  Future<void> _backupDatabase(BuildContext context) async {
    final t = Translations.of(context);
    try {
      final hasPermission = await _requestStoragePermission(context);
      if (!hasPermission) return;

      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDbPath();

      final selectedDir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select folder to save backup',
      );
      if (selectedDir == null) return;

      final now = DateTime.now();
      final timestamp =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final backupPath = '$selectedDir/workout_backup_$timestamp.db';
      final backupFile = File(backupPath);

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      await File(dbPath).copy(backupPath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t.get('backup_saved')}:\n$backupPath',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t.get('backup_failed')}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  Future<void> _restoreDatabase(BuildContext context) async {
    final t = Translations.of(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select backup file to restore',
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null || result.files.single.path == null) return;

      final backupFile = File(result.files.single.path!);

      if (!await backupFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t.get('file_not_found'),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFFF6B6B),
            ),
          );
        }
        return;
      }

      final dbHelper = DatabaseHelper();
      final dbPath = await dbHelper.getDbPath();

      await dbHelper.closeAndReset();

      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      await backupFile.copy(dbPath);

      if (context.mounted) {
        final provider = context.read<WorkoutProvider>();
        await provider.loadWorkouts();
        if (context.mounted) {
          await context.read<SettingsProvider>().loadSettings();
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t.get('restore_success'),
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t.get('restore_failed')}: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  void _showBodyStatsDialog(BuildContext context, SettingsProvider provider) {
    final t = Translations.of(context);
    final isMetric = provider.isMetric;

    final heightCtrl = TextEditingController(
      text: (provider.height ?? 0) > 0
          ? (isMetric
                    ? provider.height!
                    : provider.displayLength(provider.height!))
                .toStringAsFixed(1)
          : '',
    );
    final weightCtrl = TextEditingController(
      text: (provider.weight ?? 0) > 0
          ? (isMetric
                    ? provider.weight!
                    : provider.displayWeight(provider.weight!))
                .toStringAsFixed(1)
          : '',
    );

    // Body measurement controllers
    final Map<String, TextEditingController> measureControllers = {};
    final measurementKeys = [
      'arm_circumference',
      'waist_circumference',
      'shoulder_width',
      'chest_circumference',
      'hip_circumference',
      'thigh_circumference',
      'calf_circumference',
      'neck_circumference',
      'forearm_circumference',
    ];
    final measurements = provider.allMeasurements;
    for (final key in measurementKeys) {
      final raw = measurements[key];
      measureControllers[key] = TextEditingController(
        text: (raw ?? 0) > 0
            ? (isMetric ? raw! : provider.displayLength(raw!)).toStringAsFixed(
                1,
              )
            : '',
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.get('edit_body_stats'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(color: Theme.of(context).colorScheme.outline, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Height + Weight
                    _buildMeasurementField(
                      label: t.get('height'),
                      controller: heightCtrl,
                      suffix: isMetric ? 'cm' : 'ft/in',
                      icon: Icons.height,
                    ),
                    const SizedBox(height: 12),
                    _buildMeasurementField(
                      label: t.get('weight'),
                      controller: weightCtrl,
                      suffix: provider.unit,
                      icon: Icons.monitor_weight_outlined,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      t.get('body_measurements'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...measurementKeys.map(
                      (key) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildMeasurementField(
                          label: t.get(key),
                          controller: measureControllers[key]!,
                          suffix: provider.lengthUnit,
                          icon: _getMeasurementIcon(key),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final h = double.tryParse(heightCtrl.text) ?? 0;
                      final w = double.tryParse(weightCtrl.text) ?? 0;
                      // Convert to storage units (cm, kg)
                      final heightCm = isMetric
                          ? h
                          : provider.toCmForStorage(h);
                      final weightKg = isMetric
                          ? w
                          : provider.toKgForStorage(w);
                      provider.updateProfile(heightCm, weightKg);

                      // Body measurements
                      final Map<String, double?> bodyValues = {};
                      for (final key in measurementKeys) {
                        final v = double.tryParse(
                          measureControllers[key]!.text,
                        );
                        if (v != null && v > 0) {
                          bodyValues[key] = isMetric
                              ? v
                              : provider.toCmForStorage(v);
                        }
                      }
                      provider.updateBodyMeasurements(
                        armCircumference: bodyValues['arm_circumference'],
                        waistCircumference: bodyValues['waist_circumference'],
                        shoulderWidth: bodyValues['shoulder_width'],
                        chestCircumference: bodyValues['chest_circumference'],
                        hipCircumference: bodyValues['hip_circumference'],
                        thighCircumference: bodyValues['thigh_circumference'],
                        calfCircumference: bodyValues['calf_circumference'],
                        neckCircumference: bodyValues['neck_circumference'],
                        forearmCircumference:
                            bodyValues['forearm_circumference'],
                      );

                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            t.get('measurement_saved'),
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                        ),
                      );
                    },
                    child: Text(
                      t.get('save'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeasurementField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  IconData _getMeasurementIcon(String key) {
    switch (key) {
      case 'arm_circumference':
        return Icons.fitness_center;
      case 'waist_circumference':
        return Icons.straighten;
      case 'shoulder_width':
        return Icons.accessibility_new;
      case 'chest_circumference':
        return Icons.expand;
      case 'hip_circumference':
        return Icons.accessibility;
      case 'thigh_circumference':
        return Icons.directions_walk;
      case 'calf_circumference':
        return Icons.directions_run;
      case 'neck_circumference':
        return Icons.person;
      case 'forearm_circumference':
        return Icons.front_hand;
      default:
        return Icons.straighten;
    }
  }

  void _showThemePicker(BuildContext context, SettingsProvider provider) {
    final t = Translations.of(context);
    final options = [
      {
        'key': 'system',
        'label': t.get('system_theme'),
        'icon': Icons.brightness_auto,
      },
      {'key': 'dark', 'label': t.get('dark_theme'), 'icon': Icons.dark_mode},
      {'key': 'light', 'label': t.get('light_theme'), 'icon': Icons.light_mode},
    ];
    final current = provider.themeMode == ThemeMode.light
        ? 'light'
        : provider.themeMode == ThemeMode.dark
        ? 'dark'
        : 'system';

    _showOptionsPicker(
      context: context,
      title: t.get('theme'),
      options: options,
      currentValue: current,
      onSelect: (val) => provider.updateTheme(val),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider provider) {
    final t = Translations.of(context);
    final options = [
      {'key': 'en', 'label': t.get('english'), 'icon': Icons.language},
      {'key': 'tr', 'label': t.get('turkish'), 'icon': Icons.language},
      {'key': 'es', 'label': t.get('spanish'), 'icon': Icons.language},
      {'key': 'de', 'label': t.get('german'), 'icon': Icons.language},
      {'key': 'fr', 'label': t.get('french'), 'icon': Icons.language},
    ];

    _showOptionsPicker(
      context: context,
      title: t.get('language'),
      options: options,
      currentValue: provider.language,
      onSelect: (val) => provider.updateLanguage(val),
    );
  }

  void _showMeasurementSystemPicker(
    BuildContext context,
    SettingsProvider provider,
  ) {
    final t = Translations.of(context);
    final options = [
      {
        'key': 'metric',
        'label': t.get('metric'),
        'icon': Icons.straighten,
        'desc': 'kg, cm',
      },
      {
        'key': 'imperial',
        'label': t.get('imperial'),
        'icon': Icons.square_foot,
        'desc': 'lbs, in',
      },
    ];

    _showOptionsPicker(
      context: context,
      title: t.get('measurement_system'),
      options: options,
      currentValue: provider.measurementSystem,
      onSelect: (val) => provider.updateMeasurementSystem(val),
    );
  }

  void _showColorPalettePicker(
    BuildContext context,
    SettingsProvider provider,
    Translations t,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.get('color_palette'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.get('color_palette_desc'),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              ...AppColorPalette.presets.map((palette) {
                final isSelected = provider.colorPaletteId == palette.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      provider.updateColorPalette(palette.id);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.primary.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? palette.primary : Colors.white10,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Color swatches
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: palette.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white12),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: palette.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Name
                          Expanded(
                            child: Text(
                              t.get(palette.nameKey),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? palette.primary
                                    : Colors.white70,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: palette.primary,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showBackgroundModePicker(
    BuildContext context,
    SettingsProvider provider,
    Translations t,
  ) {
    _showOptionsPicker(
      context: context,
      title: t.get('background_mode'),
      options: [
        {
          'key': 'default',
          'label': t.get('bg_default'),
          'icon': Icons.brightness_6,
        },
        {
          'key': 'pure_black',
          'label': t.get('pure_black'),
          'icon': Icons.brightness_1,
        },
      ],
      currentValue: provider.backgroundMode,
      onSelect: (value) => provider.updateBackgroundMode(value),
    );
  }

  void _showOptionsPicker({
    required BuildContext context,
    required String title,
    required List<Map<String, dynamic>> options,
    required String currentValue,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...options.map((opt) {
              final isSelected = opt['key'] == currentValue;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15)
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    opt['icon'] as IconData,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    opt['label'] as String,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: opt['desc'] != null
                      ? Text(
                          opt['desc'] as String,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.secondary,
                        )
                      : null,
                  onTap: () {
                    onSelect(opt['key'] as String);
                    Navigator.pop(ctx);
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(SettingsProvider provider, Translations t) {
    switch (provider.themeMode) {
      case ThemeMode.light:
        return t.get('light_theme');
      case ThemeMode.dark:
        return t.get('dark_theme');
      default:
        return t.get('system_theme');
    }
  }

  String _getLanguageLabel(SettingsProvider provider) {
    switch (provider.language) {
      case 'tr':
        return 'Türkçe';
      case 'es':
        return 'Español';
      default:
        return 'English';
    }
  }

  String _getFirstDayLabel(SettingsProvider provider) {
    switch (provider.firstDayOfWeek) {
      case 1:
        return 'Monday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return SettingsProvider.dayNames[(provider.firstDayOfWeek - 1).clamp(
          0,
          6,
        )];
    }
  }

  void _showFirstDayOfWeekPicker(
    BuildContext context,
    SettingsProvider provider,
    Translations t,
  ) {
    final options = [
      {'key': '1', 'label': t.get('monday'), 'icon': Icons.calendar_today},
      {'key': '6', 'label': t.get('saturday'), 'icon': Icons.calendar_today},
      {'key': '7', 'label': t.get('sunday'), 'icon': Icons.calendar_today},
    ];

    _showOptionsPicker(
      context: context,
      title: t.get('first_day_of_week'),
      options: options,
      currentValue: provider.firstDayOfWeek.toString(),
      onSelect: (val) => provider.updateFirstDayOfWeek(int.parse(val)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final t = Translations(provider.language);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(t.get('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile / Body Stats Card ──
          _buildSectionHeader(t.get('profile'), Icons.person),
          const SizedBox(height: 8),
          _buildProfileCard(provider, t),
          const SizedBox(height: 28),

          // ── Preferences ──
          _buildSectionHeader(t.get('preferences'), Icons.tune),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.brightness_6,
              iconColor: const Color(0xFFFFBE0B),
              title: t.get('theme'),
              value: _getThemeLabel(provider, t),
              onTap: () => _showThemePicker(context, provider),
            ),
            _buildSettingsTile(
              icon: Icons.language,
              iconColor: const Color(0xFF4ECDC4),
              title: t.get('language'),
              value: _getLanguageLabel(provider),
              onTap: () => _showLanguagePicker(context, provider),
            ),
            _buildSettingsTile(
              icon: Icons.straighten,
              iconColor: Theme.of(context).colorScheme.primary,
              title: t.get('measurement_system'),
              value: provider.isMetric ? t.get('metric') : t.get('imperial'),
              onTap: () => _showMeasurementSystemPicker(context, provider),
            ),
            _buildSettingsTile(
              icon: Icons.palette,
              iconColor: provider.colorPalette.primary,
              title: t.get('color_palette'),
              value: t.get(provider.colorPalette.nameKey),
              onTap: () => _showColorPalettePicker(context, provider, t),
            ),
            _buildSettingsTile(
              icon: Icons.dark_mode,
              iconColor: provider.isPureBlack
                  ? Colors.black
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              title: t.get('background_mode'),
              value: t.get(provider.isPureBlack ? 'pure_black' : 'bg_default'),
              onTap: () => _showBackgroundModePicker(context, provider, t),
            ),
            _buildSettingsTile(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF06D6A0),
              title: t.get('first_day_of_week'),
              value: _getFirstDayLabel(provider),
              onTap: () => _showFirstDayOfWeekPicker(context, provider, t),
              isLast: true,
            ),
          ]),
          const SizedBox(height: 28),

          // ── Data Management ──
          _buildSectionHeader(t.get('data_management'), Icons.storage),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSettingsTile(
              icon: Icons.cloud_upload_outlined,
              iconColor: Theme.of(context).colorScheme.secondary,
              title: t.get('backup_database'),
              value: t.get('backup_desc'),
              onTap: () => _backupDatabase(context),
            ),
            _buildSettingsTile(
              icon: Icons.cloud_download_outlined,
              iconColor: const Color(0xFFFF6B6B),
              title: t.get('restore_database'),
              value: t.get('restore_desc'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      t.get('restore_title'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    content: Text(
                      t.get('restore_confirm'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(t.get('cancel')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _restoreDatabase(context);
                        },
                        child: Text(
                          t.get('restore'),
                          style: const TextStyle(color: Color(0xFFFF6B6B)),
                        ),
                      ),
                    ],
                  ),
                );
              },
              isLast: true,
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(SettingsProvider provider, Translations t) {
    final hasMeasurements = provider.hasBodyMeasurements;
    final heightStr = (provider.height ?? 0) > 0
        ? provider.formatHeight(provider.height!)
        : '--';
    final weightStr = (provider.weight ?? 0) > 0
        ? provider.formatWeight(provider.weight!)
        : '--';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          // Height & Weight row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        const Color(0xFF8B5CF6),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.get('my_body_stats'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStatChip(Icons.height, heightStr),
                          const SizedBox(width: 12),
                          _buildStatChip(
                            Icons.monitor_weight_outlined,
                            weightStr,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showBodyStatsDialog(context, provider),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.secondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body measurements summary
          if (hasMeasurements) ...[
            Divider(
              color: Theme.of(context).colorScheme.outline,
              height: 1,
              indent: 20,
              endIndent: 20,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _buildMeasurementChips(provider, t),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                onTap: () => _showBodyStatsDialog(context, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        t.get('update_measurements'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildMeasurementChips(
    SettingsProvider provider,
    Translations t,
  ) {
    final measurements = provider.allMeasurements;
    final List<Widget> chips = [];

    for (final entry in measurements.entries) {
      final value = entry.value;
      if (value != null && value > 0) {
        chips.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Text(
              '${t.get(entry.key)}: ${provider.formatMeasurement(value)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        );
      }
    }
    return chips;
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surfaceContainerHigh
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.outline
              : const Color(0xFFE5E5EA),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.light
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(20))
                : BorderRadius.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        if (value.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            value,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 58,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.outline
                : const Color(0xFFE5E5EA),
          ),
      ],
    );
  }
}
