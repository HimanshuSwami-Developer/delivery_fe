import 'package:dio/dio.dart';

/// A [DioException] normalized down to a status code + a human-readable
/// message, so cubits never need to know DRF's error-body shape (`detail`,
/// `{field: [errors]}`, or a validation-error map) to show something
/// sensible in a snackbar.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.from(Object error) {
    if (error is! DioException) {
      return ApiException(error.toString());
    }
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return ApiException(detail, statusCode: statusCode);

      // DRF field-error shape: {"field": ["msg1", "msg2"], ...}
      final firstError = data.values.firstWhere(
        (v) => v is List && v.isNotEmpty,
        orElse: () => null,
      );
      if (firstError is List && firstError.isNotEmpty) {
        return ApiException(firstError.first.toString(), statusCode: statusCode);
      }
    }

    if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout) {
      return const ApiException("Can't reach the server. Check your connection and try again.");
    }

    return ApiException(error.message ?? 'Something went wrong.', statusCode: statusCode);
  }

  @override
  String toString() => message;
}
