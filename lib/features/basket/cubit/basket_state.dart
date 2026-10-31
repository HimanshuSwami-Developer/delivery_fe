import 'package:equatable/equatable.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/models/support_models.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/festival_theme.dart';

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
    this.myUserId,
    this.loyaltyPoints = 0,
    this.apiReferralSummary,
    this.apiLoyaltySummary,
    this.redeemSubmitting = false,
    this.redeemMessage,
    this.role = 'customer',
    this.couponInput = '',
    this.appliedCoupon,
    this.couponMessage = '',
    this.selectedOrderId,
    this.addressId = 'home',
    this.gpsAddress,
    this.gpsDraft,
    this.deliveryDay = 0,
    this.deliverySlotId = 'exp',
    this.paymentMethodId = 'qr',
    this.trackingStage = 0,
    this.newAddressTag = 'Home',
    this.addressSaving = false,
    this.addressFormError,
    this.profileSaving = false,
    this.profileFormError,
    this.reviewRatingInput = 0,
    this.reviewCommentInput = '',
    this.reviewSubmitting = false,
    this.reviewFormError,
    this.deliveryActionLoading = false,
    this.deliveryActionError,
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
    this.deliverySettings = ApiDeliverySettings.fallback,
    this.apiNotifications = const [],
    this.apiBanners = const [],
    this.apiFestivalSettings = const [],
    this.apiSupportConfig,
    this.apiSupportFaqs = const [],
    this.paymentPopup,
    this.festivalPopup,
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

  /// `ApiProfile.id` — null until the profile has been fetched. Used to
  /// tell "my review" apart from other customers' on a product's review
  /// list (see `BasketCubit.submitProductReview`).
  final int? myUserId;

  /// Mirrors `Profile.loyalty_points` — kept in sync on every profile
  /// fetch/edit; [BasketCubit.loadLoyalty]/[redeemLoyaltyPoints] also
  /// update it directly so the balance shown elsewhere (e.g. the account
  /// screen) doesn't need a full profile refetch after redeeming.
  final int loyaltyPoints;

  /// Who signed up with my code + what each one earned me — null until
  /// [BasketCubit.loadReferrals] resolves.
  final ReferralSummary? apiReferralSummary;

  /// Points balance + transaction history — null until
  /// [BasketCubit.loadLoyalty] resolves.
  final LoyaltySummary? apiLoyaltySummary;

  /// True while [BasketCubit.redeemLoyaltyPoints] is awaiting the API call.
  final bool redeemSubmitting;

  /// Success/error feedback from the last redeem attempt, shown inline on
  /// the loyalty screen.
  final String? redeemMessage;

  /// 'customer' | 'delivery_boy' | 'admin' — mirrors `Profile.role`. Only
  /// used to decide whether the "Deliveries" tab shows; every other screen
  /// in this (customer-facing) app is role-agnostic.
  final String role;

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

  /// Unsaved address built from the same GPS fix as [gpsAddress] (with
  /// lat/lng, city, state, pincode). Checkout offers it as the
  /// "Current location" option (`addressId == kGpsAddressId`); it is only
  /// POSTed to the backend when an order is actually placed with it.
  final ApiAddress? gpsDraft;

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

  /// True while [BasketCubit.saveProfileEdit] is awaiting the API call —
  /// disables the "Save" button on the edit-profile screen.
  final bool profileSaving;

  /// Validation/API error from the last `saveProfileEdit` attempt, shown
  /// inline on the edit-profile form.
  final String? profileFormError;

  /// 0-5 star picker on the PDP's "Write a review" card; 0 means no star
  /// picked yet.
  final int reviewRatingInput;
  final String reviewCommentInput;

  /// True while [BasketCubit.submitProductReview] is awaiting the API call.
  final bool reviewSubmitting;

  /// Validation/API error from the last review submit attempt.
  final String? reviewFormError;

  /// True while a delivery-partner status update is in flight — disables
  /// the action button on the delivery detail screen.
  final bool deliveryActionLoading;

  /// API error from the last delivery-status update attempt.
  final String? deliveryActionError;

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

  /// Admin-controlled delivery fee / free-delivery threshold — see
  /// [BasketCubit.loadDeliverySettings].
  final ApiDeliverySettings deliverySettings;
  final List<ApiNotification> apiNotifications;

  /// Home-carousel promo banners (`Banner.placement == 'home_carousel'`).
  final List<ApiBanner> apiBanners;

  /// Admin-editable per-festival overrides (colours/motif/text/on-off) —
  /// see [FestivalCalendar.activeOn].
  final List<ApiFestivalSetting> apiFestivalSettings;

  /// Admin-set call/WhatsApp/chat contact info for the "Help & support"
  /// screen — null until [BasketCubit.loadSupportConfig] resolves (a
  /// best-effort fetch; the screen just renders its buttons disabled
  /// until then).
  final ApiSupportConfig? apiSupportConfig;

  /// Admin-editable Q&A shown on the "Help & support" screen — empty until
  /// [BasketCubit.loadSupportFaqs] resolves (fetched when that screen
  /// opens, not eagerly at app start).
  final List<ApiSupportFaq> apiSupportFaqs;

  /// Set once per order/payment outcome; see [PaymentPopup]. Null the rest
  /// of the time — [BasketCubit.clearPaymentPopup] resets it right after
  /// the root widget shows it.
  final PaymentPopup? paymentPopup;

  /// Set once per app session/day when a festival is active and its popup
  /// is enabled; see [BasketCubit._maybeShowFestivalPopup]. Null the rest of
  /// the time — [BasketCubit.clearFestivalPopup] resets it right after the
  /// root widget shows it.
  final FestivalTheme? festivalPopup;

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
    int? myUserId,
    int? loyaltyPoints,
    ReferralSummary? apiReferralSummary,
    LoyaltySummary? apiLoyaltySummary,
    bool? redeemSubmitting,
    String? redeemMessage,
    bool clearRedeemMessage = false,
    String? role,
    String? couponInput,
    String? appliedCoupon,
    bool clearAppliedCoupon = false,
    String? couponMessage,
    String? selectedOrderId,
    bool clearSelectedOrderId = false,
    String? addressId,
    String? gpsAddress,
    ApiAddress? gpsDraft,
    int? deliveryDay,
    String? deliverySlotId,
    String? paymentMethodId,
    int? trackingStage,
    String? newAddressTag,
    bool? addressSaving,
    String? addressFormError,
    bool clearAddressFormError = false,
    bool? profileSaving,
    String? profileFormError,
    bool clearProfileFormError = false,
    int? reviewRatingInput,
    String? reviewCommentInput,
    bool? reviewSubmitting,
    String? reviewFormError,
    bool clearReviewFormError = false,
    bool? deliveryActionLoading,
    String? deliveryActionError,
    bool clearDeliveryActionError = false,
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
    ApiDeliverySettings? deliverySettings,
    List<ApiNotification>? apiNotifications,
    List<ApiBanner>? apiBanners,
    List<ApiFestivalSetting>? apiFestivalSettings,
    ApiSupportConfig? apiSupportConfig,
    List<ApiSupportFaq>? apiSupportFaqs,
    PaymentPopup? paymentPopup,
    bool clearPaymentPopup = false,
    FestivalTheme? festivalPopup,
    bool clearFestivalPopup = false,
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
      myUserId: myUserId ?? this.myUserId,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      apiReferralSummary: apiReferralSummary ?? this.apiReferralSummary,
      apiLoyaltySummary: apiLoyaltySummary ?? this.apiLoyaltySummary,
      redeemSubmitting: redeemSubmitting ?? this.redeemSubmitting,
      redeemMessage: clearRedeemMessage ? null : (redeemMessage ?? this.redeemMessage),
      role: role ?? this.role,
      couponInput: couponInput ?? this.couponInput,
      appliedCoupon: clearAppliedCoupon ? null : (appliedCoupon ?? this.appliedCoupon),
      couponMessage: couponMessage ?? this.couponMessage,
      selectedOrderId: clearSelectedOrderId ? null : (selectedOrderId ?? this.selectedOrderId),
      addressId: addressId ?? this.addressId,
      gpsAddress: gpsAddress ?? this.gpsAddress,
      gpsDraft: gpsDraft ?? this.gpsDraft,
      deliveryDay: deliveryDay ?? this.deliveryDay,
      deliverySlotId: deliverySlotId ?? this.deliverySlotId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      trackingStage: trackingStage ?? this.trackingStage,
      newAddressTag: newAddressTag ?? this.newAddressTag,
      addressSaving: addressSaving ?? this.addressSaving,
      addressFormError: clearAddressFormError ? null : (addressFormError ?? this.addressFormError),
      profileSaving: profileSaving ?? this.profileSaving,
      profileFormError: clearProfileFormError ? null : (profileFormError ?? this.profileFormError),
      reviewRatingInput: reviewRatingInput ?? this.reviewRatingInput,
      reviewCommentInput: reviewCommentInput ?? this.reviewCommentInput,
      reviewSubmitting: reviewSubmitting ?? this.reviewSubmitting,
      reviewFormError: clearReviewFormError ? null : (reviewFormError ?? this.reviewFormError),
      deliveryActionLoading: deliveryActionLoading ?? this.deliveryActionLoading,
      deliveryActionError: clearDeliveryActionError ? null : (deliveryActionError ?? this.deliveryActionError),
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
      deliverySettings: deliverySettings ?? this.deliverySettings,
      apiNotifications: apiNotifications ?? this.apiNotifications,
      apiBanners: apiBanners ?? this.apiBanners,
      apiFestivalSettings: apiFestivalSettings ?? this.apiFestivalSettings,
      apiSupportConfig: apiSupportConfig ?? this.apiSupportConfig,
      apiSupportFaqs: apiSupportFaqs ?? this.apiSupportFaqs,
      paymentPopup: clearPaymentPopup ? null : (paymentPopup ?? this.paymentPopup),
      festivalPopup: clearFestivalPopup ? null : (festivalPopup ?? this.festivalPopup),
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
        myUserId,
        loyaltyPoints,
        apiReferralSummary,
        apiLoyaltySummary,
        redeemSubmitting,
        redeemMessage,
        role,
        couponInput,
        appliedCoupon,
        couponMessage,
        selectedOrderId,
        addressId,
        gpsAddress,
        gpsDraft,
        deliveryDay,
        deliverySlotId,
        paymentMethodId,
        trackingStage,
        newAddressTag,
        addressSaving,
        addressFormError,
        profileSaving,
        profileFormError,
        reviewRatingInput,
        reviewCommentInput,
        reviewSubmitting,
        reviewFormError,
        deliveryActionLoading,
        deliveryActionError,
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
        deliverySettings,
        apiNotifications,
        apiBanners,
        apiFestivalSettings,
        apiSupportConfig,
        apiSupportFaqs,
        paymentPopup,
        festivalPopup,
      ];
}
