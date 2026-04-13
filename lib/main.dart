import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'services/notification_service.dart';

/// Global navigator key for notification-driven navigation (alarm screen, etc.)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Load environment variables (safe — .env NOT bundled in release APK)
  // In release builds, pass GEMINI_API_KEY via --dart-define
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not available (release build) — keys should come from --dart-define
    debugPrint('No .env file found — using dart-define keys');
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase App Check (graceful — works even if API not enabled yet)
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  } catch (e) {
    debugPrint('App Check activation failed (enable the API in Google Cloud Console): $e');
  }

  // Initialize Local Notifications with navigator key for alarm screen routing
  final notifService = NotificationService();
  notifService.setNavigatorKey(navigatorKey);
  await notifService.init();

  // Note: FCM push notifications require Cloud Functions billing.
  // We use Firestore listener-based notifications instead (free).

  // ─── Security: Suppress error details in release mode ──────
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      // In release: log only the exception type, never the stack trace
      FlutterError.presentError(details);
    } else {
      // In debug: full error details for development
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };

  runApp(const VidyaSetuApp());
}
