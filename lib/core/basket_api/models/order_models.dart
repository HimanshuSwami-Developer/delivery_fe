import 'package:fastswipe/core/basket_api/json_utils.dart';

/// Mirrors `orders.serializers.StoreLocationSerializer` — the fixed
/// pickup point the backend hardcodes in `orders/views.py`.
class ApiStoreLocation {
  const ApiStoreLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory ApiStoreLocation.fromJson(Map<String, dynamic> json) => ApiStoreLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}

/// Mirrors `orders.serializers.OrderItemSerializer`.
class ApiOrderItem {
  const ApiOrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pack,
    required this.rate,
    required this.gstSlab,
    required this.qty,
    required this.amount,
    this.unitPrice,
    this.cgstPct = 0,
    this.sgstPct = 0,
    this.cgst = 0,
    this.sgst = 0,
    int? lineTotal,
  }) : lineTotal = lineTotal ?? 0;

  final int id;
  final int productId;
  final String productName;
  final String pack;
  /// Base (pre-GST) price per unit.
  final int rate;
  final String gstSlab;
  final int qty;

  /// Taxable (pre-GST) value of this line, to the paisa.
  final double amount;

  /// GST-inclusive price per unit the customer paid; null on orders placed
  /// before GST-inclusive pricing.
  final int? unitPrice;
  final double cgstPct;
  final double sgstPct;
  final double cgst;
  final double sgst;

  /// GST-inclusive amount charged for this line (= amount + cgst + sgst).
  final int lineTotal;

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) => ApiOrderItem(
        id: json['id'] as int,
        productId: json['product'] as int,
        productName: json['product_name'] as String,
        pack: json['pack'] as String? ?? '',
        rate: json['rate'] as int,
        gstSlab: json['gst_slab'] as String? ?? '5',
        qty: json['qty'] as int,
        amount: asDouble(json['amount']),
        unitPrice: json['unit_price'] as int?,
        cgstPct: asDouble(json['cgst_pct']),
        sgstPct: asDouble(json['sgst_pct']),
        cgst: asDouble(json['cgst']),
        sgst: asDouble(json['sgst']),
        lineTotal: (json['line_total'] as num?)?.toInt() ?? asDouble(json['amount']).round(),
      );
}

