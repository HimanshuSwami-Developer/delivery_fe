import 'package:dio/dio.dart';

/// A [DioException] normalized down to a status code + a human-readable
/// message, so cubits never need to know DRF's error-body shape (`detail`,
/// `{field: [errors]}`, or a validation-error map) to show something
/// sensible in a snackbar.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.data});

  final String message;
  final int? statusCode;

  /// The raw DRF error body, when it's a JSON object — e.g. `/auth/profile/`
  /// 404s bundle `role`/`mobile_number` alongside `detail` so callers can
  /// still recover them even though the request "failed".
  final Map<String, dynamic>? data;

  factory ApiException.from(Object error) {
    if (error is! DioException) {
      return ApiException(error.toString());
    }
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final dataMap = data is Map ? Map<String, dynamic>.from(data) : null;

    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return ApiException(detail, statusCode: statusCode, data: dataMap);

      // DRF field-error shape: {"field": ["msg1", "msg2"], ...}
      final firstError = data.values.firstWhere(
        (v) => v is List && v.isNotEmpty,
        orElse: () => null,
      );
      if (firstError is List && firstError.isNotEmpty) {
        return ApiException(firstError.first.toString(), statusCode: statusCode, data: dataMap);
      }
    }

    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return const ApiException("Can't reach the server. Check your connection and try again.");
    }

    return ApiException(error.message ?? 'Something went wrong.', statusCode: statusCode, data: dataMap);
  }

  @override
  String toString() => message;
}
