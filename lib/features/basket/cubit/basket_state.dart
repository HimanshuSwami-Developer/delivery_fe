import 'package:equatable/equatable.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/models/zone_models.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';

/// A one-shot "tell the user what just happened" popup — set by
/// [BasketCubit] the instant an order/payment attempt resolves (placed,
/// paid, declined, cancelled, or errored) and cleared the moment the root
/// [BasketApp] widget has shown it, so every outcome is guaranteed exactly
/// one popup regardless of which screen is on top when it lands.
class PaymentPopup extends Equatable {
  const PaymentPopup({required this.title, required this.message, required this.success});

  final String title;
  final String message;
  final bool success;

  @override
  List<Object?> get props => [title, message, success];
}

/// Single immutable state for the whole Basket app, mirroring the source
/// design's one-component `state` object. It's deliberately one cohesive
/// class rather than split per-screen: the source app is genuinely one
/// connected flow (a shared cart, a shared back-stack, screens that read
/// each other's fields), so splitting state per screen would just move the
/// coupling into ad-hoc cross-cubit wiring instead of removing it.
///
/// Kept minimal/normalized — no derived data (totals, filtered lists,
/// decorated products) lives here. Those are computed on read by
/// `basket_selectors.dart` so [BasketCubit] never emits stale derived
/// values and widgets can select just the slice they need.
class BasketState extends Equatable {
  const BasketState({
    this.screen = BasketScreen.splash,
    this.history = const [],
    this.onboardSlide = 0,
    this.category = 'dairy',
    this.subcategory = 'Milk',
    this.view = CatalogView.grid,
    this.sheet = ActiveSheet.none,
    this.band = PriceBand.all,
    this.sort = SortOption.popularity,
    this.query = '',
    this.selectedProductId,
    this.pdpTab = PdpTab.description,
    this.cart = const {},
    this.wishlist = const {},
    this.phone = '',
    this.otp = '',
    this.authLoading = false,
    this.authError,
    this.name = '',
    this.email = '',
    this.referralCodeInput = '',
    this.myReferralCode,
    this.couponInput = '',
    this.appliedCoupon,
    this.couponMessage = 'Try FIRST50 on orders above ₹499.',
    this.selectedOrderId,
    this.addressId = 'home',
    this.gpsAddress,
    this.deliveryDay = 0,
    this.deliverySlotId = 'exp',
    this.paymentMethodId = 'qr',
    this.trackingStage = 0,
    this.newAddressTag = 'Home',
    this.addressSaving = false,
    this.addressFormError,
    this.cancelReason,
    this.cancelMode = CancelMode.cancel,
    this.apiCategories = const [],
    this.apiProducts = const [],
    this.catalogLoading = false,
    this.apiAddresses = const [],
    this.apiOrders = const [],
    this.ordersLoading = false,
    this.currentOrder,
    this.apiCoupons = const [],
    this.apiNotifications = const [],
    this.apiZones = const [],
    this.zoneId,
    this.apiBanners = const [],
    this.paymentPopup,
  });

  final BasketScreen screen;

  /// Back-stack of screens to return to on [BasketCubit.back]. Most
  /// navigation appends to it; a few checkout/payment transitions reset it
  /// outright to skip re-traversing intermediate steps — matching the
  /// source design exactly (see the cubit for where and why).
  final List<BasketScreen> history;

  final int onboardSlide;

  final String category;
  final String subcategory;
  final CatalogView view;
  final ActiveSheet sheet;
  final PriceBand band;
  final SortOption sort;

  final String query;

  final String? selectedProductId;
  final PdpTab pdpTab;

  final Map<String, int> cart;
  final Set<String> wishlist;

  final String phone;
  final String otp;
  final bool authLoading;
  final String? authError;

  /// Full name entered on the setup screen, sent as the profile name once
  /// OTP verification completes.
  final String name;

  /// Email entered on the setup screen (or later from the account screen).
  /// Optional, mirrors `Profile.email` server-side.
  final String email;

  /// Someone else's referral code typed on the setup screen — only
  /// meaningful on first-time signup (see `BasketCubit.finishSetup`).
  final String referralCodeInput;

