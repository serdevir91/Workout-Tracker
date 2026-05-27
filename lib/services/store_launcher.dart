import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreLauncher {
  static const String proPackageId = 'com.workouttracker.workout_tracker.pro';
  static const String _definedUrl = String.fromEnvironment(
    'PLAY_PRO_VERSION_URL',
    defaultValue: '',
  );

  static Uri get _marketUri => Uri.parse('market://details?id=$proPackageId');
  static Uri get _webUri => Uri.parse(
    _definedUrl.isNotEmpty
        ? _definedUrl
        : 'https://play.google.com/store/apps/details?id=$proPackageId',
  );

  static Future<bool> openProVersionListing() async {
    final openedMarket = await launchUrl(
      _marketUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedMarket) return true;

    return launchUrl(_webUri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openCurrentAppListing() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageId = packageInfo.packageName;
    final marketUri = Uri.parse('market://details?id=$packageId');
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageId',
    );

    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedMarket) {
      return true;
    }

    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> openCurrentAppReviewPage() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageId = packageInfo.packageName;
    final marketUri = Uri.parse(
      'market://details?id=$packageId&showAllReviews=true',
    );
    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageId&showAllReviews=true',
    );

    final openedMarket = await launchUrl(
      marketUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedMarket) {
      return true;
    }

    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
