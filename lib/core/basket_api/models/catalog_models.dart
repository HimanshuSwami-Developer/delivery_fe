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

/// Mirrors `catalog.serializers.SubcategorySerializer` — the admin
/// console's own CRUD shape (id + real `categoryId`), distinct from
/// [ApiCategory.subs] which is just a list of names with no id, so it
/// can't be edited/deleted individually.
class ApiSubcategory {
  const ApiSubcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.order,
  });

  final int id;
  final int categoryId;
  final String name;
  final String imageUrl;
  final int order;

  factory ApiSubcategory.fromJson(Map<String, dynamic> json) => ApiSubcategory(
        id: json['id'] as int,
        categoryId: json['category'] as int,
        name: json['name'] as String,
        imageUrl: json['image_url'] as String? ?? '',
        order: json['order'] as int? ?? 0,
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

/// Mirrors `catalog.serializers.ProductReviewSerializer`.
class ApiProductReview {
  const ApiProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String? userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory ApiProductReview.fromJson(Map<String, dynamic> json) => ApiProductReview(
        id: json['id'] as int,
        userId: json['user'] as int,
        userName: json['user_name'] as String?,
        rating: json['rating'] as int,
        comment: json['comment'] as String? ?? '',
        createdAt: DateTime.parse(json['created_at'] as String),
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
    int? sellingPrice,
    required this.discountPct,
    required this.rating,
    required this.ratingsCount,
    required this.isOutOfStock,
    this.isActive = true,
    required this.mainImageUrl,
    this.description,
    this.hsnCode,
    this.gstSlab,
    this.gstRateId,
    this.gstRateName,
    this.cgstPct = 0,
    this.sgstPct = 0,
    this.images = const [],
    this.reviews = const [],
  }) : sellingPrice = sellingPrice ?? price;

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
  /// Admin-entered base price, before GST.
  final int price;

  /// What the customer sees and pays: [price] + CGST + SGST, in whole
  /// rupees (computed server-side as `selling_price`).
  final int sellingPrice;
  final int discountPct;
  final double rating;
  final int ratingsCount;
  final bool isOutOfStock;
  /// Live/Pause — a paused product (`is_active=false`) is hidden from the
  /// customer-facing catalog server-side but stays visible/editable here.
  final bool isActive;
  final String mainImageUrl;
  final String? description;
  final String? hsnCode;
  final String? gstSlab;
  final int? gstRateId;
  final String? gstRateName;
  final double cgstPct;
  final double sgstPct;
  final List<ApiProductImage> images;

  /// Only present on the detail fetch (`ProductDetailSerializer` nests
  /// these); empty on the lightweight list/grid shape.
  final List<ApiProductReview> reviews;

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
        sellingPrice: json['selling_price'] as int?,
        discountPct: json['discount_pct'] as int? ?? 0,
        rating: asDouble(json['rating']),
        ratingsCount: json['ratings_count'] as int? ?? 0,
        isOutOfStock: json['is_out_of_stock'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        mainImageUrl: json['main_image_url'] as String? ?? '',
        description: json['description'] as String?,
        hsnCode: json['hsn_code'] as String?,
        gstSlab: json['gst_slab'] as String?,
        gstRateId: json['gst_rate'] as int?,
        gstRateName: json['gst_rate_name'] as String?,
        cgstPct: asDouble(json['cgst_pct']),
        sgstPct: asDouble(json['sgst_pct']),
        images: (json['images'] as List? ?? [])
            .map((e) => ApiProductImage.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviews: (json['reviews'] as List? ?? [])
            .map((e) => ApiProductReview.fromJson(e as Map<String, dynamic>))
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
    required this.mainImageUrl,
    required this.categoryKey,
    required this.categoryName,
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
  final String mainImageUrl;
  final String categoryKey;
  final String categoryName;
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
        mainImageUrl: json['main_image_url'] as String? ?? '',
        categoryKey: json['category'] as String? ?? '',
        categoryName: json['category_name'] as String? ?? '',
        onHand: json['on_hand'] as int,
        reserved: json['reserved'] as int,
        reorderLevel: json['reorder_level'] as int,
        maxStock: json['max_stock'] as int,
        state: json['state'] as String,
      );
}

/// Mirrors `ProductStockViewSet.summary` — totals across *every* stock row,
/// independent of whatever filter/page the table is currently showing.
class StockSummary {
  const StockSummary({required this.tracked, required this.belowReorder, required this.outOfStock, required this.onHandTotal});

  final int tracked;
  final int belowReorder;
  final int outOfStock;
  final int onHandTotal;

  factory StockSummary.fromJson(Map<String, dynamic> json) => StockSummary(
        tracked: json['tracked'] as int,
        belowReorder: json['below_reorder'] as int,
        outOfStock: json['out_of_stock'] as int,
        onHandTotal: json['on_hand_total'] as int,
      );
}


/// Mirrors `catalog.serializers.GstRateSerializer` — an admin-defined
/// CGST + SGST rate picked per product.
class ApiGstRate {
  const ApiGstRate({
    required this.id,
    required this.name,
    required this.cgstPct,
    required this.sgstPct,
    this.productCount = 0,
  });

  final int id;
  final String name;
  final double cgstPct;
  final double sgstPct;
  final int productCount;

  double get totalPct => cgstPct + sgstPct;

  factory ApiGstRate.fromJson(Map<String, dynamic> json) => ApiGstRate(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        cgstPct: asDouble(json['cgst_pct']),
        sgstPct: asDouble(json['sgst_pct']),
        productCount: json['product_count'] as int? ?? 0,
      );
}

/// Formats a GST percentage without trailing zeros: 2.5 -> "2.5", 9.0 -> "9".
String gstPctLabel(double pct) {
  final s = pct.toStringAsFixed(2);
  return s.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Customer price for a base [price] under [rate] — mirrors the server's
/// `Product.selling_price` (round half up to whole rupees).
int sellingPriceFor(int price, double totalPct) => (price * (100 + totalPct) / 100 + 1e-9).round();
