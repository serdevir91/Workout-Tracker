import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/formatters.dart';

/// Service for managing workout notifications in the system tray.
/// Shows a persistent notification during active workouts with:
/// - Workout name & elapsed time (live counter)
/// - Current exercise & set info
/// - Rest timer countdown with completion alert
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _workoutNotificationId = 1;
  static const int _restTimerNotificationId = 2;
  static const int _restFinishedNotificationId = 3;

  static const String _channelId = 'workout_active';
  static const String _channelName = 'Active Workout';
  static const String _channelDescription = 'Shows active workout progress in the notification panel';

  static const String _restChannelId = 'rest_timer';
  static const String _restChannelName = 'Rest Timer';
  static const String _restChannelDescription = 'Rest timer countdown and alerts';

  static const _androidWorkoutDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDescription,
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    showWhen: false,
    onlyAlertOnce: true,
    color: Color(0xFF6C63FF),
    colorized: true,
    category: AndroidNotificationCategory.workout,
    visibility: NotificationVisibility.public,
  );

  static const _androidRestDetails = AndroidNotificationDetails(
    _restChannelId,
    _restChannelName,
    channelDescription: _restChannelDescription,
    importance: Importance.low,
    priority: Priority.low,
    ongoing: true,
    autoCancel: false,
    showWhen: false,
    onlyAlertOnce: true,
    color: Color(0xFF00D4AA),
    colorized: true,
    category: AndroidNotificationCategory.workout,
    visibility: NotificationVisibility.public,
  );

  static const _androidRestFinishedDetails = AndroidNotificationDetails(
    _restChannelId,
    _restChannelName,
    channelDescription: _restChannelDescription,
    importance: Importance.high,
    priority: Priority.high,
    ongoing: false,
    autoCancel: true,
    showWhen: true,
    onlyAlertOnce: false,
    color: Color(0xFF00D4AA),
    colorized: true,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    enableVibration: true,
    playSound: true,
  );

  /// Initialize the notification plugin. Call once at app startup.
  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);
    _isInitialized = true;
  }

  /// Request notification permission (Android 13+ / API 33+).
  /// Returns true if granted.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Show or update the persistent workout notification.
  /// Call this every second to update the timer display.
  /// Enhanced to show exercise count, sets done, and rest status.
  Future<void> showWorkoutNotification({
    required String workoutName,
    required int elapsedSeconds,
    String? lastSetInfo,
    int exerciseCount = 0,
    int totalSets = 0,
    int restTimerSeconds = 0,
    String? currentExerciseName,
  }) async {
    if (!_isInitialized) await init();

    final timeStr = formatDuration(elapsedSeconds);

    final title = '$workoutName — $timeStr';

    // Build rich body with multiple info lines
    final bodyParts = <String>[];
    
    // Don't include rest timer info here — it has its own separate notification
    
    if (currentExerciseName != null && currentExerciseName.isNotEmpty) {
      bodyParts.add('🏋️ $currentExerciseName');
    }
    
    if (lastSetInfo != null && lastSetInfo.isNotEmpty) {
      bodyParts.add('Last: $lastSetInfo');
    }
    
    if (exerciseCount > 0 || totalSets > 0) {
      final statsLine = <String>[];
      if (exerciseCount > 0) statsLine.add('$exerciseCount exercises');
      if (totalSets > 0) statsLine.add('$totalSets sets');
      bodyParts.add(statsLine.join(' · '));
    }

    final body = bodyParts.isNotEmpty 
        ? bodyParts.join('\n') 
        : 'Workout in progress...';

    const details = NotificationDetails(android: _androidWorkoutDetails);

    await _plugin.show(
      id: _workoutNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Show rest timer notification with countdown.
  Future<void> showRestTimerNotification({
    required int remainingSeconds,
    required int totalSeconds,
  }) async {
    if (!_isInitialized) await init();

    final timeStr = formatDuration(remainingSeconds);

    final title = 'Rest Time — $timeStr';
    final progress = ((totalSeconds - remainingSeconds) / totalSeconds * 100).round();
    final body = 'Resting... $progress% complete';

    const details = NotificationDetails(android: _androidRestDetails);

    await _plugin.show(
      id: _restTimerNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Show rest finished alert with vibration and sound.
  Future<void> showRestFinishedNotification({
    String title = 'Rest Finished!',
    String body = 'Time for your next set!',
  }) async {
    if (!_isInitialized) await init();

    // Cancel the countdown notification
    await _plugin.cancel(id: _restTimerNotificationId);

    const details = NotificationDetails(android: _androidRestFinishedDetails);

    await _plugin.show(
      id: _restFinishedNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Cancel rest timer notification.
  Future<void> cancelRestTimerNotification() async {
    await _plugin.cancel(id: _restTimerNotificationId);
  }

  /// Remove the workout notification (when workout is finished/cancelled).
  Future<void> cancelWorkoutNotification() async {
    await _plugin.cancel(id: _workoutNotificationId);
    await _plugin.cancel(id: _restTimerNotificationId);
    await _plugin.cancel(id: _restFinishedNotificationId);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
