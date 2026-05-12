import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/repositories/auth_repository.dart';

/// Top-level background message handler.
///
/// WHY top-level: Firebase requires background handlers to be top-level
/// functions (not instance methods) because they run in an isolate separate
/// from the main app. The @pragma annotation ensures tree-shaker keeps it.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in the background isolate.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured — skip background processing.
    return;
  }
  debugPrint('[FCM] Background message: ${message.messageId}');
  // Notification data is handled via the notification tray.
  // Deep-link navigation happens when the user taps the notification
  // (handled by onMessageOpenedApp in the foreground service).
}

/// Provider for the notification service singleton.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});

/// Central FCM notification service.
///
/// Handles:
/// 1. Firebase initialization
/// 2. Permission request (iOS requires explicit prompt)
/// 3. FCM token retrieval and refresh → sent to backend
/// 4. Foreground message display
/// 5. Notification tap → deep-link navigation
///
/// WHY a dedicated service (not in AuthNotifier):
/// - FCM lifecycle is independent from auth — tokens refresh at any time
/// - Background handlers need top-level isolation
/// - Keeps AuthNotifier focused on auth state only (SRP)
class NotificationService {
  NotificationService(this._ref);

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Callback for handling notification taps (set by the app shell).
  /// Receives the notification data payload for deep-link routing.
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initialize FCM — call once after Firebase.initializeApp().
  ///
  /// Flow:
  /// 1. Register background handler
  /// 2. Request permission (critical for iOS; no-op on Android 12-)
  /// 3. Get FCM token → send to backend
  /// 4. Listen for token refresh
  /// 5. Listen for foreground messages
  /// 6. Handle notification tap (app was in background)
  Future<void> initialize() async {
    try {
      // 1. Background handler
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // 2. Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      debugPrint('[FCM] Permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[FCM] User denied notification permissions');
        return;
      }

      // 3. Get current FCM token and send to backend
      try {
        final token = await _messaging.getToken();
        if (token != null) {
          debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
          await _sendTokenToBackend(token);
        }
      } catch (e) {
        debugPrint('[FCM] Token retrieval failed: $e');
      }

      // 4. Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed');
        _sendTokenToBackend(newToken);
      });

      // 5. Foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Handle notification tap from background/terminated state
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was launched from a notification tap (terminated state)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      // Graceful degradation: if Firebase isn't configured (dev placeholder),
      // the app still works — just without push notifications.
      debugPrint('[FCM] Initialization failed (FCM unavailable): $e');
    }
  }

  /// Send FCM token to backend via existing auth repository.
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.updateFcmToken(token);
      debugPrint('[FCM] Token sent to backend');
    } catch (e) {
      // Non-fatal: token will be retried on next refresh.
      // WHY not fatal: the user might not be logged in yet.
      debugPrint('[FCM] Failed to send token: $e');
    }
  }

  /// Handle foreground notification display.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    // Foreground notification display is handled by Android's
    // notification channel (set in AndroidManifest.xml).
    // The firebase_messaging plugin shows heads-up notification
    // when setForegroundNotificationPresentationOptions is set.
    //
    // For custom in-app banners, this is where you'd trigger a
    // SnackBar or overlay via a callback.
  }

  /// Handle notification tap → extract data for deep-link routing.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Tap: ${message.data}');
    final data = message.data;
    if (data.isNotEmpty && onNotificationTap != null) {
      onNotificationTap!(data);
    }
  }
}
