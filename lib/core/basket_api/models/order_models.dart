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
  });

  final int id;
  final int productId;
  final String productName;
  final String pack;
  final int rate;
  final String gstSlab;
  final int qty;
  final int amount;

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) => ApiOrderItem(
        id: json['id'] as int,
        productId: json['product'] as int,
        productName: json['product_name'] as String,
        pack: json['pack'] as String? ?? '',
        rate: json['rate'] as int,
        gstSlab: json['gst_slab'] as String? ?? '5',
        qty: json['qty'] as int,
        amount: json['amount'] as int,
      );
}

/// Mirrors `orders.serializers.OrderListSerializer` / `OrderDetailSerializer`
/// (detail-only fields are nullable and populated from `/orders/{id}/`).
class ApiOrder {
  const ApiOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentMode,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
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

  /// 'new' | 'packed' | 'out_for_delivery' | 'delivered' | 'cancelled'
  final String status;
  final String paymentMode;
  final int itemCount;
  final int subtotal;
  final int discount;
  final int cgst;
  final int sgst;
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
        status: json['status'] as String,
        paymentMode: json['payment_mode'] as String,
        itemCount: json['item_count'] as int? ?? 0,
        subtotal: json['subtotal'] as int,
        discount: json['discount'] as int,
        cgst: json['cgst'] as int,
        sgst: json['sgst'] as int,
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
