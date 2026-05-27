import 'package:package_info_plus/package_info_plus.dart';

enum AppFlavor { free, pro }

class AppFlavorResolver {
  static AppFlavor? _cached;

  static Future<AppFlavor> resolve() async {
    if (_cached != null) return _cached!;

    const fromDefine = String.fromEnvironment('APP_FLAVOR', defaultValue: '');
    if (fromDefine == 'pro') {
      _cached = AppFlavor.pro;
      return _cached!;
    }
    if (fromDefine == 'free') {
      _cached = AppFlavor.free;
      return _cached!;
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName.toLowerCase();
    _cached = packageName.endsWith('.pro') ? AppFlavor.pro : AppFlavor.free;
    return _cached!;
  }
}
