import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/cart_models.dart';

/// The logged-in customer's cart + wishlist. See `cart/views.py`.
class CartRepository {
  CartRepository(this._client);

  final ApiClient _client;

  Future<ApiCart> fetchCart() async {
    try {
      final response = await _client.dio.get('/cart/');
      return ApiCart.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCart> addItem(int productId, {int qty = 1}) async {
    try {
      final response = await _client.dio.post('/cart/items/', data: {'product': productId, 'qty': qty});
      return ApiCart.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCart> setItemQty(int productId, int qty) async {
    try {
      final response = await _client.dio.patch('/cart/items/$productId/', data: {'qty': qty});
      return ApiCart.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCart> removeItem(int productId) async {
    try {
      final response = await _client.dio.delete('/cart/items/$productId/');
      return ApiCart.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _client.dio.delete('/cart/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCart> applyCoupon(String code) async {
    try {
      final response = await _client.dio.post('/cart/coupon/', data: {'code': code});
      return ApiCart.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiCart> removeCoupon() async {
    try {
      final response = await _client.dio.delete('/cart/coupon/');
      return ApiCart.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<ApiWishlistItem>> fetchWishlist() async {
    try {
      final response = await _client.dio.get('/wishlist/');
      return (response.data as List).map((e) => ApiWishlistItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> addToWishlist(int productId) async {
    try {
      await _client.dio.post('/wishlist/', data: {'product': productId});
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> removeFromWishlist(int productId) async {
    try {
      await _client.dio.delete('/wishlist/$productId/');
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