  /// This account's own shareable referral code, server-generated and
  /// returned on the profile — null until the profile has been fetched.
  final String? myReferralCode;

  final String couponInput;
  final String? appliedCoupon;
  final String couponMessage;

  /// Selected past order id on the order-detail screen; null means "the
  /// live order" (which mirrors the current cart — see selectors).
  final String? selectedOrderId;

  final String addressId;

  /// Full formatted address (street, area, city, pincode) reverse-geocoded
  /// from the device's current GPS position — the Home header's address
  /// subtitle prefers this over [addressId]'s saved address when available
  /// (see `selectors.dart`'s `homeAddressSubtitle`); null until
  /// [BasketCubit.loadGpsLocation] resolves it (or fails/is denied — a
  /// silent, best-effort lookup).
  final String? gpsAddress;

  final int deliveryDay;
  final String deliverySlotId;
  final String paymentMethodId;

  /// 0-3 index into [BasketCatalog.trackingSteps].
  final int trackingStage;

  final String newAddressTag;

  /// True while [BasketCubit.submitNewAddress] is awaiting the API call —
  /// disables the "Save address" button so a slow network can't double-post.
  final bool addressSaving;

  /// Validation/API error from the last `submitNewAddress` attempt, shown
  /// inline on the address-edit form.
  final String? addressFormError;

  final String? cancelReason;
  final CancelMode cancelMode;

  // ── Live backend data (fetched via BasketApiBundle; see BasketCubit) ──

  final List<ApiCategory> apiCategories;
  final List<ApiProduct> apiProducts;
  final bool catalogLoading;

  final List<ApiAddress> apiAddresses;

  final List<ApiOrder> apiOrders;
  final bool ordersLoading;

  /// The order just placed (or most recently opened), kept separately from
  /// [apiOrders] so success/tracking screens have it the instant `place`
  /// returns, without waiting on a fresh `apiOrders` list fetch.
  final ApiOrder? currentOrder;

  final List<ApiCoupon> apiCoupons;
  final List<ApiNotification> apiNotifications;

  final List<ApiZone> apiZones;

  /// Zone orders are placed against — the app has no "pick your dark
  /// store" UI, so this is just the first open zone once [apiZones] loads.
  final int? zoneId;

  /// Home-carousel promo banners (`Banner.placement == 'home_carousel'`).
  final List<ApiBanner> apiBanners;

  /// Set once per order/payment outcome; see [PaymentPopup]. Null the rest
  /// of the time — [BasketCubit.clearPaymentPopup] resets it right after
  /// the root widget shows it.
  final PaymentPopup? paymentPopup;

