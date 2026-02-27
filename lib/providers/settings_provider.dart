import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _language = 'en';
  String _unit = 'kg'; // 'kg' or 'lbs'

  double? _height;
  double? _weight;
  String? _lastWeightUpdate;

  // Schedule Settings
  bool _showOnDashboard = true;
  bool _displayAllData = true;
  bool _autoPositioning = false;
  List<int> _workoutDays = [1, 2, 3, 4, 5, 6, 7];

  // Getters
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get unit => _unit;
  bool get isKg => _unit == 'kg';

  double? get height => _height;
  double? get weight => _weight;
  String? get lastWeightUpdate => _lastWeightUpdate;

  bool get showOnDashboard => _showOnDashboard;
  bool get displayAllData => _displayAllData;
  bool get autoPositioning => _autoPositioning;
  List<int> get workoutDays => _workoutDays;

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
        _unit = settings['unit'] as String? ?? 'kg';

        _height = (settings['height'] as num?)?.toDouble();
        _weight = (settings['weight'] as num?)?.toDouble();
        _lastWeightUpdate = settings['last_weight_update'] as String?;

        _showOnDashboard = (settings['show_on_dashboard'] as int?) != 0;
        _displayAllData = (settings['display_all_data'] as int?) != 0;
        _autoPositioning = (settings['auto_positioning'] as int?) == 1;

        final wdStr = settings['workout_days'] as String? ?? '1,2,3,4,5,6,7';
        _workoutDays = wdStr.split(',').map((e) => int.tryParse(e) ?? 1).toList();

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

  Future<void> updateUnit(String newUnit) async {
    _unit = newUnit;
    notifyListeners();
    await _saveToDb({'unit': newUnit});
  }

  Future<void> updateProfile(double heightStr, double weightStr) async {
    _height = heightStr;
    _weight = weightStr;
    _lastWeightUpdate = DateTime.now().toIso8601String();
    notifyListeners();
    await _saveToDb({
      'height': heightStr,
      'weight': weightStr,
      'last_weight_update': _lastWeightUpdate,
    });
  }

  Future<void> updateWeightOnly(double weightStr) async {
    _weight = weightStr;
    _lastWeightUpdate = DateTime.now().toIso8601String();
    notifyListeners();
    await _saveToDb({
      'weight': weightStr,
      'last_weight_update': _lastWeightUpdate,
    });
  }

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
