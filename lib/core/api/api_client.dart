import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin Dio wrapper shared by all feature repositories once they talk to the
/// real backend. Not yet wired to any live endpoint.
class ApiClient {
  ApiClient({
    String? baseUrl,
    FlutterSecureStorage? secureStorage,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'https://api.fastswipe.example.com',
                ),
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: _authTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final FlutterSecureStorage _secureStorage;

  static const _authTokenKey = 'auth_token';

  Future<void> persistAuthToken(String token) =>
      _secureStorage.write(key: _authTokenKey, value: token);

  Future<void> clearAuthToken() => _secureStorage.delete(key: _authTokenKey);
}
