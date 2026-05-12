/// Production-safe JSON parsing utilities.
///
/// Laravel returns `decimal` columns as **strings** (e.g. `"0.00"`) while Dart
/// JSON decoders deliver numbers as `int` or `double`.  These helpers bridge
/// that gap by accepting both types gracefully.
///
/// Usage:
/// ```dart
/// import 'package:savebite/core/utils/safe_parse.dart';
///
/// final price = toDoubleOrNull(json['price']);       // "12500.00" → 12500.0
/// final qty   = toIntOrNull(json['quantity']);        // 5 → 5
/// final dist  = toDoubleOrNull(json['distance_km']); // null → null
/// ```
library;

/// Converts a JSON value (int, double, String, or null) to [double?].
///
/// Handles Laravel `decimal:N` casts that arrive as strings like `"0.00"`.
double? toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Converts a JSON value to a non-null [double], with a [fallback].
double toDouble(dynamic value, [double fallback = 0.0]) {
  return toDoubleOrNull(value) ?? fallback;
}

/// Converts a JSON value (int, double, String, or null) to [int?].
///
/// Handles edge cases where backend returns numeric strings.
int? toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Converts a JSON value to a non-null [int], with a [fallback].
int toInt(dynamic value, [int fallback = 0]) {
  return toIntOrNull(value) ?? fallback;
}

/// Converts a JSON value to [bool], with a [fallback].
///
/// Handles int-as-bool (0/1) from MySQL and string representations.
bool toBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return fallback;
}
