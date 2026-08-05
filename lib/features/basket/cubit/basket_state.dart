import 'package:equatable/equatable.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/models/zone_models.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';

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
    this.couponInput = '',
    this.appliedCoupon,
    this.couponMessage = 'Try FIRST50 on orders above ₹499.',
    this.selectedOrderId,
    this.addressId = 'home',
    this.deliveryDay = 0,
    this.deliverySlotId = 'exp',
    this.paymentMethodId = 'upi',
    this.trackingStage = 0,
    this.newAddressTag = 'Home',
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

  final String couponInput;
  final String? appliedCoupon;
  final String couponMessage;

  /// Selected past order id on the order-detail screen; null means "the
  /// live order" (which mirrors the current cart — see selectors).
  final String? selectedOrderId;

  final String addressId;
  final int deliveryDay;
  final String deliverySlotId;
  final String paymentMethodId;

  /// 0-3 index into [BasketCatalog.trackingSteps].
  final int trackingStage;

  final String newAddressTag;
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
    String? couponInput,
    String? appliedCoupon,
    String? couponMessage,
    String? selectedOrderId,
    bool clearSelectedOrderId = false,
    String? addressId,
    int? deliveryDay,
    String? deliverySlotId,
    String? paymentMethodId,
    int? trackingStage,
    String? newAddressTag,
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
      couponInput: couponInput ?? this.couponInput,
      appliedCoupon: appliedCoupon ?? this.appliedCoupon,
      couponMessage: couponMessage ?? this.couponMessage,
      selectedOrderId: clearSelectedOrderId ? null : (selectedOrderId ?? this.selectedOrderId),
      addressId: addressId ?? this.addressId,
      deliveryDay: deliveryDay ?? this.deliveryDay,
      deliverySlotId: deliverySlotId ?? this.deliverySlotId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      trackingStage: trackingStage ?? this.trackingStage,
      newAddressTag: newAddressTag ?? this.newAddressTag,
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
        couponInput,
        appliedCoupon,
        couponMessage,
        selectedOrderId,
        addressId,
        deliveryDay,
        deliverySlotId,
        paymentMethodId,
        trackingStage,
        newAddressTag,
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
      ];
}
