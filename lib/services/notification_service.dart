import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing workout notifications in the system tray.
/// Shows a persistent notification during active workouts with:
/// - Workout name
/// - Elapsed time (live counter)
/// - Last set info (e.g., "Bench Press 80kg x 10")
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  static const int _workoutNotificationId = 1;
  static const String _channelId = 'workout_active';
  static const String _channelName = 'Active Workout';
  static const String _channelDescription = 'Shows active workout progress in the notification panel';

  static const _androidDetails = AndroidNotificationDetails(
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
  Future<void> showWorkoutNotification({
    required String workoutName,
    required int elapsedSeconds,
    String? lastSetInfo,
  }) async {
    if (!_isInitialized) await init();

    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final title = '$workoutName — $timeStr';
    final body = lastSetInfo ?? 'Workout in progress...';

    const details = NotificationDetails(android: _androidDetails);

    await _plugin.show(
      id: _workoutNotificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Remove the workout notification (when workout is finished/cancelled).
  Future<void> cancelWorkoutNotification() async {
    await _plugin.cancel(id: _workoutNotificationId);
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
