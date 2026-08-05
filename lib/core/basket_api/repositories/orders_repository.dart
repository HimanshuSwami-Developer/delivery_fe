import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

/// Placing/tracking orders (customer) and managing them (admin). Customers
/// only ever see their own orders — enforced server-side by
/// `OrderViewSet.get_queryset`, not by anything client-side. See
/// `orders/views.py`.
class OrdersRepository {
  OrdersRepository(this._client);

  final ApiClient _client;

  Future<List<ApiOrder>> fetchOrders({String? status, int? zone}) async {
    try {
      final response = await _client.dio.get('/orders/', queryParameters: {
        'status': ?status,
        'zone': ?zone,
        'page_size': 100,
      });
      return extractResults(response.data).map((e) => ApiOrder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiOrder> fetchOrder(int id) async {
    try {
      final response = await _client.dio.get('/orders/$id/');
      return ApiOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiOrder> placeOrder({
    String? addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
    required int zone,
    required String paymentMode,
    String? deliverySlotDate,
    String? deliverySlotLabel,
    String? gstin,
  }) async {
    try {
      final response = await _client.dio.post('/orders/place/', data: {
        'address_id': ?addressId,
        'address_line1': ?addressLine1,
        'city': ?city,
        'state': ?state,
        'pincode': ?pincode,
        'zone': zone,
        'payment_mode': paymentMode,
        'delivery_slot_date': ?deliverySlotDate,
        'delivery_slot_label': ?deliverySlotLabel,
        'gstin': ?gstin,
      });
      return ApiOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiOrder> cancelOrder(int id) async {
    try {
      final response = await _client.dio.post('/orders/$id/cancel/');
      return ApiOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiOrder> setStatus(int id, String status) async {
    try {
      final response = await _client.dio.patch('/orders/$id/set_status/', data: {'status': status});
      return ApiOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiOrder> assignPartner(int id, int deliveryPartnerId) async {
    try {
      final response = await _client.dio.post('/orders/$id/assign_partner/', data: {
        'delivery_partner': deliveryPartnerId,
      });
      return ApiOrder.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
