/// Compile-time environment configuration via `--dart-define`.
///
/// WHY `--dart-define` instead of `.env` files or runtime config:
/// - Values are baked into the binary at compile time → zero runtime cost
/// - Cannot be tampered with via reverse-engineering (unlike SharedPreferences)
/// - Works identically on iOS, Android, web, and desktop
/// - Flutter test runner supports it natively
///
/// Usage:
/// ```bash
/// # Development (Android emulator — default)
/// flutter run
///
/// # Development (physical device on same WiFi)
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8000/api/v1
///
/// # Development (iOS simulator)
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
///
/// # Staging
/// flutter run --dart-define=API_BASE_URL=https://staging-api.savebite.id/api/v1 --dart-define=ENV=staging
///
/// # Production
/// flutter build apk --dart-define=API_BASE_URL=https://api.savebite.id/api/v1 --dart-define=ENV=production
/// ```
class AppEnv {
  const AppEnv._();

  /// Current environment name: `development`, `staging`, or `production`.
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// API base URL. Defaults to Android emulator localhost proxy.
  ///
  /// The default `10.0.2.2` is Android emulator's alias for host machine
  /// localhost. For iOS simulator, pass `localhost` explicitly.
  /// For physical devices, pass the host machine's WiFi IP.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Midtrans client key (sandbox vs production).
  static const String midtransClientKey = String.fromEnvironment(
    'MIDTRANS_CLIENT_KEY',
    defaultValue: '', // sandbox key injected via CI/CD
  );

  /// Whether this is a production build.
  static bool get isProduction => env == 'production';

  /// Whether this is a staging build.
  static bool get isStaging => env == 'staging';

  /// Whether this is a development build.
  static bool get isDevelopment => env == 'development';

  /// Connect timeout — tighter in prod, relaxed in dev.
  static Duration get connectTimeout =>
      isProduction ? const Duration(seconds: 10) : const Duration(seconds: 15);

  /// Receive timeout.
  static Duration get receiveTimeout =>
      isProduction ? const Duration(seconds: 10) : const Duration(seconds: 15);
}
