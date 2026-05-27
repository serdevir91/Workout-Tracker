import 'package:shared_preferences/shared_preferences.dart';

class StartupFlowService {
  static const String onboardingSeenKey = 'has_seen_onboarding_v1';
  static const String startupOfferLaunchCountKey = 'startup_offer_launch_count_v2';
  static const String startupOfferNeverShowKey = 'startup_offer_never_show_v2';
  static const String rateReviewCompletedKey = 'rate_review_completed_v1';
  static const String rateReviewNeverShowKey = 'rate_review_never_show_v1';
  static const String rateReviewCompletedWorkoutCountKey =
      'rate_review_completed_workout_count_v1';
  static const String rateReviewLastPromptWorkoutCountKey =
      'rate_review_last_prompt_workout_count_v1';

  const StartupFlowService();

  Future<StartupFlowSnapshot> prepare() async {
    final prefs = await SharedPreferences.getInstance();
    final launchCount = (prefs.getInt(startupOfferLaunchCountKey) ?? 0) + 1;
    await prefs.setInt(startupOfferLaunchCountKey, launchCount);

    final hasSeenOnboarding = prefs.getBool(onboardingSeenKey) ?? false;
    final neverShowStartupOffer =
        prefs.getBool(startupOfferNeverShowKey) ?? false;

    return StartupFlowSnapshot(
      launchCount: launchCount,
      hasSeenOnboarding: hasSeenOnboarding,
      neverShowStartupOffer: neverShowStartupOffer,
    );
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingSeenKey, true);
  }

  Future<void> setNeverShowStartupOffer(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(startupOfferNeverShowKey, value);
  }

  Future<void> markRateReviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rateReviewCompletedKey, true);
  }

  Future<void> setNeverShowRateReview(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(rateReviewNeverShowKey, value);
  }

  Future<void> setRateReviewPromptLastShownForWorkout(
    int completedWorkoutCount,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      rateReviewLastPromptWorkoutCountKey,
      completedWorkoutCount,
    );
  }

  Future<RateReviewPromptState> registerWorkoutCompletionAndEvaluate() async {
    final prefs = await SharedPreferences.getInstance();
    final completedWorkoutCount =
        (prefs.getInt(rateReviewCompletedWorkoutCountKey) ?? 0) + 1;
    await prefs.setInt(rateReviewCompletedWorkoutCountKey, completedWorkoutCount);

    final hasRatedOrReviewed = prefs.getBool(rateReviewCompletedKey) ?? false;
    final neverShowRateReview = prefs.getBool(rateReviewNeverShowKey) ?? false;
    final lastPromptWorkoutCount =
        prefs.getInt(rateReviewLastPromptWorkoutCountKey) ?? 0;

    final shouldShow = shouldShowRateReviewPromptAfterWorkout(
      completedWorkoutCount: completedWorkoutCount,
      hasRatedOrReviewed: hasRatedOrReviewed,
      neverShowRateReview: neverShowRateReview,
      lastPromptWorkoutCount: lastPromptWorkoutCount,
    );

    if (shouldShow) {
      await setRateReviewPromptLastShownForWorkout(completedWorkoutCount);
    }

    return RateReviewPromptState(
      completedWorkoutCount: completedWorkoutCount,
      hasRatedOrReviewed: hasRatedOrReviewed,
      neverShowRateReview: neverShowRateReview,
      lastPromptWorkoutCount: shouldShow
          ? completedWorkoutCount
          : lastPromptWorkoutCount,
      shouldShowPrompt: shouldShow,
    );
  }

  bool shouldShowStartupOffer({
    required int launchCount,
    required bool isPremiumUnlocked,
    required bool neverShowStartupOffer,
  }) {
    if (isPremiumUnlocked || neverShowStartupOffer) {
      return false;
    }
    return launchCount == 1 || launchCount % 8 == 0;
  }

  bool shouldShowRateReviewPromptAfterWorkout({
    required int completedWorkoutCount,
    required bool hasRatedOrReviewed,
    required bool neverShowRateReview,
    required int lastPromptWorkoutCount,
  }) {
    if (hasRatedOrReviewed || neverShowRateReview) {
      return false;
    }

    if (completedWorkoutCount < 1) {
      return false;
    }

    if (lastPromptWorkoutCount == 0) {
      return true;
    }

    return (completedWorkoutCount - lastPromptWorkoutCount) >= 10;
  }
}

class StartupFlowSnapshot {
  const StartupFlowSnapshot({
    required this.launchCount,
    required this.hasSeenOnboarding,
    required this.neverShowStartupOffer,
  });

  final int launchCount;
  final bool hasSeenOnboarding;
  final bool neverShowStartupOffer;
}

class RateReviewPromptState {
  const RateReviewPromptState({
    required this.completedWorkoutCount,
    required this.hasRatedOrReviewed,
    required this.neverShowRateReview,
    required this.lastPromptWorkoutCount,
    required this.shouldShowPrompt,
  });

  final int completedWorkoutCount;
  final bool hasRatedOrReviewed;
  final bool neverShowRateReview;
  final int lastPromptWorkoutCount;
  final bool shouldShowPrompt;
}
