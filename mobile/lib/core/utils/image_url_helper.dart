import '../config/app_env.dart';

/// Centralized image URL resolution for SaveBite.
///
/// WHY this exists:
/// The Laravel backend generates image URLs using `asset()`, which resolves
/// against `APP_URL` (typically `http://localhost:8000` in dev). But the
/// Flutter app on an Android emulator can't reach `localhost` — it needs
/// `10.0.2.2`. This helper rewrites backend-generated URLs to use the
/// same host the API client uses, ensuring images load correctly in every
/// environment (emulator, physical device, staging, production).
///
/// ARCHITECTURE:
/// - Single source of truth for all image URL resolution
/// - Handles null, empty, relative, and fully-qualified URLs
/// - CDN-migration-ready: swap the base URL here and all images update
/// - No screen-level code needs to know about URL rewriting
class ImageUrlHelper {
  const ImageUrlHelper._();

  /// Derives the storage base URL from the API base URL.
  ///
  /// API base: `http://10.0.2.2:8000/api/v1`
  /// Storage base: `http://10.0.2.2:8000`
  ///
  /// In production with a CDN, override this with:
  /// `static String get _storageBaseUrl => 'https://cdn.savebite.id';`
  static String get _storageBaseUrl {
    final apiUrl = AppEnv.apiBaseUrl; // e.g. http://10.0.2.2:8000/api/v1
    final uri = Uri.tryParse(apiUrl);
    if (uri == null) return apiUrl;
    // Strip the /api/v1 path to get the server root
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  /// Resolves a backend image value into a fully-qualified, loadable URL.
  ///
  /// Handles all known patterns:
  /// - `null` or empty → returns `null`
  /// - Already a full URL with `http(s)://` → rewrites host to match API
  /// - Relative path like `food/abc.jpg` → prepends storage base
  /// - Path starting with `/storage/` → prepends server base
  /// - Path starting with `storage/` → prepends server base with `/`
  ///
  /// Returns `null` if the input is unusable, so callers can show fallback.
  static String? resolve(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;

    final trimmed = rawUrl.trim();

    // Full URL — rewrite host to match our API target
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return _rewriteHost(trimmed);
    }

    // Absolute path from server root: /storage/food/abc.jpg
    if (trimmed.startsWith('/storage/')) {
      return '$_storageBaseUrl$trimmed';
    }

    // Relative path without leading slash: storage/food/abc.jpg
    if (trimmed.startsWith('storage/')) {
      return '$_storageBaseUrl/$trimmed';
    }

    // Raw storage path from DB: food/abc.jpg
    // This is what Laravel stores in the `image` column
    return '$_storageBaseUrl/storage/$trimmed';
  }

  /// Rewrites a full URL's host/port to match our API server.
  ///
  /// Example:
  /// Input:  `http://localhost:8000/storage/food/abc.jpg`
  /// Output: `http://10.0.2.2:8000/storage/food/abc.jpg`
  ///
  /// This is necessary because `APP_URL` in Laravel's `.env` is typically
  /// `http://localhost:8000`, but the emulator can't reach `localhost`.
  static String _rewriteHost(String fullUrl) {
    final sourceUri = Uri.tryParse(fullUrl);
    if (sourceUri == null) return fullUrl;

    final targetUri = Uri.tryParse(_storageBaseUrl);
    if (targetUri == null) return fullUrl;

    // If the hosts already match, no rewrite needed
    if (sourceUri.host == targetUri.host &&
        sourceUri.port == targetUri.port) {
      return fullUrl;
    }

    // Rebuild with the target host but keep the original path
    return sourceUri
        .replace(
          scheme: targetUri.scheme,
          host: targetUri.host,
          port: targetUri.port,
        )
        .toString();
  }
}
