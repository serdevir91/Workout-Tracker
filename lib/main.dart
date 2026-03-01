import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/database_helper.dart';
import 'providers/workout_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initDatabaseFactory();
  await NotificationService().init();
  runApp(const WorkoutTrackerApp());
}

class WorkoutTrackerApp extends StatelessWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WorkoutProvider()..loadWorkouts()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final palette = settings.colorPalette;
          final bool pureBlack = settings.isPureBlack;
          return MaterialApp(
            title: 'Workout Tracker',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            
            // --- Light Theme ---
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
              primaryColor: palette.primary,
              dividerColor: const Color(0xFFE5E5EA),
              hintColor: const Color(0xFF8E8E93),
              colorScheme: ColorScheme.light(
                primary: palette.primary,
                secondary: palette.secondary,
                surface: Colors.white,
                onSurface: const Color(0xFF1C1C1E),
                onSurfaceVariant: const Color(0xFF8E8E93),
                surfaceContainerHighest: const Color(0xFFF0F0F5),
                surfaceContainerHigh: const Color(0xFFE8E8F0),
                surfaceContainer: const Color(0xFFEAEAEF),
                outline: const Color(0xFFE5E5EA),
                outlineVariant: const Color(0xFFD1D1D6),
                error: palette.error,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
                iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
                titleTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C1C1E),
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFFF0F0F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E5EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.primary, width: 2),
                ),
                hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            
            // --- Dark Theme ---
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: pureBlack ? Colors.black : const Color(0xFF0F0F23),
              primaryColor: palette.primary,
              dividerColor: pureBlack ? const Color(0xFF222222) : const Color(0xFF2D2D5E),
              hintColor: const Color(0xFF6B6B8D),
              colorScheme: ColorScheme.dark(
                primary: palette.primary,
                secondary: palette.secondary,
                surface: pureBlack ? const Color(0xFF111111) : const Color(0xFF1A1A2E),
                onSurface: Colors.white,
                onSurfaceVariant: const Color(0xFF6B6B8D),
                surfaceContainerHighest: pureBlack ? const Color(0xFF1A1A1A) : const Color(0xFF252547),
                surfaceContainerHigh: pureBlack ? const Color(0xFF0A0A0A) : const Color(0xFF1E1E3E),
                surfaceContainer: pureBlack ? const Color(0xFF151515) : const Color(0xFF222244),
                outline: pureBlack ? const Color(0xFF222222) : const Color(0xFF2D2D5E),
                outlineVariant: pureBlack ? const Color(0xFF333333) : const Color(0xFF444466),
                error: palette.error,
              ),
              appBarTheme: AppBarTheme(
                backgroundColor: pureBlack ? Colors.black : const Color(0xFF1A1A2E),
                elevation: 0,
                centerTitle: true,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              cardTheme: CardThemeData(
                color: pureBlack ? const Color(0xFF111111) : const Color(0xFF1A1A2E),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: pureBlack ? const Color(0xFF222222) : const Color(0xFF2D2D5E)),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: pureBlack ? const Color(0xFF1A1A1A) : const Color(0xFF252547),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pureBlack ? const Color(0xFF222222) : const Color(0xFF2D2D5E)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: pureBlack ? const Color(0xFF222222) : const Color(0xFF2D2D5E)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: palette.primary, width: 2),
                ),
                hintStyle: const TextStyle(color: Color(0xFF6B6B8D)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
