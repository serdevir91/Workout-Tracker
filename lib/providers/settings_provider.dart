import 'package:flutter/material.dart';
import '../db/database_helper.dart';

/// Color palette preset definitions.
class AppColorPalette {
  final String id;
  final String nameKey; // translation key
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color error;

  const AppColorPalette({
    required this.id,
    required this.nameKey,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.error,
  });

  static const List<AppColorPalette> presets = [
    AppColorPalette(
      id: 'default',
      nameKey: 'palette_default',
      primary: Color(0xFF6C63FF),
      secondary: Color(0xFF00D4AA),
      accent: Color(0xFF6B6B8D),
      error: Color(0xFFFF6B6B),
    ),
    AppColorPalette(
      id: 'ocean',
      nameKey: 'palette_ocean',
      primary: Color(0xFF0077B6),
      secondary: Color(0xFF00B4D8),
      accent: Color(0xFF90E0EF),
      error: Color(0xFFE63946),
    ),
    AppColorPalette(
      id: 'sunset',
      nameKey: 'palette_sunset',
      primary: Color(0xFFFF6B35),
      secondary: Color(0xFFFFD166),
      accent: Color(0xFFEF476F),
      error: Color(0xFFE63946),
    ),
    AppColorPalette(
      id: 'forest',
      nameKey: 'palette_forest',
      primary: Color(0xFF2D6A4F),
      secondary: Color(0xFF52B788),
      accent: Color(0xFF95D5B2),
      error: Color(0xFFD62828),
    ),
    AppColorPalette(
      id: 'rose',
      nameKey: 'palette_rose',
      primary: Color(0xFFBE185D),
      secondary: Color(0xFFFB7185),
      accent: Color(0xFFFDA4AF),
      error: Color(0xFFDC2626),
    ),
    AppColorPalette(
      id: 'crimson',
      nameKey: 'palette_crimson',
      primary: Color(0xFFDC2626),
      secondary: Color(0xFFF97316),
      accent: Color(0xFFFBBF24),
      error: Color(0xFFB91C1C),
    ),
  ];

  static AppColorPalette getById(String id) {
    return presets.firstWhere((p) => p.id == id, orElse: () => presets.first);
  }
}

/// Unit conversion helpers.
class UnitConverter {
  static double kgToLbs(double kg) => kg * 2.20462;
  static double lbsToKg(double lbs) => lbs / 2.20462;
  static double cmToInches(double cm) => cm / 2.54;
  static double inchesToCm(double inches) => inches * 2.54;

  /// Convert a height in cm to feet'inches" string (e.g. "5'11\"").
  static String cmToFeetInchesStr(double cm) {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return "$feet'$inches\"";
  }

  /// Convert weight for display. DB always stores in kg.
  static double displayWeight(double kgValue, bool isMetric) {
    return isMetric ? kgValue : kgToLbs(kgValue);
  }

  /// Convert weight from display unit to kg for storage.
  static double toKgForStorage(double displayValue, bool isMetric) {
    return isMetric ? displayValue : lbsToKg(displayValue);
  }

  /// Convert length for display. DB always stores in cm.
  static double displayLength(double cmValue, bool isMetric) {
    return isMetric ? cmValue : cmToInches(cmValue);
  }

