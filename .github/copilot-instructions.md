# Copilot Instructions for Workout Tracker

A cross-platform fitness tracking application built with Flutter and Dart, featuring a modern dark-themed UI with glassmorphism effects.

## Project Overview

**Language:** Dart (Flutter)  
**Platforms:** Android, Windows Desktop  
**Key Dependencies:** 
- `sqflite` (SQLite local database)
- `provider` (state management)
- `table_calendar` (calendar widget)

## Architecture

### Directory Structure
- `lib/` - Main application code (Dart)
- `android/` - Android-specific configuration
- `windows/` - Windows desktop build configuration
- `assets/` - Images, GIFs, and static resources
- `test/` - Unit and widget tests

### Key Modules
- **Exercise Library:** GIF-based exercise demonstrations categorized by muscle groups
- **Workout Sessions:** Real-time logging of sets, reps, and weights
- **Weekly Analytics:** Animated bar charts showing volume, reps, and sets data
- **UI Theme:** Dark theme with purple and mint green accents (glassmorphism design)

## Build & Run Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run on Android emulator/device
flutter run -d android

# Run on Windows
flutter run -d windows

# Watch mode
flutter run --verbose
```

### Build
```bash
# Android APK
flutter build apk --release

# Windows executable
flutter build windows --release

# Analyze code
flutter analyze
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/my_test.dart

# Generate coverage
flutter test --coverage
```

## Code Style & Patterns

### Naming Conventions
- `PascalCase` for classes and widgets
- `camelCase` for variables, functions, methods
- Use descriptive names (e.g., `WorkoutSession` not `WS`)

### Flutter Best Practices
- Use `const` constructors where possible (performance optimization)
- Avoid rebuilding entire widget trees; use `Provider` for state management
- Extract reusable widgets into separate files
- Use `StatelessWidget` by default; only use `StatefulWidget` when needed

### Database (SQLite via sqflite)
- Models: Define Dart classes with `toMap()` and `fromMap()` methods
- Queries: Keep all db operations in a dedicated `database_helper.dart`
- Migrations: Handle schema changes in version-aware migrations

### State Management (Provider)
- Watch `ChangeNotifier` providers for reactive updates
- Use `Consumer` or `context.watch()` to rebuild widgets
- Keep business logic separate from UI in provider classes

## Key Files to Understand

- [pubspec.yaml](pubspec.yaml) - Dependencies and project metadata
- [lib/main.dart](lib/main.dart) - App entry point and root widget
- [analysis_options.yaml](analysis_options.yaml) - Linter rules and analysis configuration

## Git Workflow

- **Branch naming:** `feature/feature-name`, `bugfix/bug-name`, `hotfix/issue-name`
- **Commit messages:** Be descriptive; include feature/bug reference
- **PRs:** Run `flutter analyze` and `flutter test` before pushing

## Common Tasks

### Adding a New Exercise
1. Create exercise GIF in `assets/exercises/`
2. Add entry to exercise database model
3. Update exercise library category in UI

### Creating a New Widget
1. Create `lib/screens/` or `lib/widgets/` folder if needed
2. Use `const` constructor and `flutter_test` patterns
3. Inject dependencies via constructor parameters

### Fixing UI/Styling Issues
- Check `lib/theme/` or search for `ThemeData` definitions
- Glassmorphism uses `BackdropFilter` with `ColorFilter`
- Colors like purple (#6D28D9) and mint green (#10B981) are theme accents

## Performance Tips

- Use `const` widgets to prevent unnecessary rebuilds
- Lazy-load exercise GIFs using `Image.asset()` with caching
- Limit `Consumer` scope to smallest widget using the data
- Profile with DevTools: `flutter pub global activate devtools && flutter pub global run devtools`

## Debugging

```bash
# Verbose logging
flutter run -v

# Debug specific dart file
flutter run --dart-define=DEBUG=true

# Use DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

## Release Process

1. Bump version in `pubspec.yaml`
2. Run `flutter clean && flutter pub get`
3. Build APK: `flutter build apk --release`
4. Build Windows: `flutter build windows --release`
5. Tag release: `git tag v1.0.0 && git push origin --tags`
6. Upload builds to GitHub Releases

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [sqflite Package](https://pub.dev/packages/sqflite)
- [Provider Package](https://pub.dev/packages/provider)
- [Table Calendar](https://pub.dev/packages/table_calendar)
