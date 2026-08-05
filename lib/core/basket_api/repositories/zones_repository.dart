import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/zone_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

class ZonesRepository {
  ZonesRepository(this._client);

  final ApiClient _client;

  Future<List<ApiZone>> fetchZones() async {
    try {
      final response = await _client.dio.get('/zones/', queryParameters: {'page_size': 50});
      return extractResults(response.data).map((e) => ApiZone.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiZone> createZone(Map<String, dynamic> data) async {
    try {
      final response = await _client.dio.post('/zones/', data: data);
      return ApiZone.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiZone> setZoneOpen(int id, bool isOpen) async {
    try {
      final response = await _client.dio.patch('/zones/$id/', data: {'is_open': isOpen});
      return ApiZone.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
