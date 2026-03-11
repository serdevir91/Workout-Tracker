<div align="center">
  <img src="assets/images/app_icon.png" alt="Workout Tracker Logo" width="120"/>
  <h1>Modern Workout Tracker</h1>
  <p>A sleek fitness tracking application built with Flutter â€” supports Light, Dark &amp; Pure Black (AMOLED) themes.</p>
  <p>
    <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.41-blue?logo=flutter" />
    <img alt="Dart" src="https://img.shields.io/badge/Dart-3.11-blue?logo=dart" />
    <img alt="Platform" src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows-green" />
    <img alt="License" src="https://img.shields.io/badge/License-MIT-yellow" />
  </p>
</div>

## Features

- **Light / Dark / Pure Black Themes:** Full theme support with 6 color palettes (Default, Ocean, Sunset, Forest, Rose, Crimson) and AMOLED-friendly pure black mode.
- **Exercise Library:** 873 exercises categorized by muscle groups with auto-cycling image demonstrations (public domain, [free-exercise-db](https://github.com/yuhonas/free-exercise-db)).
- **Smart Tracking:** Log sets, reps, and weights during active workout sessions with swipeable exercise navigation and built-in rest timer.
- **Cardio Support:** Dedicated cardio timer for exercises like Cycle Ergometer, Treadmill, etc.
- **Workout Plans & Routines:** Create custom routines, assign them to specific days, and follow structured training programs.
- **Workout Schedule:** Calendar-based weekly schedule with configurable workout days and auto-positioning.
- **Workout Summary:** Post-workout summary screen showing calories burned, total time, and total volume.
- **Body Progress Charts:** Track body measurements (weight, arm, waist, chest, etc.) with line charts over time.
- **Muscle Group Distribution:** Donut chart showing muscle group workout distribution with period filters.
- **Weekly Insights:** Beautifully animated vertical bar charts showing weekly Volume, Reps, and Sets data.
- **Calories Chart:** Track calories burned over time with line chart visualization.
- **Stats Dashboard:** Overview cards for total workouts, volume, duration, and sets with session-level breakdown.
- **Settings & Profile:** Configure theme, color palette, background mode, language, weight unit (kg/lbs), height, and body measurements.
- **Multi-Language Support:** English, Turkish (TÃ¼rkÃ§e), and Spanish (EspaÃ±ol) localization built-in.
- **First Day of Week Setting:** Choose Monday, Saturday, or Sunday as your week start â€” workout plans sort accordingly.
- **Add Exercise from Library:** Long-press or tap "Add to Workout" from any exercise detail to add it to a workout plan.
- **Redesigned Exercise Detail Screen:** Hero images with SliverAppBar, auto-cycling GIF-like animation, card-based metrics, modern history cards.
- **Backup & Restore:** Export/import your workout data for safe keeping.
- **Cross-Platform:** Runs seamlessly on Android and Windows Desktop.

## Screenshots

<p align="center">
  <img src="assets/screenshots/1.jpeg" width="30%" />
  <img src="assets/screenshots/2_v2.jpeg" width="30%" />
  <img src="assets/screenshots/3.jpeg" width="30%" />
</p>
<p align="center">
  <img src="assets/screenshots/4.jpeg" width="30%" />
  <img src="assets/screenshots/5.jpeg" width="30%" />
  <img src="assets/screenshots/6.jpeg" width="30%" />
</p>
<p align="center">
  <img src="assets/screenshots/7.jpeg" width="30%" />
  <img src="assets/screenshots/8.jpeg" width="30%" />
  <img src="assets/screenshots/9.jpeg" width="30%" />
</p>

## Download & Install

You can easily install and test the app on your Android device!

1. Go to the **[Releases](https://github.com/serdevir91/Workout-Tracker/releases)** section of this repository.
2. Download the latest `app-release.apk` file.
3. Transfer the file to your Android phone.
4. Open the file manager, tap on the APK, and select **Install** (You may need to allow "Install from unknown sources" in your settings).

### Windows

Download and run the Windows build from the [Releases](https://github.com/serdevir91/Workout-Tracker/releases) page, or build it yourself with:

```bash
flutter build windows
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | [Flutter](https://flutter.dev/) 3.41 (Dart 3.11) |
| **Local Database** | sqflite (SQLite) |
| **State Management** | Provider |
| **UI Components** | TableCalendar, Custom IndexedStack Navigation |
| **Localization** | Custom translation system (EN / TR / ES) |

## Project Structure

```
lib/
|-- main.dart                  # App entry point
|-- db/                        # Database helper (SQLite)
|-- l10n/                      # Translations (EN, TR)
|-- models/                    # Data models (Workout, Plan, etc.)
|-- providers/                 # State management (Workout, Settings)
|-- screens/                   # All app screens
|   |-- home_screen.dart
|   |-- active_workout_screen.dart
|   |-- exercise_library_screen.dart
|   |-- exercise_info_screen.dart
|   |-- plans_screen.dart
|   |-- create_routine_screen.dart
|   |-- stats_screen.dart
|   |-- settings_screen.dart
|   |-- workout_detail_screen.dart
|   |-- workout_schedule_screen.dart
|   |-- workout_summary_screen.dart
|   `-- swipeable_exercise_screen.dart
|-- services/                  # Notification service
|-- utils/                     # Utility functions
`-- widgets/                   # Reusable widgets
```

## Run Locally

```bash
# Clone the repository
git clone https://github.com/serdevir91/Workout-Tracker.git

# Navigate to the project folder
cd Workout-Tracker

# Install dependencies
flutter pub get

# Run on Android
flutter run

# Build release APK
flutter build apk --release

# Build for Windows
flutter build windows
```

## What's New (v3.1.5)

- **Cardio Issue Fixed** â€” Cardio exercises now handle timer/session flow more reliably during active workouts.
- **Session Completion Reliability** â€” Workout session finishing logic was improved to reduce incomplete or inconsistent summaries.
- **Stats & Summary Consistency** â€” Stats and workout summary calculations were aligned with the updated workout/session flow.

<details>
<summary>v3.0.1 Changes</summary>

- **Refined Muscle Group Categories** â€” Split broad groups into specific targets: Arms â†’ Biceps + Triceps, Legs â†’ Quadriceps + Hamstrings, Glutes & Hips â†’ Glutes, added Lower Back as separate category, Traps moved to Shoulders
- **Exercise Timer Fix** â€” Timer now correctly tracks the currently viewed exercise instead of always the last one; background time compensation also uses the active exercise
- **All Exercises Properly Finished** â€” Workout completion now finishes all open exercises (not just the last one), fixing duration tracking for multi-exercise workouts
- **Smart Muscle Group Matching** â€” Added 60+ custom exercise name overrides, fuzzy keyword matching with caching, and special bench press detection (close-grip â†’ Triceps, others â†’ Chest)
- **Improved Donut Chart** â€” Muscle group distribution chart is now properly centered with centered legend layout
- **Exercise Library Updates** â€” Category list updated to match new fine-grained muscle groups with distinct colors and icons

</details>

<details>
<summary>v3.0.0 Changes</summary>

- **Free Exercise Database** â€” Replaced ExRx.net with [free-exercise-db](https://github.com/yuhonas/free-exercise-db) (873 exercises, public domain / Unlicense)
- **Auto-Cycling Exercise Images** â€” Exercise detail screen images now auto-cycle between start/end positions like a GIF animation (1.2s interval)
- **Improved Image Quality** â€” High-resolution JPG images for all exercises, served from GitHub CDN
- **Exercise Add Bug Fixed** â€” Adding exercises to workouts from the library now works correctly in all views
- **Removed url_launcher Dependency** â€” Streamlined dependencies, no more external browser launches for exercises
- **Cleaned Up Codebase** â€” Removed 24+ legacy Python scraping scripts and outdated data files

</details>

<details>
<summary>v2.2.1 Changes</summary>

- **Redesigned Exercise Detail Screen** â€” Hero GIF with SliverAppBar, card-based metrics, modern history cards with LIVE badge
- **First Day of Week Setting** â€” Choose Monday, Saturday, or Sunday; workout plans sort accordingly
- **Add Exercise from Library** â€” Tap "Add to Workout" from exercise detail to add it to any workout plan
- **Exercise Counter Repositioned** â€” Swipe indicator (1/8) now sits right below the sets counter badge
- **Workout Plan Sorting** â€” Next training cards respect first day of week setting
- **Alternative Exercise Swap** â€” Quick swap button in exercise detail AppBar

</details>

<details>
<summary>v2.1.0 Changes</summary>

- **Light / Dark / Pure Black themes** with full theme-aware colors across all screens
- **6 Color Palettes:** Default, Ocean, Sunset, Forest, Rose, Crimson
- **Pure Black (AMOLED) mode** for battery saving on OLED screens
- **Spanish language** support added
- **Swipeable exercise navigation** during active workouts
- **Body progress charts** with 10 measurement types
- **Muscle group donut chart** with period filters
- **Calories burned chart** with time-based tracking
- **Cardio exercise support** with dedicated timer
- **Backup & Restore** functionality
- **Improved date formatting** in workout history and detail screens
- Workout Plans & Routines with day assignment
- Workout Schedule with calendar view
- Post-workout Summary screen
- Settings screen (Theme, Color Palette, Background Mode, Language, Units, Profile)
- Exercise thumbnails in workout lists
- Windows desktop support improvements

</details>

<details>
<summary>v2.0.0 Changes</summary>

- **Exercise library overhaul** â€” 526+ exercises with GIF demonstrations
- **Workout Plans & Routines** â€” Create custom routines and assign to specific days
- **Workout Schedule** â€” Calendar-based weekly schedule with configurable workout days
- **Post-workout Summary** â€” Calories burned, total time, and total volume overview
- **Stats Dashboard** â€” Total workouts, volume, duration, and sets with session breakdown
- **Body Progress Charts** â€” Track weight, arm, waist, chest and more with line charts
- **Multi-Language Support** â€” English and Turkish localization
- **Settings & Profile** â€” Theme, language, weight unit (kg/lbs), height, body measurements
- **Notification Service** â€” Rest timer and workout reminder notifications
- **Improved data models** â€” Pydantic-style validation for workout data

</details>

<details>
<summary>v1.0.0 Initial Release</summary>

- Core workout tracking with sets, reps, and weight logging
- Exercise library with 526+ exercises and GIF demonstrations
- Active workout session with rest timer
- Workout history and detail screens
- SQLite local database storage
- Dark theme support
- Android and Windows platform support

</details>

---
