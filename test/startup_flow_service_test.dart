import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_tracker/services/startup_flow_service.dart';

void main() {
  group('StartupFlowService', () {
    test('first prepare increments launch count and shows onboarding', () async {
      SharedPreferences.setMockInitialValues({});
      const service = StartupFlowService();

      final snapshot = await service.prepare();

      expect(snapshot.launchCount, 1);
      expect(snapshot.hasSeenOnboarding, isFalse);
      expect(snapshot.neverShowStartupOffer, isFalse);
      expect(
        service.shouldShowStartupOffer(
          launchCount: snapshot.launchCount,
          isPremiumUnlocked: false,
          neverShowStartupOffer: snapshot.neverShowStartupOffer,
        ),
        isTrue,
      );
    });

    test('launch 8 triggers recurring startup offer', () async {
      SharedPreferences.setMockInitialValues({
        StartupFlowService.onboardingSeenKey: true,
        StartupFlowService.startupOfferLaunchCountKey: 7,
      });
      const service = StartupFlowService();

      final snapshot = await service.prepare();

      expect(snapshot.launchCount, 8);
      expect(
        service.shouldShowStartupOffer(
          launchCount: snapshot.launchCount,
          isPremiumUnlocked: false,
          neverShowStartupOffer: snapshot.neverShowStartupOffer,
        ),
        isTrue,
      );
    });

    test('never-show flag suppresses future startup offer', () async {
      SharedPreferences.setMockInitialValues({
        StartupFlowService.onboardingSeenKey: true,
        StartupFlowService.startupOfferLaunchCountKey: 15,
        StartupFlowService.startupOfferNeverShowKey: true,
      });
      const service = StartupFlowService();

      final snapshot = await service.prepare();

      expect(
        service.shouldShowStartupOffer(
          launchCount: snapshot.launchCount,
          isPremiumUnlocked: false,
          neverShowStartupOffer: snapshot.neverShowStartupOffer,
        ),
        isFalse,
      );
    });

    test('rate-review prompt starts after first completed workout', () async {
      SharedPreferences.setMockInitialValues({
        StartupFlowService.onboardingSeenKey: true,
      });
      const service = StartupFlowService();

      final state = await service.registerWorkoutCompletionAndEvaluate();

      expect(state.completedWorkoutCount, 1);
      expect(state.shouldShowPrompt, isTrue);
    });

    test('rate-review prompt repeats every 10 completed workouts', () async {
      SharedPreferences.setMockInitialValues({
        StartupFlowService.rateReviewCompletedWorkoutCountKey: 7,
        StartupFlowService.rateReviewLastPromptWorkoutCountKey: 1,
      });
      const service = StartupFlowService();

      final first = await service.registerWorkoutCompletionAndEvaluate();
      expect(first.completedWorkoutCount, 8);
      expect(first.shouldShowPrompt, isFalse);

      await service.registerWorkoutCompletionAndEvaluate(); // 9
      await service.registerWorkoutCompletionAndEvaluate(); // 10
      final eleventh = await service.registerWorkoutCompletionAndEvaluate(); // 11

      expect(
        eleventh.shouldShowPrompt,
        isTrue,
      );
    });

    test('rate-review prompt suppressed when user already rated', () async {
      SharedPreferences.setMockInitialValues({
        StartupFlowService.rateReviewCompletedKey: true,
      });
      const service = StartupFlowService();

      final state = await service.registerWorkoutCompletionAndEvaluate();
      expect(
        state.shouldShowPrompt,
        isFalse,
      );
    });

    test('rate-review prompt suppressed when never-show is selected', () async {
      SharedPreferences.setMockInitialValues({
        StartupFlowService.rateReviewNeverShowKey: true,
      });
      const service = StartupFlowService();

      expect(
        (await service.registerWorkoutCompletionAndEvaluate()).shouldShowPrompt,
        isFalse,
      );
    });
  });
}
