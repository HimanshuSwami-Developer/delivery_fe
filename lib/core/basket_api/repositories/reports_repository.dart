import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/report_models.dart';

/// Admin-only aggregate reports, computed live server-side from real
/// `Order`/`ProductStock` data — see `reports/views.py`.
class ReportsRepository {
  ReportsRepository(this._client);

  final ApiClient _client;

  Future<DashboardReport> fetchDashboard() async {
    try {
      final response = await _client.dio.get('/admin/reports/dashboard/');
      return DashboardReport.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<SalesReport> fetchSales({int months = 6}) async {
    try {
      final response = await _client.dio.get('/admin/reports/sales/', queryParameters: {'months': months});
      return SalesReport.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<GstReport> fetchGst({String? month}) async {
    try {
      final response = await _client.dio.get('/admin/reports/gst/', queryParameters: {'month': ?month});
      return GstReport.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<AdminCustomerRow>> fetchCustomers() async {
    try {
      final response = await _client.dio.get('/auth/admin/customers/');
      return (response.data as List).map((e) => AdminCustomerRow.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}
