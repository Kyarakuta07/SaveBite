import 'package:dio/dio.dart';

import '../constants/strings.dart';

/// Sealed result type for API calls.
///
/// Usage with pattern matching:
/// ```dart
/// final result = await ApiResult.guard(() => dio.get('/food-items'));
/// switch (result) {
///   case Success(:final data):  // handle data
///   case Failure(:final message): // handle error
/// }
/// ```
sealed class ApiResult<T> {
  const ApiResult();

  /// Wrap an async call in a result.
  static Future<ApiResult<T>> guard<T>(Future<T> Function() fn) async {
    try {
      return Success(await fn());
    } on DioException catch (e) {
      return Failure(
        message: _extractMessage(e),
        statusCode: e.response?.statusCode,
        fieldErrors: _extractFieldErrors(e),
      );
    } catch (e) {
      return Failure(message: e.toString());
    }
  }

  static String _extractMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return Strings.networkError;
    }
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['errors'] is Map) {
        final errors = data['errors'] as Map;
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first[0].toString();
      }
      if (data['message'] != null) return data['message'].toString();
    }
    return Strings.unknownError;
  }

  static Map<String, List<String>>? _extractFieldErrors(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['errors'] is Map) {
      return (data['errors'] as Map).map(
        (k, v) => MapEntry(
          k.toString(),
          (v as List).map((e) => e.toString()).toList(),
        ),
      );
    }
    return null;
  }
}

/// Successful API result.
class Success<T> extends ApiResult<T> {
  const Success(this.data);
  final T data;
}

/// Failed API result.
class Failure<T> extends ApiResult<T> {
  const Failure({
    required this.message,
    this.statusCode,
    this.fieldErrors,
  });
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? fieldErrors;
}
