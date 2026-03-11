import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/formatters.dart';

/// Service for managing workout notifications in the system tray.
/// Shows a persistent notification during active workouts with:
/// - Workout name and elapsed time
/// - Current exercise and set info
/// - Rest timer countdown with completion alert
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _workoutNotificationId = 1;
  static const int _restTimerNotificationId = 2;
  static const int _restFinishedNotificationId = 3;

  static const String _channelId = 'workout_active';
  static const String _channelName = 'Active Workout';
  static const String _channelDescription =
      'Shows active workout progress in the notification panel';

  static const String _restChannelId = 'rest_timer';
  static const String _restChannelName = 'Rest Timer';
  static const String _restChannelDescription =
      'Rest timer countdown and alerts';

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

  Future<void> init() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: initSettings);
    _isInitialized = true;
  }

  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> showWorkoutNotification({
    required String workoutName,
    required int elapsedSeconds,
    required bool isTimerRunning,
    String? lastSetInfo,
    int exerciseCount = 0,
    int totalSets = 0,
    String? currentExerciseName,
    int? workoutStartedAtEpochMs,
  }) async {
    if (!_isInitialized) await init();

    final title = isTimerRunning
        ? workoutName
        : '$workoutName - ${formatDuration(elapsedSeconds)}';

    final bodyParts = <String>[];
    if (currentExerciseName != null && currentExerciseName.isNotEmpty) {
      bodyParts.add(currentExerciseName);
    }
    if (lastSetInfo != null && lastSetInfo.isNotEmpty) {
      bodyParts.add('Last: $lastSetInfo');
    }
    if (exerciseCount > 0 || totalSets > 0) {
      final statsLine = <String>[];
      if (exerciseCount > 0) statsLine.add('$exerciseCount exercises');
      if (totalSets > 0) statsLine.add('$totalSets sets');
      bodyParts.add(statsLine.join(' | '));
    }

    final body = bodyParts.isNotEmpty
        ? bodyParts.join('\n')
        : 'Workout in progress...';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: isTimerRunning,
        when: isTimerRunning
            ? (workoutStartedAtEpochMs ??
                  DateTime.now().millisecondsSinceEpoch -
                      (elapsedSeconds * 1000))
            : null,
        usesChronometer: isTimerRunning,
        onlyAlertOnce: true,
        color: const Color(0xFF6C63FF),
        colorized: true,
        category: AndroidNotificationCategory.workout,
        visibility: NotificationVisibility.public,
      ),
    );

    await _plugin.show(
      id: _workoutNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showRestTimerNotification({
    required int remainingSeconds,
    required int totalSeconds,
  }) async {
    if (!_isInitialized) await init();

    final progress = ((totalSeconds - remainingSeconds) / totalSeconds * 100)
        .round();
    final body = 'Resting... $progress% complete';

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _restChannelId,
        _restChannelName,
        channelDescription: _restChannelDescription,
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: true,
        when: DateTime.now().millisecondsSinceEpoch + (remainingSeconds * 1000),
        usesChronometer: true,
        chronometerCountDown: true,
        onlyAlertOnce: true,
        color: const Color(0xFF00D4AA),
        colorized: true,
        category: AndroidNotificationCategory.workout,
        visibility: NotificationVisibility.public,
      ),
    );

    await _plugin.show(
      id: _restTimerNotificationId,
      title: 'Rest Time',
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showRestFinishedNotification({
    String title = 'Rest Finished!',
    String body = 'Time for your next set!',
  }) async {
    if (!_isInitialized) await init();

    await _plugin.cancel(id: _restTimerNotificationId);

    const details = NotificationDetails(android: _androidRestFinishedDetails);

    await _plugin.show(
      id: _restFinishedNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancelRestTimerNotification() async {
    await _plugin.cancel(id: _restTimerNotificationId);
  }

  Future<void> cancelWorkoutNotification() async {
    await _plugin.cancel(id: _workoutNotificationId);
    await _plugin.cancel(id: _restTimerNotificationId);
    await _plugin.cancel(id: _restFinishedNotificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
