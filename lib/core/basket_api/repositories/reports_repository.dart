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

  /// Successfully delivered sales grouped by [period] ('daily' | 'weekly' |
  /// 'monthly' | 'yearly'); [start]/[end] default server-side to a trailing
  /// window per period. See `DeliveredSalesReportView`.
  Future<DeliveredSalesReport> fetchDeliveredSales({required String period, String? start, String? end}) async {
    try {
      final response = await _client.dio.get('/admin/reports/sales/delivered/', queryParameters: {
        'period': period,
        'start': ?start,
        'end': ?end,
      });
      return DeliveredSalesReport.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// .xlsx bytes of [fetchDeliveredSales] — Summary, every delivered order,
  /// and products sold. See `DeliveredSalesExportView`.
  Future<List<int>> fetchDeliveredSalesExcel({required String period, String? start, String? end}) async {
    try {
      final response = await _client.dio.get<List<int>>(
        '/admin/reports/sales/delivered/export/',
        queryParameters: {'period': period, 'start': ?start, 'end': ?end},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
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

  /// The seller's GST profile shown on the GST settings panel — see
  /// `StoreSettingsView`.
  Future<StoreGstSettings> fetchStoreSettings() async {
    try {
      final response = await _client.dio.get('/admin/reports/settings/');
      return StoreGstSettings.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Saves edits from the GST settings panel — takes effect on the next
  /// invoice/GSTR-3B/GSTR-1 generated, no deploy needed.
  Future<StoreGstSettings> updateStoreSettings(StoreGstSettings settings) async {
    try {
      final response = await _client.dio.patch('/admin/reports/settings/', data: settings.toJson());
      return StoreGstSettings.fromJson(response.data as Map<String, dynamic>);
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
