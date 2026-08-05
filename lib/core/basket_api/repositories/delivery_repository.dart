import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

/// Admin-only delivery-partner roster. See `delivery/views.py`.
class DeliveryRepository {
  DeliveryRepository(this._client);

  final ApiClient _client;

  Future<List<ApiDeliveryPartner>> fetchPartners({int? zone, String? status}) async {
    try {
      final response = await _client.dio.get('/partners/', queryParameters: {
        'zone': ?zone,
        'status': ?status,
        'page_size': 100,
      });
      return extractResults(response.data)
          .map((e) => ApiDeliveryPartner.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiDeliveryPartner> createPartner(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/partners/', data: data);
      return ApiDeliveryPartner.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiDeliveryPartner> updatePartner(int id, Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.patch('/partners/$id/', data: data);
      return ApiDeliveryPartner.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
