import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin Dio wrapper shared by every repository that talks to the Django
/// backend in `Delivery/` (JWT auth via `djangorestframework-simplejwt`).
///
/// Attaches the stored access token to every request, and — on a 401 —
/// tries exactly once to refresh it via `/api/token/refresh/` before
/// giving up and clearing the session (the caller sees the original 401
/// and should route back to login).
class ApiClient {
  /// Pre-login endpoints that must never get a stored `Authorization`
  /// header attached (a stale/invalid one gets rejected by the backend
  /// before the view even runs) and must never trigger the refresh-retry
  /// flow on 401. NOT a blanket `/auth/` prefix check — `/auth/profile/`
  /// is a real authenticated endpoint and needs the token like any other.
  static const _publicAuthPaths = [
    '/auth/send-otp/',
    '/auth/resend-otp/',
    '/auth/verify-otp/',
    '/auth/master-login/',
  ];

  static bool _isPublicAuthEndpoint(String path) =>
      _publicAuthPaths.any((p) => path.contains(p));

  /// [tokenScope] namespaces the stored tokens (e.g. `'customer'` vs.
  /// `'admin'`) so the customer app and the admin console — two separate
  /// products sharing one Flutter codebase/process here — can each hold
  /// their own signed-in session without one login clobbering the other.
  ApiClient({
    String? baseUrl,
    FlutterSecureStorage? secureStorage,
    String tokenScope = 'customer',
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _accessTokenKey = 'basket_${tokenScope}_access_token',
        _refreshTokenKey = 'basket_${tokenScope}_refresh_token',
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  // 127.0.0.1 works for iOS simulator / macOS / web against a
                  // locally-run `python manage.py runserver`. Android
                  // emulators need `10.0.2.2` instead — pass
                  // `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api` there.
                    // defaultValue: 'http://192.168.1.3:8000/api',
                  // defaultValue:'http://192.168.9.153:8000/api',
                   defaultValue:'https://deliverybe.vercel.app/api',
                ),
            contentType: 'application/json',
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final isAuthEndpoint = _isPublicAuthEndpoint(options.path);
          if (!isAuthEndpoint) {
            final token = await _secureStorage.read(key: _accessTokenKey);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isAuthError = error.response?.statusCode == 401;
          final isAuthEndpoint = _isPublicAuthEndpoint(error.requestOptions.path);
          if (isAuthError && !isAuthEndpoint && error.requestOptions.extra['_retried'] != true) {
            final refreshed = await _tryRefresh();
            if (refreshed != null) {
              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $refreshed';
              retryOptions.extra['_retried'] = true;
              try {
                final response = await dio.fetch(retryOptions);
                handler.resolve(response);
                return;
              } on DioException catch (retryError) {
                handler.next(retryError);
                return;
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;
  final FlutterSecureStorage _secureStorage;
  final String _accessTokenKey;
  final String _refreshTokenKey;

  Future<String?> _tryRefresh() async {
    final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;
    try {
      // A bare Dio instance (not `dio`) so this call skips the auth
      // interceptor above — it must not attach the (expired) access token.
      final response = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
        '/token/refresh/',
        data: {'refresh': refreshToken},
      );
      final access = response.data['access'] as String;
      final rotatedRefresh = response.data['refresh'] as String?;
      await _secureStorage.write(key: _accessTokenKey, value: access);
      if (rotatedRefresh != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: rotatedRefresh);
      }
      return access;
    } catch (_) {
      await clearTokens();
      return null;
    }
  }

  Future<void> persistTokens({required String access, required String refresh}) async {
    await _secureStorage.write(key: _accessTokenKey, value: access);
    await _secureStorage.write(key: _refreshTokenKey, value: refresh);
  }

  Future<bool> hasSession() async => (await _secureStorage.read(key: _accessTokenKey)) != null;

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
  }
}
