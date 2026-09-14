import 'package:dio/dio.dart';
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

  Future<List<ApiOrder>> fetchOrders({String? status}) async {
    try {
      final response = await _client.dio.get('/orders/', queryParameters: {
        'status': ?status,
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

  /// [paymentScreenshotBytes]/[paymentScreenshotFilename] are QR checkout
  /// only — proof of the UPI payment the customer already made, uploaded
  /// to Cloudinary server-side and stored on the order for admin review
  /// (`payment_status` stays 'pending' either way). Sending a file forces
  /// this onto a multipart request; every other field rides along as a
  /// plain form field.
  Future<ApiOrder> placeOrder({
    String? addressId,
    String? addressLine1,
    String? city,
    String? state,
    String? pincode,
    required String paymentMode,
    String? deliverySlotDate,
    String? deliverySlotLabel,
    String? gstin,
    List<int>? paymentScreenshotBytes,
    String? paymentScreenshotFilename,
  }) async {
    try {
      final fields = {
        'address_id': ?addressId,
        'address_line1': ?addressLine1,
        'city': ?city,
        'state': ?state,
        'pincode': ?pincode,
        'payment_mode': paymentMode,
        'delivery_slot_date': ?deliverySlotDate,
        'delivery_slot_label': ?deliverySlotLabel,
        'gstin': ?gstin,
      };
      final data = paymentScreenshotBytes == null
          ? fields
          : FormData.fromMap({
              ...fields,
              'payment_screenshot': MultipartFile.fromBytes(
                paymentScreenshotBytes,
                filename: paymentScreenshotFilename ?? 'screenshot.jpg',
              ),
            });
      final response = await _client.dio.post('/orders/place/', data: data);
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

  /// Raw PDF bytes for order [id]'s GST invoice — server generates it on
  /// demand from the order's own stored data (see `OrderViewSet.invoice`),
  /// so it's available immediately after placement. Visibility mirrors
  /// [fetchOrder]: the customer who placed it, the assigned delivery
  /// partner, or an admin.
  Future<List<int>> fetchInvoicePdf(int id) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/orders/$id/invoice/',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Raw PDF bytes for order [id]'s receipt — the same data as
  /// [fetchInvoicePdf], laid out as a printable 80mm POS/till-receipt
  /// instead of an A4 tax invoice. See `OrderViewSet.receipt`.
  Future<List<int>> fetchReceiptPdf(int id) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/orders/$id/receipt/',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
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
