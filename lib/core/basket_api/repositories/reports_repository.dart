import 'package:dio/dio.dart';
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

  /// CSV bytes for the "⤓ Export CSV" button on the Sales reports screen —
  /// same numbers as [fetchSales], see `SalesReportExportView`.
  Future<List<int>> fetchSalesExportCsv({int months = 6}) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/admin/reports/sales/export/',
        queryParameters: {'months': months},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GSTR-1-shaped JSON bytes for the GST screen's "⤓ GSTR-1 (JSON)"
  /// button — see `Gstr1ExportView`.
  Future<List<int>> fetchGstr1Json({String? month}) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/admin/reports/gst/gstr1/',
        queryParameters: {'month': ?month},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// GSTR-3B summary PDF bytes for the GST screen's "⤓ GSTR-3B summary"
  /// button — see `Gstr3bExportView`.
  Future<List<int>> fetchGstr3bPdf({String? month}) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/admin/reports/gst/gstr3b/',
        queryParameters: {'month': ?month},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
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
