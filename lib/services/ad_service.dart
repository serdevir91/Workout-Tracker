import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum AdPlacement { home, workouts, stats }

class AdService {
  AdService._();

  static final AdService instance = AdService._();

  static const String _defaultAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _defaultAndroidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _homeBannerId = String.fromEnvironment(
    'ADMOB_BANNER_HOME_ID',
    defaultValue: _defaultAndroidBannerId,
  );
  static const String _workoutsBannerId = String.fromEnvironment(
    'ADMOB_BANNER_WORKOUTS_ID',
    defaultValue: _defaultAndroidBannerId,
  );
  static const String _statsBannerId = String.fromEnvironment(
    'ADMOB_BANNER_STATS_ID',
    defaultValue: _defaultAndroidBannerId,
  );
  static const String _interstitialWorkoutFinishId = String.fromEnvironment(
    'ADMOB_INTERSTITIAL_WORKOUT_FINISH_ID',
    defaultValue: _defaultAndroidInterstitialId,
  );

  bool _initialized = false;
  InterstitialAd? _workoutFinishInterstitial;

  bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> initialize() async {
    if (!isSupportedPlatform || _initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  String bannerUnitIdFor(AdPlacement placement) {
    switch (placement) {
      case AdPlacement.home:
        return _homeBannerId;
      case AdPlacement.workouts:
        return _workoutsBannerId;
      case AdPlacement.stats:
        return _statsBannerId;
    }
  }

  Future<BannerAd> createBanner(AdPlacement placement) async {
    await initialize();
    final ad = BannerAd(
      adUnitId: bannerUnitIdFor(placement),
      request: const AdRequest(),
      size: AdSize.banner,
      listener: const BannerAdListener(),
    );
    await ad.load();
    return ad;
  }

  Future<void> preloadWorkoutFinishInterstitial() async {
    await initialize();
    if (_workoutFinishInterstitial != null) return;

    final completer = Completer<void>();
    await InterstitialAd.load(
      adUnitId: _interstitialWorkoutFinishId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _workoutFinishInterstitial = ad;
          completer.complete();
        },
        onAdFailedToLoad: (_) {
          completer.complete();
        },
      ),
    );
    await completer.future;
  }

  Future<void> showWorkoutFinishInterstitial() async {
    await initialize();
    await preloadWorkoutFinishInterstitial();

    final ad = _workoutFinishInterstitial;
    if (ad == null) return;

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _workoutFinishInterstitial = null;
        preloadWorkoutFinishInterstitial();
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _workoutFinishInterstitial = null;
        preloadWorkoutFinishInterstitial();
        completer.complete();
      },
    );
    ad.show();
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }
}
