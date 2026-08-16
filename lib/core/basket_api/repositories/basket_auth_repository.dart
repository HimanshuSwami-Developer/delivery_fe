import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';

/// Phone + OTP auth against `accounts.urls` (`/api/auth/...`), shared by
/// both the customer app and the admin console — only the profile's `role`
/// differs afterward.
class BasketAuthRepository {
  BasketAuthRepository(this._client);

  final ApiClient _client;

  Future<int> sendOtp(String mobileNumber) async {
    try {
      final response = await _client.dio.post('/auth/send-otp/', data: {'mobile_number': mobileNumber});
      return response.data['expires_in_minutes'] as int? ?? 5;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<int> resendOtp(String mobileNumber) async {
    try {
      final response = await _client.dio.post('/auth/resend-otp/', data: {'mobile_number': mobileNumber});
      return response.data['expires_in_minutes'] as int? ?? 5;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<LoginResult> verifyOtp({required String mobileNumber, required String otpCode}) async {
    try {
      final response = await _client.dio.post(
        '/auth/verify-otp/',
        data: {'mobile_number': mobileNumber, 'otp_code': otpCode},
      );
      final result = LoginResult.fromJson(response.data as Map<String, dynamic>);
      await _client.persistTokens(access: result.tokens.access, refresh: result.tokens.refresh);
      return result;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Logs in with the fixed QA/testing code from `settings.MASTER_OTP` —
  /// no SMS involved. Used by the admin console's "Sign in" (a real login,
  /// unlike the customer app which always does a real OTP).
  Future<LoginResult> masterLogin({required String mobileNumber, required String masterOtp}) async {
    try {
      final response = await _client.dio.post(
        '/auth/master-login/',
        data: {'mobile_number': mobileNumber, 'master_otp': masterOtp},
      );
      final result = LoginResult.fromJson(response.data as Map<String, dynamic>);
      await _client.persistTokens(access: result.tokens.access, refresh: result.tokens.refresh);
      return result;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Upserts this device's FCM token against the signed-in user — see
  /// `accounts.RegisterDeviceView`. Safe to call repeatedly (e.g. on every
  /// app start and whenever the OS rotates the token); failures are
  /// swallowed by the caller since a missed registration just means this
  /// device won't get pushes until the next successful call, not a
  /// user-facing error.
  Future<void> registerDevice({required String token, required String platform}) async {
    try {
      await _client.dio.post('/auth/device-token/', data: {'token': token, 'platform': platform});
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProfile?> fetchProfile() async {
    try {
      final response = await _client.dio.get('/auth/profile/');
      return ApiProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      final err = ApiException.from(e);
      if (err.statusCode == 404) return null; // profile not completed yet
      throw err;
    }
  }

  Future<ApiProfile> completeProfile(String name) async {
    try {
      final response = await _client.dio.post('/auth/profile/', data: {'name': name});
      return ApiProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiProfile> updateProfile(String name) async {
    try {
      final response = await _client.dio.patch('/auth/profile/', data: {'name': name});
      return ApiProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<ApiAddress>> fetchAddresses() async {
    try {
      final response = await _client.dio.get('/auth/profile/addresses/');
      return (response.data as List).map((e) => ApiAddress.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiAddress> addAddress(ApiAddress address) async {
    try {
      final response = await _client.dio.post('/auth/profile/addresses/', data: address.toJson());
      return ApiAddress.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiAddress> updateAddress(String id, ApiAddress address) async {
    try {
      final response = await _client.dio.patch('/auth/profile/addresses/$id/', data: address.toJson());
      return ApiAddress.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _client.dio.delete('/auth/profile/addresses/$id/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<bool> hasSession() => _client.hasSession();

  Future<void> logout() => _client.clearTokens();
}
