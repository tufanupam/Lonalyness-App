/// AI Muse — Main Entry Point
/// Initializes Firebase and launches the application.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

import 'core/config/app_config.dart';

Future<void> main() async {
  // Ensure Flutter framework is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait mode (skip on web — not supported)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase with generated config
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseAvailable = true;
    debugPrint("✅ Firebase initialized successfully");
  } catch (e, stack) {
    debugPrint("⚠️ Firebase initialization failed: $e");
    debugPrint("Stack trace: $stack");
    // Continue running in Offline/Demo mode
  }

  debugPrint("🚀 AI Muse starting — Firebase: $isFirebaseAvailable");

  // Run the app with Riverpod scope
  runApp(
    const ProviderScope(
      child: AiMuseApp(),
    ),
  );
}
