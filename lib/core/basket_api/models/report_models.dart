import 'package:fastswipe/core/basket_api/json_utils.dart';


/// One point of `DashboardReport.chart14d`.
class ChartPoint {
  const ChartPoint({required this.date, required this.gmv});
  final String date;
  final int gmv;

  factory ChartPoint.fromJson(Map<String, dynamic> json) =>
      ChartPoint(date: json['date'] as String, gmv: json['gmv'] as int);
}

class LowStockRow {
  const LowStockRow({required this.product, required this.sku, required this.onHand});
  final String product;
  final String sku;
  final int onHand;

  factory LowStockRow.fromJson(Map<String, dynamic> json) => LowStockRow(
        product: json['product'] as String,
        sku: json['sku'] as String,
        onHand: json['on_hand'] as int,
      );
}

class RecentOrderRow {
  const RecentOrderRow({
    required this.id,
    required this.orderNumber,
    required this.customer,
    required this.itemCount,
    required this.total,
    this.deliveryPartner,
    required this.status,
  });
  final int id;
  final String orderNumber;
  final String customer;
  final int itemCount;
  final int total;
  final String? deliveryPartner;
  final String status;

  factory RecentOrderRow.fromJson(Map<String, dynamic> json) => RecentOrderRow(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String,
        customer: json['customer'] as String,
        itemCount: json['item_count'] as int,
        total: json['total'] as int,
        deliveryPartner: json['delivery_partner'] as String?,
        status: json['status'] as String,
      );
}

/// Mirrors `reports.views.DashboardReportView`'s JSON.
class DashboardReport {
  const DashboardReport({
    required this.gmvToday,
    this.gmvDeltaPct,
    required this.ordersToday,
    this.ordersDeltaPct,
    required this.avgBasket,
    this.onTimeRatePct,
    required this.chart14d,
    required this.lowStock,
    required this.recentOrders,
  });

  final int gmvToday;
  final double? gmvDeltaPct;
  final int ordersToday;
  final double? ordersDeltaPct;
  final int avgBasket;
  final double? onTimeRatePct;
  final List<ChartPoint> chart14d;
  final List<LowStockRow> lowStock;
  final List<RecentOrderRow> recentOrders;

