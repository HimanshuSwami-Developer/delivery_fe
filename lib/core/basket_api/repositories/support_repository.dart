import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/support_models.dart';
import 'package:fastswipe/core/basket_api/pagination.dart';

class SupportRepository {
  SupportRepository(this._client);

  final ApiClient _client;

  Future<List<ApiSupportTicket>> fetchTickets() async {
    try {
      final response = await _client.dio.get('/tickets/');
      return extractResults(response.data).map((e) => ApiSupportTicket.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<ApiSupportTicket> createTicket({required String subject, required String message, int? orderId}) async {
    try {
      final response = await _client.dio.post('/tickets/', data: {
        'subject': subject,
        'message': message,
        'order': ?orderId,
      });
      return ApiSupportTicket.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
