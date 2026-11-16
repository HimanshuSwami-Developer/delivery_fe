import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:flutter/material.dart';

class BasketCategory {
  const BasketCategory({
    required this.key,
    required this.name,
    required this.subs,
    required this.count,
    this.imageUrl = '',
  });

  final String key;
  final String name;
  final List<String> subs;
  final int count;

  /// Cloudinary-hosted photo (`Category.image_url` on the backend) — shown
  /// on the category's home/category-grid tile. Empty when the admin
  /// hasn't uploaded one yet, in which case the tile falls back to a
  /// generic placeholder icon.
  final String imageUrl;

  factory BasketCategory.fromApi(ApiCategory c) =>
      BasketCategory(key: c.key, name: c.name, subs: c.subs, count: c.productCount, imageUrl: c.imageUrl);
}

class BasketProduct {
  const BasketProduct({
    required this.id,
    required this.name,
    required this.pack,
    required this.price,
    required this.mrp,
    required this.cat,
    required this.sub,
    required this.brand,
    required this.rating,
    required this.ratingsCount,
    this.oos = false,
    this.imageUrl = '',
    this.images = const [],
    this.reviews = const [],
    this.bestBefore = '',
    this.expiryDate,
  });

  final String id;
  final String name;
  final String pack;
  final int price;
  final int mrp;
  final String cat;
  final String sub;
  final String brand;
  final double rating;
  final int ratingsCount;
  final bool oos;

  /// Cloudinary-hosted photo (`Product.main_image_url` on the backend).
  /// Empty when the admin hasn't uploaded one yet, in which case product
  /// cards fall back to a generic placeholder.
  final String imageUrl;

  /// Extra PDP gallery photos (`ProductImage` rows on the backend), beyond
  /// [imageUrl]. Only populated once the full product detail has loaded
  /// (list/card screens fetch the lighter shape that omits these) — see
  /// [galleryImages].
  final List<String> images;

  /// Everything the PDP slider should show: the gallery photos if the admin
  /// added any, else just [imageUrl] (or nothing, if the product has no
  /// photo at all yet).
  List<String> get galleryImages => images.isNotEmpty ? images : (imageUrl.isEmpty ? const [] : [imageUrl]);

  /// Only populated once the full product detail has loaded — see [images].
  final List<ApiProductReview> reviews;

  /// Shelf life as printed on the pack ("6 months from packaging"); empty
  /// when the admin hasn't set one.
  final String bestBefore;

  /// Expiry of the batch currently in stock, if the admin set one.
  final DateTime? expiryDate;

  int get discountPct => (100 * (1 - price / mrp)).round();

  /// [id] is the numeric Django pk stringified — every place in this app
  /// that keys a product (cart map, wishlist set, order line lookups)
  /// already uses `String` ids, so the backend's `int` id is converted
  /// once here rather than threading `int`/`String` both ways.
  factory BasketProduct.fromApi(ApiProduct p) => BasketProduct(
        id: p.id.toString(),
        name: p.name,
        pack: p.pack,
        price: p.sellingPrice,
        mrp: p.mrp,
        cat: p.cat,
        sub: p.sub ?? '',
        brand: p.brand,
        rating: p.rating,
        ratingsCount: p.ratingsCount,
        oos: p.isOutOfStock,
        imageUrl: p.mainImageUrl,
        images: [for (final img in p.images) img.imageUrl],
        reviews: p.reviews,
        bestBefore: p.bestBefore,
        expiryDate: p.expiryDate,
      );
}

class BasketCoupon {
  const BasketCoupon({
    required this.code,
    required this.min,
    required this.label,
    this.off,
    this.pct,
  });

  final String code;
  final int min;
  final String label;
  final int? off;
  final int? pct;

  int discountFor(int subtotal) {
    if (pct != null) return (subtotal * pct! / 100).round();
    return off ?? 0;
  }
}

class OnboardSlide {
  const OnboardSlide({
    required this.title,
    required this.body,
    required this.tint,
  });

  final String title;
  final String body;

  /// Page background while this slide is showing — each slide gets its own
  /// warm ivory/navy-family wash, cross-faded on swipe.
  final Color tint;
}

class AccountRow {
  const AccountRow({
    required this.icon,
    required this.title,
    required this.sub,
    required this.target,
  });

  final String icon;
  final String title;
  final String sub;
  final BasketScreen target;
}

class Address {
  const Address({
    required this.id,
    required this.label,
    required this.tag,
    required this.line,
    required this.eta,
  });

  final String id;
  final String label;
  final String tag;
  final String line;
  final int eta;

  /// [eta] has no per-address backend equivalent — pass a reasonable
  /// generic default.
  factory Address.fromApi(ApiAddress a, {int eta = 15}) {
    final type = a.addressType.isEmpty ? 'other' : a.addressType;
    final label = type[0].toUpperCase() + type.substring(1);
    return Address(
      id: a.id,
      label: label,
      tag: a.isDefault ? 'Default' : label,
      line: [
        a.addressLine1,
        if ((a.addressLine2 ?? '').isNotEmpty) a.addressLine2!,
        a.city,
        if (a.pincode.isNotEmpty) a.pincode,
      ].where((s) => s.isNotEmpty).join(', '),
      eta: eta,
    );
  }
}

class DeliveryDay {
  const DeliveryDay(this.label, this.date);

  final String label;
  final String date;
}

class DeliverySlot {
  const DeliverySlot({
    required this.id,
    required this.label,
    required this.sub,
    required this.fee,
  });

  final String id;
  final String label;
  final String sub;

  /// 'FREE' or a formatted amount like '₹19' — display text, not a number,
  /// matching the source design's `SLOTS[].fee`.
  final String fee;
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.sub,
    required this.icon,
  });

  final String id;
  final String name;
  final String sub;
  final String icon;
}

class TimelineStep {
  const TimelineStep(this.title, this.sub);

  final String title;
  final String sub;
}

class OrderHistoryEntry {
  const OrderHistoryEntry({
    required this.id,
    required this.date,
    required this.status,
    required this.live,
    required this.productIds,
  });

  final String id;
  final String date;

  /// 'On the way' | 'Delivered' | 'Cancelled'
  final String status;
  final bool live;
  final List<String> productIds;
}

class NotificationItem {
  const NotificationItem(this.icon, this.title, this.body, this.time);

  final String icon;
  final String title;
  final String body;
  final String time;
}

class CouponCard {
  const CouponCard({
    required this.code,
    required this.title,
    required this.terms,
  });

  final String code;
  final String title;
  final String terms;
}
