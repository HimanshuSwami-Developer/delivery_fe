import 'package:fastswipe/core/basket_api/json_utils.dart';

/// Mirrors `catalog.serializers.CategorySerializer`.
class ApiCategory {
  const ApiCategory({
    required this.id,
    required this.key,
    required this.name,
    required this.imageUrl,
    required this.order,
    required this.subs,
    required this.productCount,
  });

  final int id;
  final String key;
  final String name;
  final String imageUrl;
  final int order;
  final List<String> subs;
  final int productCount;

  factory ApiCategory.fromJson(Map<String, dynamic> json) => ApiCategory(
        id: json['id'] as int,
        key: json['key'] as String,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        subs: (json['subs'] as List? ?? []).map((e) => e.toString()).toList(),
        productCount: json['product_count'] as int? ?? 0,
      );
}

/// Mirrors `catalog.serializers.ProductImageSerializer`.
class ApiProductImage {
  const ApiProductImage({required this.id, required this.imageUrl, required this.order});

  final int id;
  final String imageUrl;
  final int order;

  factory ApiProductImage.fromJson(Map<String, dynamic> json) => ApiProductImage(
        id: json['id'] as int,
        imageUrl: json['image_url'] as String,
        order: json['order'] as int? ?? 0,
      );
}

/// Mirrors `catalog.serializers.ProductListSerializer` (+ the extra detail
/// fields when fetched via `ProductDetailSerializer`, all nullable here).
class ApiProduct {
  const ApiProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.cat,
    this.sub,
    required this.categoryId,
    this.subcategoryId,
    required this.pack,
    required this.sku,
    required this.mrp,
    required this.price,
    required this.discountPct,
    required this.rating,
    required this.ratingsCount,
    required this.isOutOfStock,
    required this.mainImageUrl,
    this.description,
    this.hsnCode,
    this.gstSlab,
    this.images = const [],
  });

  final int id;
  final String name;
  final String brand;
  final String cat;
  final String? sub;
  final int categoryId;
  final int? subcategoryId;
  final String pack;
  final String sku;
  final int mrp;
  final int price;
  final int discountPct;
  final double rating;
  final int ratingsCount;
  final bool isOutOfStock;
  final String mainImageUrl;
  final String? description;
  final String? hsnCode;
  final String? gstSlab;
  final List<ApiProductImage> images;

  factory ApiProduct.fromJson(Map<String, dynamic> json) => ApiProduct(
        id: json['id'] as int,
        name: json['name'] as String,
        brand: json['brand'] as String? ?? '',
        cat: json['cat'] as String? ?? '',
        sub: json['sub'] as String?,
        categoryId: json['category'] as int,
        subcategoryId: json['subcategory'] as int?,
        pack: json['pack'] as String? ?? '',
        sku: json['sku'] as String,
        mrp: json['mrp'] as int,
        price: json['price'] as int,
        discountPct: json['discount_pct'] as int? ?? 0,
        rating: asDouble(json['rating']),
        ratingsCount: json['ratings_count'] as int? ?? 0,
        isOutOfStock: json['is_out_of_stock'] as bool? ?? false,
        mainImageUrl: json['main_image_url'] as String? ?? '',
        description: json['description'] as String?,
        hsnCode: json['hsn_code'] as String?,
        gstSlab: json['gst_slab'] as String?,
        images: (json['images'] as List? ?? [])
            .map((e) => ApiProductImage.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Mirrors `catalog.serializers.ProductStockSerializer`.
class ApiProductStock {
  const ApiProductStock({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sku,
    required this.pack,
    required this.zoneId,
    required this.zoneName,
    required this.onHand,
    required this.reserved,
    required this.reorderLevel,
    required this.maxStock,
    required this.state,
  });

  final int id;
  final int productId;
  final String productName;
  final String sku;
  final String pack;
  final int zoneId;
  final String zoneName;
  final int onHand;
  final int reserved;
  final int reorderLevel;
  final int maxStock;

  /// 'healthy' | 'low' | 'out_of_stock'
  final String state;

  factory ApiProductStock.fromJson(Map<String, dynamic> json) => ApiProductStock(
        id: json['id'] as int,
        productId: json['product'] as int,
        productName: json['product_name'] as String,
        sku: json['sku'] as String,
        pack: json['pack'] as String? ?? '',
        zoneId: json['zone'] as int,
        zoneName: json['zone_name'] as String,
        onHand: json['on_hand'] as int,
        reserved: json['reserved'] as int,
        reorderLevel: json['reorder_level'] as int,
        maxStock: json['max_stock'] as int,
        state: json['state'] as String,
      );
}
