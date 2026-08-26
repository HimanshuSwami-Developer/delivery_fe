import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

/// Coupons/banners/notifications — public read, admin write. See
/// `promotions/views.py`.
class PromotionsRepository {
  PromotionsRepository(this._client);

  final ApiClient _client;

  Future<List<ApiCoupon>> fetchCoupons({bool? isActive}) async {
    try {
      final response = await _client.dio.get('/coupons/', queryParameters: {
        'is_active': ?isActive,
        'page_size': 50,
      });
      return extractResults(response.data).map((e) => ApiCoupon.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCoupon> createCoupon(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/coupons/', data: data);
      return ApiCoupon.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCoupon> setCouponActive(String code, bool isActive) async {
    try {
      final response = await _client.dio.patch('/coupons/$code/', data: {'is_active': isActive});
      return ApiCoupon.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCoupon> updateCoupon(String code, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/coupons/$code/', data: data);
      return ApiCoupon.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteCoupon(String code) async {
    try {
      await _client.dio.delete('/coupons/$code/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Returns `(discount, errorMessage)` — exactly one is non-null.
  Future<(int?, String?)> validateCoupon({required String code, required int subtotal}) async {
    try {
      final response = await _client.dio.post('/coupons/validate_code/', data: {'code': code, 'subtotal': subtotal});
      return (response.data['discount'] as int, null);
    } catch (e) {
      final err = ApiException.from(e);
      return (null, err.message);
    }
  }

  Future<List<ApiBanner>> fetchBanners({String? placement, bool? isActive}) async {
    try {
      final response = await _client.dio.get('/banners/', queryParameters: {
        'placement': ?placement,
        'is_active': ?isActive,
        'page_size': 50,
      });
      return extractResults(response.data).map((e) => ApiBanner.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiBanner> createBanner(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/banners/', data: data);
      return ApiBanner.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiBanner> setBannerActive(int id, bool isActive) async {
    try {
      final response = await _client.dio.patch('/banners/$id/', data: {'is_active': isActive});
      return ApiBanner.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiBanner> updateBanner(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/banners/$id/', data: data);
      return ApiBanner.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteBanner(int id) async {
    try {
      await _client.dio.delete('/banners/$id/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<ApiNotification>> fetchNotifications() async {
    try {
      final response = await _client.dio.get('/notifications/', queryParameters: {'page_size': 50});
      return extractResults(response.data).map((e) => ApiNotification.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiNotification> createNotification({required String title, required String body, required String audience}) async {
    try {
      final response = await _client.dio.post('/notifications/', data: {'title': title, 'body': body, 'audience': audience});
      return ApiNotification.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiNotification> sendNotification(int id) async {
    try {
      final response = await _client.dio.post('/notifications/$id/send_now/');
      return ApiNotification.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
