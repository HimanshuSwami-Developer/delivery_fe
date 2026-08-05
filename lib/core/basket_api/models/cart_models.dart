import 'catalog_models.dart';

/// Mirrors `cart.serializers.CartItemSerializer`.
class ApiCartItem {
  const ApiCartItem({required this.id, required this.product, required this.qty, required this.amount});

  final int id;
  final ApiProduct product;
  final int qty;
  final int amount;

  factory ApiCartItem.fromJson(Map<String, dynamic> json) => ApiCartItem(
        id: json['id'] as int,
        product: ApiProduct.fromJson(json['product_detail'] as Map<String, dynamic>),
        qty: json['qty'] as int,
        amount: json['amount'] as int,
      );
}

/// Mirrors `cart.serializers.CartSerializer`.
class ApiCart {
  const ApiCart({
    required this.items,
    required this.couponCode,
    required this.subtotal,
    required this.mrpTotal,
    required this.discount,
    required this.deliveryFee,
    required this.itemCount,
    required this.total,
  });

  final List<ApiCartItem> items;
  final String? couponCode;
  final int subtotal;
  final int mrpTotal;
  final int discount;
  final int deliveryFee;
  final int itemCount;
  final int total;

  static const empty = ApiCart(
    items: [],
    couponCode: null,
    subtotal: 0,
    mrpTotal: 0,
    discount: 0,
    deliveryFee: 0,
    itemCount: 0,
    total: 0,
  );

  factory ApiCart.fromJson(Map<String, dynamic> json) => ApiCart(
        items: (json['items'] as List? ?? [])
            .map((e) => ApiCartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        couponCode: json['coupon_code'] as String?,
        subtotal: json['subtotal'] as int,
        mrpTotal: json['mrp_total'] as int,
        discount: json['discount'] as int,
        deliveryFee: json['delivery_fee'] as int,
        itemCount: json['item_count'] as int,
        total: json['total'] as int,
      );
}

/// Mirrors `cart.serializers.WishlistItemSerializer`.
class ApiWishlistItem {
  const ApiWishlistItem({required this.id, required this.product});

  final int id;
  final ApiProduct product;

  factory ApiWishlistItem.fromJson(Map<String, dynamic> json) => ApiWishlistItem(
        id: json['id'] as int,
        product: ApiProduct.fromJson(json['product_detail'] as Map<String, dynamic>),
      );
}