  /// Convert length from display unit to cm for storage.
  static double toCmForStorage(double displayValue, bool isMetric) {
    return isMetric ? displayValue : inchesToCm(displayValue);
  }
}

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'en';
  String _measurementSystem = 'metric'; // 'metric' or 'imperial'
  String _colorPaletteId = 'default';
  String _backgroundMode = 'default'; // 'default', 'pure_black'

  double? _height; // always stored in cm
  double? _weight; // always stored in kg
  String? _lastWeightUpdate;

  // Body measurements (always stored in cm)
  double? _armCircumference;
  double? _waistCircumference;
  double? _shoulderWidth;
  double? _chestCircumference;
  double? _hipCircumference;
  double? _thighCircumference;
  double? _calfCircumference;
  double? _neckCircumference;
  double? _forearmCircumference;

  // Schedule Settings
  bool _showOnDashboard = true;
  bool _displayAllData = true;
  bool _autoPositioning = false;
  List<int> _workoutDays = [1, 2, 3, 4, 5, 6, 7];

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get measurementSystem => _measurementSystem;
  bool get isMetric => _measurementSystem == 'metric';
  String get colorPaletteId => _colorPaletteId;
  AppColorPalette get colorPalette => AppColorPalette.getById(_colorPaletteId);
  String get backgroundMode => _backgroundMode;
  bool get isPureBlack => _backgroundMode == 'pure_black';

  /// Weight unit string for display.
  String get unit => isMetric ? 'kg' : 'lbs';
  /// Length unit string for display.
  String get lengthUnit => isMetric ? 'cm' : 'in';
  /// Backward compat.
  bool get isKg => isMetric;

  double? get height => _height;
  double? get weight => _weight;
  String? get lastWeightUpdate => _lastWeightUpdate;

  // Body measurements getters (raw cm values)
  double? get armCircumference => _armCircumference;
  double? get waistCircumference => _waistCircumference;
  double? get shoulderWidth => _shoulderWidth;
  double? get chestCircumference => _chestCircumference;
  double? get hipCircumference => _hipCircumference;
  double? get thighCircumference => _thighCircumference;
  double? get calfCircumference => _calfCircumference;
  double? get neckCircumference => _neckCircumference;
  double? get forearmCircumference => _forearmCircumference;

  bool get showOnDashboard => _showOnDashboard;
  bool get displayAllData => _displayAllData;
  bool get autoPositioning => _autoPositioning;
  List<int> get workoutDays => _workoutDays;

  // ── Display helpers (automatically convert based on system) ──

  /// Display weight value (converts from kg if imperial).
  double displayWeight(double kgValue) =>
      UnitConverter.displayWeight(kgValue, isMetric);

  /// Display length value (converts from cm if imperial).
  double displayLength(double cmValue) =>
      UnitConverter.displayLength(cmValue, isMetric);

  /// Convert display weight to kg for storage.
  double toKgForStorage(double displayValue) =>
      UnitConverter.toKgForStorage(displayValue, isMetric);

  /// Convert display length to cm for storage.
  double toCmForStorage(double displayValue) =>
      UnitConverter.toCmForStorage(displayValue, isMetric);

  /// Format a weight for display with unit suffix.
  String formatWeight(double kgValue, {int decimals = 1}) {
    final v = displayWeight(kgValue);
    return '${v.toStringAsFixed(decimals)} $unit';
  }

  /// Format a height for display with unit suffix.
  String formatHeight(double cmValue, {int decimals = 1}) {
    if (!isMetric) {
      return UnitConverter.cmToFeetInchesStr(cmValue);
    }
    return '${cmValue.toStringAsFixed(decimals)} cm';
  }

  /// Format a body measurement for display with unit suffix.
  String formatMeasurement(double cmValue, {int decimals = 1}) {
    final v = displayLength(cmValue);
    return '${v.toStringAsFixed(decimals)} $lengthUnit';
  }

  Future<void> loadSettings() async {
    try {
      final settings = await DatabaseHelper().getUserSettings();
      if (settings.isNotEmpty) {
        final t = settings['theme'] as String?;
        if (t == 'light') {
          _themeMode = ThemeMode.light;
        } else if (t == 'dark') {
          _themeMode = ThemeMode.dark;
        } else {
          _themeMode = ThemeMode.system;
        }

        _language = settings['language'] as String? ?? 'en';

        // Support legacy 'unit' field migration
        final unitField = settings['unit'] as String? ?? 'kg';
        final msField = settings['measurement_system'] as String?;
        if (msField != null) {
          _measurementSystem = msField;
        } else {
          _measurementSystem = (unitField == 'lbs') ? 'imperial' : 'metric';
        }

        _height = (settings['height'] as num?)?.toDouble();
        _weight = (settings['weight'] as num?)?.toDouble();
        _lastWeightUpdate = settings['last_weight_update'] as String?;

        // Body measurements
        _armCircumference = (settings['arm_circumference'] as num?)?.toDouble();
        _waistCircumference = (settings['waist_circumference'] as num?)?.toDouble();
        _shoulderWidth = (settings['shoulder_width'] as num?)?.toDouble();
        _chestCircumference = (settings['chest_circumference'] as num?)?.toDouble();
        _hipCircumference = (settings['hip_circumference'] as num?)?.toDouble();
        _thighCircumference = (settings['thigh_circumference'] as num?)?.toDouble();
        _calfCircumference = (settings['calf_circumference'] as num?)?.toDouble();
        _neckCircumference = (settings['neck_circumference'] as num?)?.toDouble();
        _forearmCircumference = (settings['forearm_circumference'] as num?)?.toDouble();

        _showOnDashboard = (settings['show_on_dashboard'] as int?) != 0;
        _displayAllData = (settings['display_all_data'] as int?) != 0;
        _autoPositioning = (settings['auto_positioning'] as int?) == 1;

        final wdStr = settings['workout_days'] as String? ?? '1,2,3,4,5,6,7';
        _workoutDays = wdStr.split(',').map((e) => int.tryParse(e) ?? 1).toList();

        _colorPaletteId = settings['color_palette'] as String? ?? 'default';
        _backgroundMode = settings['background_mode'] as String? ?? 'default';

        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading settings: $e");
    }
  }

  Future<void> updateTheme(String theme) async {
    if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
    await _saveToDb({'theme': theme});
  }

  Future<void> updateLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    await _saveToDb({'language': lang});
  }

  Future<void> updateMeasurementSystem(String system) async {
    _measurementSystem = system;
    final legacyUnit = system == 'imperial' ? 'lbs' : 'kg';
    notifyListeners();
    await _saveToDb({
      'measurement_system': system,
      'unit': legacyUnit,
    });
  }

  /// Legacy method — kept for backward compat.
  Future<void> updateUnit(String newUnit) async {
    final system = newUnit == 'lbs' ? 'imperial' : 'metric';
    await updateMeasurementSystem(system);
  }

  Future<void> updateColorPalette(String paletteId) async {
    _colorPaletteId = paletteId;
    notifyListeners();
    await _saveToDb({'color_palette': paletteId});
  }

  Future<void> updateBackgroundMode(String mode) async {
    _backgroundMode = mode;
    notifyListeners();
    await _saveToDb({'background_mode': mode});
  }

  Future<void> updateProfile(double heightCm, double weightKg) async {
    _height = heightCm;
    _weight = weightKg;
    _lastWeightUpdate = DateTime.now().toIso8601String();
    notifyListeners();
    await _saveToDb({
      'height': heightCm,
      'weight': weightKg,
      'last_weight_update': _lastWeightUpdate,
    });
  }

  Future<void> updateWeightOnly(double weightKg) async {
    _weight = weightKg;
    _lastWeightUpdate = DateTime.now().toIso8601String();
    notifyListeners();
    await _saveToDb({
      'weight': weightKg,
      'last_weight_update': _lastWeightUpdate,
    });
  }

  Future<void> updateBodyMeasurements({
    double? armCircumference,
    double? waistCircumference,
    double? shoulderWidth,
    double? chestCircumference,
    double? hipCircumference,
    double? thighCircumference,
    double? calfCircumference,
    double? neckCircumference,
    double? forearmCircumference,
  }) async {
    _armCircumference = armCircumference ?? _armCircumference;
    _waistCircumference = waistCircumference ?? _waistCircumference;
    _shoulderWidth = shoulderWidth ?? _shoulderWidth;
    _chestCircumference = chestCircumference ?? _chestCircumference;
    _hipCircumference = hipCircumference ?? _hipCircumference;
    _thighCircumference = thighCircumference ?? _thighCircumference;
    _calfCircumference = calfCircumference ?? _calfCircumference;
    _neckCircumference = neckCircumference ?? _neckCircumference;
    _forearmCircumference = forearmCircumference ?? _forearmCircumference;
    notifyListeners();
    await _saveToDb({
      'arm_circumference': _armCircumference,
      'waist_circumference': _waistCircumference,
      'shoulder_width': _shoulderWidth,
      'chest_circumference': _chestCircumference,
      'hip_circumference': _hipCircumference,
      'thigh_circumference': _thighCircumference,
      'calf_circumference': _calfCircumference,
      'neck_circumference': _neckCircumference,
      'forearm_circumference': _forearmCircumference,
    });
    // Also log measurement history
    await DatabaseHelper().insertBodyMeasurement({
      'date': DateTime.now().toIso8601String(),
      'weight': _weight,
      'height': _height,
      'arm_circumference': _armCircumference,
      'waist_circumference': _waistCircumference,
      'shoulder_width': _shoulderWidth,
      'chest_circumference': _chestCircumference,
      'hip_circumference': _hipCircumference,
      'thigh_circumference': _thighCircumference,
      'calf_circumference': _calfCircumference,
      'neck_circumference': _neckCircumference,
      'forearm_circumference': _forearmCircumference,
    });
  }

  /// Check if any body measurements have been recorded.
  bool get hasBodyMeasurements =>
      (_armCircumference ?? 0) > 0 ||
      (_waistCircumference ?? 0) > 0 ||
      (_shoulderWidth ?? 0) > 0 ||
      (_chestCircumference ?? 0) > 0 ||
      (_hipCircumference ?? 0) > 0 ||
      (_thighCircumference ?? 0) > 0 ||
      (_calfCircumference ?? 0) > 0 ||
      (_neckCircumference ?? 0) > 0 ||
      (_forearmCircumference ?? 0) > 0;

  /// Get all current measurements as a map for display.
  Map<String, double?> get allMeasurements => {
    'arm_circumference': _armCircumference,
    'waist_circumference': _waistCircumference,
    'shoulder_width': _shoulderWidth,
    'chest_circumference': _chestCircumference,
    'hip_circumference': _hipCircumference,
    'thigh_circumference': _thighCircumference,
    'calf_circumference': _calfCircumference,
    'neck_circumference': _neckCircumference,
    'forearm_circumference': _forearmCircumference,
  };

  Future<void> _saveToDb(Map<String, dynamic> data) async {
    await DatabaseHelper().updateUserSettings(data);
  }

  Future<void> updateScheduleSettings({
    required bool showOnDashboard,
    required bool displayAllData,
    required bool autoPositioning,
    required List<int> workoutDays,
  }) async {
    _showOnDashboard = showOnDashboard;
    _displayAllData = displayAllData;
    _autoPositioning = autoPositioning;
    _workoutDays = workoutDays;
    notifyListeners();

    await _saveToDb({
      'show_on_dashboard': showOnDashboard ? 1 : 0,
      'display_all_data': displayAllData ? 1 : 0,
      'auto_positioning': autoPositioning ? 1 : 0,
      'workout_days': workoutDays.join(','),
    });
  }
}
