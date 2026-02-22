import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/alert_monitor_service.dart';
import 'services/gemini_service.dart';

/// Main entry point for the Safe Vision application
/// Initializes Firebase, Gemini AI, notifications, and alert monitoring
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI appearance
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0E27),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock app to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Gemini AI service
  await GeminiService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize and start alert monitoring service
  await AlertMonitorService.initialize();
  await AlertMonitorService.startMonitoring();

  runApp(const SafeVisionApp());
}

/// Root widget of the Safe Vision application
/// Configures app theme, navigation, and Material Design settings
class SafeVisionApp extends StatelessWidget {
  const SafeVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Vision - Team Zesitx',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // Color scheme with teal accent
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4ECDC4),
          brightness: Brightness.dark,
        ),

        // Text theme using Inter font family
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),

        // Dark background color
        scaffoldBackgroundColor: const Color(0xFF0A0E27),

        // Elevated button styling
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        // Input field styling
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4ECDC4), width: 2),
          ),
        ),
      ),

      // Start with splash screen
      home: const SplashScreen(),
    );
  }
}
