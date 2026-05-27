import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

enum PermissionRequestState { granted, denied, permanentlyDenied, notRequired }

class InitialPermissionResult {
  const InitialPermissionResult({
    required this.notification,
    required this.storage,
  });

  final PermissionRequestState notification;
  final PermissionRequestState storage;
}

class AppPermissionService {
  const AppPermissionService();

  Future<PermissionRequestState> requestNotificationPermission() async {
    if (!Platform.isAndroid) {
      return PermissionRequestState.notRequired;
    }

    final status = await Permission.notification.request();
    return _mapStatus(status);
  }

  Future<PermissionRequestState> requestStoragePermission() async {
    return PermissionRequestState.notRequired;
  }

  Future<InitialPermissionResult> requestInitialPermissions() async {
    final notification = await requestNotificationPermission();
    final storage = await requestStoragePermission();
    return InitialPermissionResult(
      notification: notification,
      storage: storage,
    );
  }

  PermissionRequestState _mapStatus(PermissionStatus status) {
    if (status.isGranted || status.isLimited || status.isProvisional) {
      return PermissionRequestState.granted;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return PermissionRequestState.permanentlyDenied;
    }
    return PermissionRequestState.denied;
  }
}
