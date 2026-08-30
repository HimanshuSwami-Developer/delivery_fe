/// Mirrors `promotions.serializers.CouponSerializer`.
class ApiCoupon {
  const ApiCoupon({
    required this.id,
    required this.code,
    required this.title,
    required this.minOrderValue,
    this.flatDiscount,
    this.percentDiscount,
    this.maxDiscount,
    this.validUntil,
    required this.terms,
    required this.isActive,
    required this.usedCount,
    required this.discountGiven,
    required this.isValidNow,
  });

  final int id;
  final String code;
  final String title;
  final int minOrderValue;
  final int? flatDiscount;
  final int? percentDiscount;
  final int? maxDiscount;
  final String? validUntil;
  final String terms;
  final bool isActive;
  final int usedCount;
  final int discountGiven;
  final bool isValidNow;

  factory ApiCoupon.fromJson(Map<String, dynamic> json) => ApiCoupon(
        id: json['id'] as int,
        code: json['code'] as String,
        title: json['title'] as String,
        minOrderValue: json['min_order_value'] as int,
        flatDiscount: json['flat_discount'] as int?,
        percentDiscount: json['percent_discount'] as int?,
        maxDiscount: json['max_discount'] as int?,
        validUntil: json['valid_until'] as String?,
        terms: json['terms'] as String? ?? '',
        isActive: json['is_active'] as bool,
        usedCount: json['used_count'] as int? ?? 0,
        discountGiven: json['discount_given'] as int? ?? 0,
        isValidNow: json['is_valid_now'] as bool? ?? true,
      );
}

/// Mirrors `promotions.serializers.BannerSerializer`.
class ApiBanner {
  const ApiBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.placement,
    this.categoryId,
    required this.linkScreen,
    required this.order,
    required this.isActive,
    required this.impressions,
  });

  final int id;
  final String title;
  final String imageUrl;
  final String placement;
  final int? categoryId;
  final String linkScreen;
  final int order;
  final bool isActive;
  final int impressions;

  factory ApiBanner.fromJson(Map<String, dynamic> json) => ApiBanner(
        id: json['id'] as int,
        title: json['title'] as String,
        imageUrl: json['image_url'] as String? ?? '',
        placement: json['placement'] as String,
        categoryId: json['category'] as int?,
        linkScreen: json['link_screen'] as String? ?? '',
        order: json['order'] as int? ?? 0,
        isActive: json['is_active'] as bool,
        impressions: json['impressions'] as int? ?? 0,
      );
}

/// Mirrors `promotions.serializers.FestivalSettingSerializer` — one row per
/// festival, admin-editable colours/motif/text and on/auto/off override for
/// the home header's festival theme. See
/// `features/basket/presentation/festival_theme.dart` for how this merges
/// over the app's built-in festival catalog.
class ApiFestivalSetting {
  const ApiFestivalSetting({
    required this.id,
    required this.key,
    required this.overrideMode,
    this.startsOn,
    this.endsOn,
    required this.accentColor,
    required this.gradientStart,
    required this.gradientEnd,
    required this.motif,
    required this.greetingText,
    required this.popupEnabled,
    required this.popupTitle,
    required this.popupMessage,
  });

  final int id;
  final String key;

  /// `'auto'` | `'force_on'` | `'force_off'`.
  final String overrideMode;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String accentColor;
  final String gradientStart;
  final String gradientEnd;

  /// `'diyaLights'` | `'colorSplash'` | `'snowfall'` | `'confetti'`.
  final String motif;
  final String greetingText;
  final bool popupEnabled;
  final String popupTitle;
  final String popupMessage;

  factory ApiFestivalSetting.fromJson(Map<String, dynamic> json) => ApiFestivalSetting(
        id: json['id'] as int,
        key: json['key'] as String,
        overrideMode: json['override_mode'] as String? ?? 'auto',
        startsOn: json['starts_on'] != null ? DateTime.parse(json['starts_on'] as String) : null,
        endsOn: json['ends_on'] != null ? DateTime.parse(json['ends_on'] as String) : null,
        accentColor: json['accent_color'] as String? ?? '',
        gradientStart: json['gradient_start'] as String? ?? '',
        gradientEnd: json['gradient_end'] as String? ?? '',
        motif: json['motif'] as String? ?? '',
        greetingText: json['greeting_text'] as String? ?? '',
        popupEnabled: json['popup_enabled'] as bool? ?? true,
        popupTitle: json['popup_title'] as String? ?? '',
        popupMessage: json['popup_message'] as String? ?? '',
      );
}

/// Mirrors `promotions.serializers.NotificationSerializer`.
class ApiNotification {
  const ApiNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    this.sentAt,
    required this.sentCount,
    required this.openedCount,
  });

  final int id;
  final String title;
  final String body;
  final String audience;
  final DateTime? sentAt;
  final int sentCount;
  final int openedCount;

  factory ApiNotification.fromJson(Map<String, dynamic> json) => ApiNotification(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        audience: json['audience'] as String,
        sentAt: json['sent_at'] == null ? null : DateTime.parse(json['sent_at'] as String),
        sentCount: json['sent_count'] as int? ?? 0,
        openedCount: json['opened_count'] as int? ?? 0,
      );
}