  factory DashboardReport.fromJson(Map<String, dynamic> json) {
    final kpis = json['kpis'] as Map<String, dynamic>;
    return DashboardReport(
      gmvToday: kpis['gmv_today'] as int,
      gmvDeltaPct: (kpis['gmv_delta_pct'] as num?)?.toDouble(),
      ordersToday: kpis['orders_today'] as int,
      ordersDeltaPct: (kpis['orders_delta_pct'] as num?)?.toDouble(),
      avgBasket: kpis['avg_basket'] as int,
      onTimeRatePct: (kpis['on_time_rate_pct'] as num?)?.toDouble(),
      chart14d: (json['chart_14d'] as List).map((e) => ChartPoint.fromJson(e as Map<String, dynamic>)).toList(),
      lowStock: (json['low_stock'] as List).map((e) => LowStockRow.fromJson(e as Map<String, dynamic>)).toList(),
      recentOrders:
          (json['recent_orders'] as List).map((e) => RecentOrderRow.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class MonthlyRevenuePoint {
  const MonthlyRevenuePoint({required this.month, required this.revenue});
  final String month;
  final int revenue;

  factory MonthlyRevenuePoint.fromJson(Map<String, dynamic> json) =>
      MonthlyRevenuePoint(month: json['month'] as String, revenue: json['revenue'] as int);
}

class TopCategoryRow {
  const TopCategoryRow({required this.category, required this.revenue});
  final String? category;
  final num revenue;

  factory TopCategoryRow.fromJson(Map<String, dynamic> json) =>
      TopCategoryRow(category: json['category'] as String?, revenue: json['revenue'] as num);
}

/// Mirrors `reports.views.SalesReportView`'s JSON.
class SalesReport {
  const SalesReport({
    required this.revenueThisMonth,
    required this.ordersThisMonth,
    required this.avgBasket,
    this.repeatRatePct,
    required this.monthlyRevenue,
    required this.topCategories,
  });

  final int revenueThisMonth;
  final int ordersThisMonth;
  final int avgBasket;
  final double? repeatRatePct;
  final List<MonthlyRevenuePoint> monthlyRevenue;
  final List<TopCategoryRow> topCategories;

  factory SalesReport.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>;
    return SalesReport(
      revenueThisMonth: stats['revenue_this_month'] as int,
      ordersThisMonth: stats['orders_this_month'] as int,
      avgBasket: stats['avg_basket'] as int,
      repeatRatePct: (stats['repeat_rate_pct'] as num?)?.toDouble(),
      monthlyRevenue: (json['monthly_revenue'] as List)
          .map((e) => MonthlyRevenuePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCategories:
          (json['top_categories'] as List).map((e) => TopCategoryRow.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class GstSlabRow {
  const GstSlabRow({
    required this.slab,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.totalTax,
    required this.invoices,
  });
  final String slab;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double totalTax;
  final int invoices;

  factory GstSlabRow.fromJson(Map<String, dynamic> json) => GstSlabRow(
        slab: json['slab'] as String,
        taxableValue: asDouble(json['taxable_value']),
        cgst: asDouble(json['cgst']),
        sgst: asDouble(json['sgst']),
        totalTax: asDouble(json['total_tax']),
        invoices: json['invoices'] as int,
      );
}

/// Mirrors `reports.views.GstReportView`'s JSON.
class GstReport {
  const GstReport({
    required this.month,
    required this.taxableTurnover,
    required this.outputGst,
    required this.inputCredit,
    required this.netPayable,
    required this.slabs,
  });

  final String month;
  final double taxableTurnover;
  final double outputGst;
  final double inputCredit;
  final double netPayable;
  final List<GstSlabRow> slabs;

  factory GstReport.fromJson(Map<String, dynamic> json) => GstReport(
        month: json['month'] as String,
        taxableTurnover: asDouble(json['taxable_turnover']),
        outputGst: asDouble(json['output_gst']),
        inputCredit: asDouble(json['input_credit']),
        netPayable: asDouble(json['net_payable']),
        slabs: (json['slabs'] as List).map((e) => GstSlabRow.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// Mirrors `reports.serializers.StoreSettingsSerializer`'s JSON — the
/// seller's own GST profile, editable from the admin console's GST
/// settings panel and printed on every generated invoice/GSTR-3B summary.
class StoreGstSettings {
  const StoreGstSettings({required this.businessName, required this.address, required this.gstin});

  final String businessName;
  final String address;
  final String gstin;

  factory StoreGstSettings.fromJson(Map<String, dynamic> json) => StoreGstSettings(
        businessName: json['business_name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        gstin: json['gstin'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'business_name': businessName, 'address': address, 'gstin': gstin};
}

/// Mirrors `accounts.views.AdminCustomerListView`'s JSON.
class AdminCustomerRow {
  const AdminCustomerRow({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.ordersCount,
    required this.ltv,
    this.lastOrderAt,
    required this.tier,
  });

  final int id;
  final String? name;
  final String mobileNumber;
  final int ordersCount;
  final int ltv;
  final DateTime? lastOrderAt;
  final String tier;

  factory AdminCustomerRow.fromJson(Map<String, dynamic> json) => AdminCustomerRow(
        id: json['id'] as int,
        name: json['name'] as String?,
        mobileNumber: json['mobile_number'] as String,
        ordersCount: json['orders_count'] as int,
        ltv: json['ltv'] as int,
        lastOrderAt: json['last_order_at'] == null ? null : DateTime.parse(json['last_order_at'] as String),
        tier: json['tier'] as String,
      );
}

/// One day/week/month/year bucket of [DeliveredSalesReport].
class DeliveredSalesRow {
  const DeliveredSalesRow({
    required this.periodStart,
    required this.label,
    required this.orders,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.gst,
    required this.deliveryFee,
    required this.revenue,
    required this.codRevenue,
    required this.onlineRevenue,
  });

  final DateTime periodStart;
  final String label;
  final int orders;
  final int items;
  final int subtotal;
  final int discount;
  final int gst;
  final int deliveryFee;
  final int revenue;
  final int codRevenue;
  final int onlineRevenue;

  factory DeliveredSalesRow.fromJson(Map<String, dynamic> json) => DeliveredSalesRow(
        periodStart: DateTime.parse(json['period_start'] as String),
        label: json['label'] as String,
        orders: json['orders'] as int,
        items: json['items'] as int,
        subtotal: json['subtotal'] as int,
        discount: json['discount'] as int,
        gst: (asDouble(json['cgst']) + asDouble(json['sgst'])).round(),
        deliveryFee: json['delivery_fee'] as int,
        revenue: json['revenue'] as int,
        codRevenue: json['cod_revenue'] as int,
        onlineRevenue: json['online_revenue'] as int,
      );
}

/// Mirrors `DeliveredSalesReportView` — successfully delivered sales only,
/// grouped by `period` ('daily' | 'weekly' | 'monthly' | 'yearly').
class DeliveredSalesReport {
  const DeliveredSalesReport({
    required this.period,
    required this.start,
    required this.end,
    required this.orders,
    required this.items,
    required this.revenue,
    required this.avgOrderValue,
    required this.codRevenue,
    required this.onlineRevenue,
    required this.gst,
    this.bestPeriod,
    required this.rows,
  });

  final String period;
  final DateTime start;
  final DateTime end;
  final int orders;
  final int items;
  final int revenue;
  final int avgOrderValue;
  final int codRevenue;
  final int onlineRevenue;
  final int gst;
  final String? bestPeriod;
  final List<DeliveredSalesRow> rows;

  factory DeliveredSalesReport.fromJson(Map<String, dynamic> json) {
    final t = json['totals'] as Map<String, dynamic>;
    return DeliveredSalesReport(
      period: json['period'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      orders: t['orders'] as int,
      items: t['items'] as int,
      revenue: t['revenue'] as int,
      avgOrderValue: t['avg_order_value'] as int,
      codRevenue: t['cod_revenue'] as int,
      onlineRevenue: t['online_revenue'] as int,
      gst: (asDouble(t['cgst']) + asDouble(t['sgst'])).round(),
      bestPeriod: json['best_period'] as String?,
      rows: (json['rows'] as List).map((e) => DeliveredSalesRow.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
