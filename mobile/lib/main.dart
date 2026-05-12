import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_locale_config.dart';

/// Entry point — per skill: project-structure.md.
///
/// Firebase.initializeApp() must be called before any Firebase service.
/// WHY async main: Firebase init requires platform channel communication
/// that must complete before FCM registration can proceed.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppLocaleConfig.initialize();

  // Initialize Firebase (required for FCM push notifications).
  // The google-services.json (Android) / GoogleService-Info.plist (iOS)
  // must be placed in the correct platform directories before this works.
  // Wrapped in try-catch so the app can still run during development
  // with a placeholder config — FCM features will silently degrade.
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('⚠️ Firebase init failed (FCM will be unavailable): $e');
  }

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: SaveBiteApp()));
}