  BasketState copyWith({
    BasketScreen? screen,
    List<BasketScreen>? history,
    int? onboardSlide,
    String? category,
    String? subcategory,
    CatalogView? view,
    ActiveSheet? sheet,
    PriceBand? band,
    SortOption? sort,
    String? query,
    String? selectedProductId,
    PdpTab? pdpTab,
    Map<String, int>? cart,
    Set<String>? wishlist,
    String? phone,
    String? otp,
    bool? authLoading,
    String? authError,
    bool clearAuthError = false,
    String? name,
    String? email,
    String? referralCodeInput,
    String? myReferralCode,
    String? couponInput,
    String? appliedCoupon,
    String? couponMessage,
    String? selectedOrderId,
    bool clearSelectedOrderId = false,
    String? addressId,
    String? gpsAddress,
    int? deliveryDay,
    String? deliverySlotId,
    String? paymentMethodId,
    int? trackingStage,
    String? newAddressTag,
    bool? addressSaving,
    String? addressFormError,
    bool clearAddressFormError = false,
    String? cancelReason,
    bool clearCancelReason = false,
    CancelMode? cancelMode,
    List<ApiCategory>? apiCategories,
    List<ApiProduct>? apiProducts,
    bool? catalogLoading,
    List<ApiAddress>? apiAddresses,
    List<ApiOrder>? apiOrders,
    bool? ordersLoading,
    ApiOrder? currentOrder,
    List<ApiCoupon>? apiCoupons,
    List<ApiNotification>? apiNotifications,
    List<ApiZone>? apiZones,
    int? zoneId,
    List<ApiBanner>? apiBanners,
    PaymentPopup? paymentPopup,
    bool clearPaymentPopup = false,
  }) {
    return BasketState(
      screen: screen ?? this.screen,
      history: history ?? this.history,
      onboardSlide: onboardSlide ?? this.onboardSlide,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      view: view ?? this.view,
      sheet: sheet ?? this.sheet,
      band: band ?? this.band,
      sort: sort ?? this.sort,
      query: query ?? this.query,
      selectedProductId: selectedProductId ?? this.selectedProductId,
      pdpTab: pdpTab ?? this.pdpTab,
      cart: cart ?? this.cart,
      wishlist: wishlist ?? this.wishlist,
      phone: phone ?? this.phone,
      otp: otp ?? this.otp,
      authLoading: authLoading ?? this.authLoading,
      authError: clearAuthError ? null : (authError ?? this.authError),
      name: name ?? this.name,
      email: email ?? this.email,
      referralCodeInput: referralCodeInput ?? this.referralCodeInput,
      myReferralCode: myReferralCode ?? this.myReferralCode,
      couponInput: couponInput ?? this.couponInput,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      couponMessage: couponMessage ?? this.couponMessage,
      selectedOrderId: clearSelectedOrderId ? null : (selectedOrderId ?? this.selectedOrderId),
      addressId: addressId ?? this.addressId,
      gpsAddress: gpsAddress ?? this.gpsAddress,
      deliveryDay: deliveryDay ?? this.deliveryDay,
      deliverySlotId: deliverySlotId ?? this.deliverySlotId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      trackingStage: trackingStage ?? this.trackingStage,
      newAddressTag: newAddressTag ?? this.newAddressTag,
      addressSaving: addressSaving ?? this.addressSaving,
      addressFormError: clearAddressFormError ? null : (addressFormError ?? this.addressFormError),
      cancelReason: clearCancelReason ? null : (cancelReason ?? this.cancelReason),
      cancelMode: cancelMode ?? this.cancelMode,
      apiCategories: apiCategories ?? this.apiCategories,
      apiProducts: apiProducts ?? this.apiProducts,
      catalogLoading: catalogLoading ?? this.catalogLoading,
      apiAddresses: apiAddresses ?? this.apiAddresses,
      apiOrders: apiOrders ?? this.apiOrders,
      ordersLoading: ordersLoading ?? this.ordersLoading,
      currentOrder: currentOrder ?? this.currentOrder,
      apiCoupons: apiCoupons ?? this.apiCoupons,
      apiNotifications: apiNotifications ?? this.apiNotifications,
      apiZones: apiZones ?? this.apiZones,
      zoneId: zoneId ?? this.zoneId,
      apiBanners: apiBanners ?? this.apiBanners,
      paymentPopup: clearPaymentPopup ? null : (paymentPopup ?? this.paymentPopup),
    );
  }

  @override
  List<Object?> get props => [
        screen,
        history,
        onboardSlide,
        category,
        subcategory,
        view,
        sheet,
        band,
        sort,
        query,
        selectedProductId,
        pdpTab,
        cart,
        wishlist,
        phone,
        otp,
        authLoading,
        authError,
        name,
        email,
        referralCodeInput,
        myReferralCode,
        couponInput,
        appliedCoupon,
        couponMessage,
        selectedOrderId,
        addressId,
        gpsAddress,
        deliveryDay,
        deliverySlotId,
        paymentMethodId,
        trackingStage,
        newAddressTag,
        addressSaving,
        addressFormError,
        cancelReason,
        cancelMode,
        apiCategories,
        apiProducts,
        catalogLoading,
        apiAddresses,
        apiOrders,
        ordersLoading,
        currentOrder,
        apiCoupons,
        apiNotifications,
        apiZones,
        zoneId,
        apiBanners,
        paymentPopup,
      ];
}
