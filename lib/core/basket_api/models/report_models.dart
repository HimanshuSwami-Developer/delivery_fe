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
  final int taxableValue;
  final int cgst;
  final int sgst;
  final int totalTax;
  final int invoices;

  factory GstSlabRow.fromJson(Map<String, dynamic> json) => GstSlabRow(
        slab: json['slab'] as String,
        taxableValue: json['taxable_value'] as int,
        cgst: json['cgst'] as int,
        sgst: json['sgst'] as int,
        totalTax: json['total_tax'] as int,
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
  final int taxableTurnover;
  final int outputGst;
  final int inputCredit;
  final int netPayable;
  final List<GstSlabRow> slabs;

  factory GstReport.fromJson(Map<String, dynamic> json) => GstReport(
        month: json['month'] as String,
        taxableTurnover: json['taxable_turnover'] as int,
        outputGst: json['output_gst'] as int,
        inputCredit: json['input_credit'] as int,
        netPayable: json['net_payable'] as int,
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