/// Mirrors `orders.serializers.OrderListSerializer` / `OrderDetailSerializer`
/// (detail-only fields are nullable and populated from `/orders/{id}/`).
class ApiOrder {
  const ApiOrder({
    required this.id,
    required this.orderNumber,
    this.invoiceNumber,
    required this.status,
    required this.paymentMode,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    this.taxableValue = 0,
    required this.cgst,
    required this.sgst,
    required this.deliveryFee,
    required this.total,
    required this.address,
    required this.createdAt,
    this.paymentStatus = 'pending',
    this.paymentScreenshotUrl,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.customerName,
    this.customerMobile,
    this.latitude,
    this.longitude,
    this.items = const [],
    this.couponCode,
    this.gstin,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    this.deliverySlotDate,
    this.deliverySlotLabel,
    this.packedAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  final int id;
  final String orderNumber;

  /// GST invoice number, e.g. LTC/26-27/0001 — null on orders placed
  /// before the invoice series existed.
  final String? invoiceNumber;

  /// 'new' | 'packed' | 'out_for_delivery' | 'delivered' | 'cancelled'
  final String status;
  final String paymentMode;
  final int itemCount;
  final int subtotal;
  final int discount;
  /// Pre-GST value of the items; [cgst]/[sgst] are the tax inside the
  /// GST-inclusive [subtotal] — all to the paisa.
  final double taxableValue;
  final double cgst;
  final double sgst;
  final int deliveryFee;
  final int total;
  final String address;
  final DateTime createdAt;

  /// 'pending' | 'paid' | 'failed'.
  final String paymentStatus;

  /// Set only for a `payment_mode: 'qr'` order — the Cloudinary URL of the
  /// screenshot the customer uploaded as proof of their UPI payment, kept
  /// pending an admin's manual review.
  final String? paymentScreenshotUrl;

  final int? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? customerName;
  final String? customerMobile;

  /// Drop-pin for the delivery partner's map view — null for orders placed
  /// before this was captured, or without a saved address that had one.
  final double? latitude;
  final double? longitude;

  final List<ApiOrderItem> items;
  final String? couponCode;
  final String? gstin;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final String? deliverySlotDate;
  final String? deliverySlotLabel;
  final DateTime? packedAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  static DateTime? _dt(dynamic v) => v == null ? null : DateTime.parse(v as String);

  factory ApiOrder.fromJson(Map<String, dynamic> json) => ApiOrder(
        id: json['id'] as int,
        orderNumber: json['order_number'] as String,
        invoiceNumber: json['invoice_number'] as String?,
        status: json['status'] as String,
        paymentMode: json['payment_mode'] as String,
        itemCount: json['item_count'] as int? ?? 0,
        subtotal: json['subtotal'] as int,
        discount: json['discount'] as int,
        taxableValue: asDouble(json['taxable_value']),
        cgst: asDouble(json['cgst']),
        sgst: asDouble(json['sgst']),
        deliveryFee: json['delivery_fee'] as int,
        total: json['total'] as int,
        address: json['address'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
        paymentStatus: json['payment_status'] as String? ?? 'pending',
        paymentScreenshotUrl: json['payment_screenshot_url'] as String?,
        deliveryPartnerId: json['delivery_partner'] as int?,
        deliveryPartnerName: json['delivery_partner_name'] as String?,
        customerName: json['customer_name'] as String?,
        customerMobile: json['customer_mobile'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        items: (json['items'] as List? ?? [])
            .map((e) => ApiOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        couponCode: json['coupon_code'] as String?,
        gstin: json['gstin'] as String?,
        addressLine1: json['address_line1'] as String?,
        addressLine2: json['address_line2'] as String?,
        city: json['city'] as String?,
        state: json['state'] as String?,
        pincode: json['pincode'] as String?,
        deliverySlotDate: json['delivery_slot_date'] as String?,
        deliverySlotLabel: json['delivery_slot_label'] as String?,
        packedAt: _dt(json['packed_at']),
        outForDeliveryAt: _dt(json['out_for_delivery_at']),
        deliveredAt: _dt(json['delivered_at']),
        cancelledAt: _dt(json['cancelled_at']),
      );
}

/// Mirrors `orders.serializers.OrderTrackingSerializer` — the lightweight
/// snapshot the live tracking map polls (`/orders/{id}/tracking/`).
class ApiOrderTracking {
  const ApiOrderTracking({
    required this.id,
    required this.status,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.latitude,
    this.longitude,
    this.riderLatitude,
    this.riderLongitude,
    this.riderHeading,
    this.riderLocationUpdatedAt,
  });

  final int id;
  final String status;
  final int? deliveryPartnerId;
  final String? deliveryPartnerName;

  /// Delivery drop-pin, if the order was placed against one.
  final double? latitude;
  final double? longitude;

  /// Rider's last reported GPS fix — null until the rider app has sent one
  /// while the order is out for delivery.
  final double? riderLatitude;
  final double? riderLongitude;
  final double? riderHeading;
  final DateTime? riderLocationUpdatedAt;

  bool get hasRiderLocation => riderLatitude != null && riderLongitude != null;

  factory ApiOrderTracking.fromJson(Map<String, dynamic> json) => ApiOrderTracking(
        id: json['id'] as int,
        status: json['status'] as String,
        deliveryPartnerId: json['delivery_partner'] as int?,
        deliveryPartnerName: json['delivery_partner_name'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        riderLatitude: (json['rider_latitude'] as num?)?.toDouble(),
        riderLongitude: (json['rider_longitude'] as num?)?.toDouble(),
        riderHeading: (json['rider_heading'] as num?)?.toDouble(),
        riderLocationUpdatedAt: ApiOrder._dt(json['rider_location_updated_at']),
      );
}

/// Mirrors `reports.serializers.DeliverySettingsSerializer` — the
/// admin-controlled delivery fee and free-delivery threshold, served
/// publicly at `/orders/delivery_settings/` and edited at
/// `/admin/reports/delivery-settings/`.
class ApiDeliverySettings {
  const ApiDeliverySettings({
    required this.deliveryFee,
    required this.freeDeliveryEnabled,
    required this.freeDeliveryAbove,
  });

  /// Used until the real settings load — matches the backend defaults.
  static const fallback = ApiDeliverySettings(deliveryFee: 19, freeDeliveryEnabled: true, freeDeliveryAbove: 199);

  final int deliveryFee;
  final bool freeDeliveryEnabled;
  final int freeDeliveryAbove;

  /// Same rule as `StoreSettings.delivery_fee_for` server-side.
  int feeFor(int itemTotal) {
    if (itemTotal <= 0) return 0;
    if (freeDeliveryEnabled && itemTotal >= freeDeliveryAbove) return 0;
    return deliveryFee;
  }

  ApiDeliverySettings copyWith({int? deliveryFee, bool? freeDeliveryEnabled, int? freeDeliveryAbove}) =>
      ApiDeliverySettings(
        deliveryFee: deliveryFee ?? this.deliveryFee,
        freeDeliveryEnabled: freeDeliveryEnabled ?? this.freeDeliveryEnabled,
        freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      );

  factory ApiDeliverySettings.fromJson(Map<String, dynamic> json) => ApiDeliverySettings(
        deliveryFee: json['delivery_fee'] as int,
        freeDeliveryEnabled: json['free_delivery_enabled'] as bool? ?? true,
        freeDeliveryAbove: json['free_delivery_above'] as int,
      );

  Map<String, dynamic> toJson() => {
        'delivery_fee': deliveryFee,
        'free_delivery_enabled': freeDeliveryEnabled,
        'free_delivery_above': freeDeliveryAbove,
      };
}
