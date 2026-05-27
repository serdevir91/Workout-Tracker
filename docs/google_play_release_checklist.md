# Google Play Release Checklist

## Flavors and Bundles
- Build free bundle: `flutter build appbundle --release --flavor free --dart-define=APP_FLAVOR=free`
- Build pro bundle: `flutter build appbundle --release --flavor pro --dart-define=APP_FLAVOR=pro`
- Verify package ids:
  - Free: `com.workouttracker.workout_tracker`
  - Pro: `com.workouttracker.workout_tracker.pro`

## Monetization
- Create subscription products in Play Console:
  - `premium_monthly`
  - `premium_yearly`
- Activate the subscriptions before testing.
- Verify restore purchases flow.

## Ads
- Add production AdMob App ID and unit IDs via `--dart-define`.
- Confirm free build shows banners on Home/Workouts/Stats.
- Confirm interstitial shows on workout finish.
- Confirm pro/premium states show no ads.

## Policy and Store
- Update and publish privacy policy URL.
- Complete Data Safety form (ads + billing + local storage disclosures).
- Set content rating and ads declaration.
- Upload store screenshots for free and pro listings.
- Fill short/long descriptions and localization text.

## Final QA
- Free: routine limit = 3, 4th routine opens paywall.
- Premium unlock: no ads, unlimited routines, advanced stats, 1RM section.
- Pro build: premium features open by default and paywall hidden.
- Backup/restore works using SAF file picker on Android 13+.

## Billing Testing
- Add your Gmail under Play Console > Settings > License testing.
- Add the same Gmail to the internal testing track and accept the opt-in link.
- Install the `free` build from Google Play internal testing, not by direct APK.
- Keep subscription product IDs active and matching the app constants:
  - `premium_monthly`
  - `premium_yearly`
- If products do not appear in-app, confirm the tester account downloaded the app from Play Store and clear Play Store cache before retrying.
- Use Google Play test cards or Play Billing Lab for renewal, decline, grace period, account hold, and pending scenarios.
