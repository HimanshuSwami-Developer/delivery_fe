import 'dart:async';

import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/prefs/app_prefs.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/cubit/basket_state.dart';
import 'package:fastswipe/features/basket/data/basket_api_bundle.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns every action in the Basket app — navigation, cart/wishlist,
/// browse filters, and the checkout/payment/tracking flow — ported 1:1
/// from `Basket App - Parts 1-2.dc.html`'s `Component` class.
///
/// Navigation is internal state (a `history` stack), not `go_router`:
/// most actions push onto it, but several checkout/payment transitions
/// hard-reset it to skip re-traversing steps the user shouldn't land back
/// on (e.g. `back` from the payment screen goes straight to the cart, not
/// back through order-summary → slot → address). Each such reset is called
/// out below because it's a deliberate product decision in the source
/// design, not an oversight.
class BasketCubit extends Cubit<BasketState> {
  BasketCubit(this.api) : super(const BasketState()) {
    _splashTimer = Timer(const Duration(milliseconds: 1700), _leaveSplash);
    _bootstrap();
  }

  final BasketApiBundle api;

  static const int etaMinutes = 12;
  static const int freeDeliveryAbove = 199;
  static const bool showBuyAgain = true;

  Timer? _splashTimer;
  Timer? _paymentTimer;

  @override
  Future<void> close() {
    _splashTimer?.cancel();
    _paymentTimer?.cancel();
    return super.close();
  }

  /// If a token is already stored (from a previous run), skip straight past
  /// splash/onboarding/login to home rather than making a returning user
  /// re-authenticate every launch.
  Future<void> _bootstrap() async {
    if (!await api.auth.hasSession()) return;
    try {
      final profile = await api.auth.fetchProfile();
      if (profile != null) {
        emit(state.copyWith(name: profile.name));
      }
      _splashTimer?.cancel();
      goReset(BasketScreen.home);
      _loadHomeData();
    } catch (_) {
      // Stale/expired token with no network to refresh it — let the normal
      // splash -> onboarding -> login flow run instead.
    }
  }

  /// Fires every "home screen needs data" fetch in parallel. Each one
  /// manages its own loading/error state independently, so callers don't
  /// await this — it's called once per fresh arrival at home (first
  /// login, post-setup), not on every `goReset(home)`.
  void _loadHomeData() {
    loadCatalog();
    loadZones();
    loadAddresses();
    loadOrders();
    loadCoupons();
    loadNotifications();
    loadBanners();
  }

  Future<void> loadCatalog() async {
    emit(state.copyWith(catalogLoading: true));
    try {
      final categories = await api.catalog.fetchCategories();
      final products = await api.catalog.fetchProducts(ordering: '-ratings_count');
      emit(state.copyWith(catalogLoading: false, apiCategories: categories, apiProducts: products));
    } catch (_) {
      emit(state.copyWith(catalogLoading: false));
    }
  }

  Future<void> loadBanners() async {
    try {
      final banners = await api.promotions.fetchBanners(placement: 'home_carousel', isActive: true);
      emit(state.copyWith(apiBanners: banners));
    } catch (_) {}
  }

  Future<void> loadZones() async {
    try {
      final zones = await api.zones.fetchZones();
      final open = zones.where((z) => z.isOpen);
      final chosen = open.isNotEmpty ? open.first : (zones.isNotEmpty ? zones.first : null);
      emit(state.copyWith(apiZones: zones, zoneId: chosen?.id));
    } catch (_) {}
  }

  Future<void> loadAddresses() async {
    try {
      final addresses = await api.auth.fetchAddresses();
      String? addressId = state.addressId;
      if (addresses.isNotEmpty) {
        final defaults = addresses.where((a) => a.isDefault);
        addressId = (defaults.isNotEmpty ? defaults.first : addresses.first).id;
      }
      emit(state.copyWith(apiAddresses: addresses, addressId: addressId));
    } catch (_) {}
  }

  Future<void> loadOrders() async {
    emit(state.copyWith(ordersLoading: true));
    try {
      final orders = await api.orders.fetchOrders();
      emit(state.copyWith(ordersLoading: false, apiOrders: orders));
    } catch (_) {
      emit(state.copyWith(ordersLoading: false));
    }
  }

  Future<void> loadCoupons() async {
    try {
      final coupons = await api.promotions.fetchCoupons(isActive: true);
      emit(state.copyWith(apiCoupons: coupons));
    } catch (_) {}
  }

  Future<void> loadNotifications() async {
    try {
      final notifications = await api.promotions.fetchNotifications();
      emit(state.copyWith(apiNotifications: notifications));
    } catch (_) {}
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void go(BasketScreen next) {
    emit(state.copyWith(
      history: [...state.history, state.screen],
      screen: next,
      sheet: ActiveSheet.none,
    ));
  }

  void back() {
    if (state.history.isEmpty) {
      emit(state.copyWith(screen: BasketScreen.home, sheet: ActiveSheet.none));
      return;
    }
    emit(state.copyWith(
      screen: state.history.last,
      history: state.history.sublist(0, state.history.length - 1),
      sheet: ActiveSheet.none,
    ));
  }

  /// Jumps to [next] and clears the back-stack — used by the bottom-nav
  /// tabs and anywhere else that should start a fresh flow.
  void goReset(BasketScreen next) {
    emit(state.copyWith(screen: next, history: const [], sheet: ActiveSheet.none));
  }

  void goHome() => goReset(BasketScreen.home);

  /// Opens the PDP immediately with whatever's already cached (list screens
  /// only carry `ProductListSerializer`'s lighter shape, so no gallery yet),
  /// then fetches the full `ProductDetailSerializer` shape in the background
  /// and merges it back into `apiProducts` — that's what fills in `images`
  /// for the slider a moment later.
  void openProduct(String productId) {
    emit(state.copyWith(
      history: [...state.history, state.screen],
      screen: BasketScreen.pdp,
      selectedProductId: productId,
      pdpTab: PdpTab.description,
      sheet: ActiveSheet.none,
    ));
    final id = int.tryParse(productId);
    if (id == null) return;
    api.catalog.fetchProduct(id).then((detail) {
      if (isClosed) return;
      emit(state.copyWith(apiProducts: [for (final p in state.apiProducts) if (p.id == id) detail else p]));
    }).catchError((_) {});
  }

  /// Takes the whole [BasketCategory] (not just its key) so this can pick a
  /// safe starting subcategory itself — some real backend categories have
  /// no subcategories at all, and `category.subs.first` at the call site
  /// threw on those (the "subcategory screen not showing" bug: the tap
  /// crashed before `go` ever ran).
  void openCategory(BasketCategory category) {
    emit(state.copyWith(
      history: [...state.history, state.screen],
      screen: BasketScreen.list,
      category: category.key,
      subcategory: category.subs.isEmpty ? '' : category.subs.first,
      sheet: ActiveSheet.none,
    ));
  }

  /// Home banners are optionally tied to a category (`Banner.category` on
  /// the backend) — tapping one jumps straight to that category's listing,
  /// same destination as tapping the category chip itself. No-op for
  /// banners with no linked category (pure promo art).
  void openBanner(ApiBanner banner) {
    if (banner.categoryId == null) return;
    final match = state.apiCategories.where((c) => c.id == banner.categoryId);
    if (match.isEmpty) return;
    openCategory(BasketCategory.fromApi(match.first));
  }

  void openCoupons({String? code}) {
    emit(state.copyWith(
      history: [...state.history, state.screen],
      screen: BasketScreen.cart,
      couponInput: code ?? (state.apiCoupons.isNotEmpty ? state.apiCoupons.first.code : ''),
      sheet: ActiveSheet.none,
    ));
  }

  // ── Onboarding / auth (Part 1) ──────────────────────────────────────

  /// Onboarding is a once-ever, first-launch thing (persisted via
  /// [AppPrefs]) — every later launch skips straight from splash to
  /// login instead of replaying it.
  Future<void> _leaveSplash() async {
    if (state.screen != BasketScreen.splash) return;
    final seen = await AppPrefs.hasSeenOnboarding();
    if (state.screen != BasketScreen.splash) return; // re-check post-await
    go(seen ? BasketScreen.login : BasketScreen.onboard);
  }

  void skipSplash() => _leaveSplash();

  void skipOnboarding() {
    AppPrefs.setSeenOnboarding();
    go(BasketScreen.login);
  }

  void nextOnboardSlide() {
    if (state.onboardSlide >= BasketCatalog.onboarding.length - 1) {
      AppPrefs.setSeenOnboarding();
      go(BasketScreen.login);
    } else {
      emit(state.copyWith(onboardSlide: state.onboardSlide + 1));
    }
  }

  /// Jumps straight to a slide — the onboarding dots are tappable, not just
  /// swipe/Next-driven.
  void setOnboardSlide(int i) => emit(state.copyWith(onboardSlide: i));

  void setPhone(String value) => emit(state.copyWith(phone: _digitsOnly(value), clearAuthError: true));

  /// The backend wants E.164-ish numbers; the login screen only collects
  /// the 10-digit local part (with a fixed "+91" prefix shown next to it).
  String get _fullPhone => '+91${state.phone}';

  Future<void> sendOtp() async {
    if (state.phone.length < 10) {
      emit(state.copyWith(authError: 'Enter a valid 10-digit mobile number.'));
      return;
    }
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.sendOtp(_fullPhone);
      emit(state.copyWith(authLoading: false));
      go(BasketScreen.otp);
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  Future<void> resendOtp() async {
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.resendOtp(_fullPhone);
      emit(state.copyWith(authLoading: false));
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  void setOtp(String value) => emit(state.copyWith(otp: _digitsOnly(value), clearAuthError: true));

  Future<void> verifyOtp() async {
    if (state.otp.length != 6) {
      emit(state.copyWith(authError: 'Enter all 6 digits to continue.'));
      return;
    }
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      final result = await api.auth.verifyOtp(mobileNumber: _fullPhone, otpCode: state.otp);
      if (result.isNewUser) {
        emit(state.copyWith(authLoading: false));
        go(BasketScreen.setup);
        return;
      }
      final profile = await api.auth.fetchProfile();
      emit(state.copyWith(authLoading: false, name: profile?.name ?? ''));
      goReset(BasketScreen.home);
      _loadHomeData();
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  void setName(String value) => emit(state.copyWith(name: value));

  Future<void> finishSetup() async {
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.completeProfile(state.name.trim());
      emit(state.copyWith(authLoading: false));
      goReset(BasketScreen.home);
      _loadHomeData();
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  Future<void> signOut() async {
    await api.auth.logout();
    emit(const BasketState());
  }

  static String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  // ── Cart / wishlist ──────────────────────────────────────────────────
  //
  // The local `cart`/`wishlist` fields stay the source of truth the UI
  // reads from (so every existing screen keeps working unchanged) — each
  // mutation below updates them immediately, then fires the matching cart
  // API call in the background. A failed sync is swallowed rather than
  // rolled back: the next cart/wishlist fetch (e.g. next app open) is what
  // reconciles, matching how the rest of this app treats the network as
  // best-effort rather than building a full optimistic-rollback pipeline.

  void bump(String productId, int delta) {
    final next = Map<String, int>.from(state.cart);
    final qty = (next[productId] ?? 0) + delta;
    if (qty <= 0) {
      next.remove(productId);
    } else {
      next[productId] = qty;
    }
    emit(state.copyWith(cart: next));
    _syncCartItem(productId, qty <= 0 ? 0 : qty);
  }

  Future<void> _syncCartItem(String productId, int qty) async {
    final id = int.tryParse(productId);
    if (id == null) return;
    try {
      if (qty <= 0) {
        await api.cart.removeItem(id);
      } else {
        await api.cart.setItemQty(id, qty);
      }
    } catch (_) {}
  }

  void addToCart(String productId) {
    final product = productById(state, productId);
    if (product == null || product.oos) return;
    if ((state.cart[productId] ?? 0) == 0) bump(productId, 1);
  }

  void toggleWishlist(String productId) {
    final next = Set<String>.from(state.wishlist);
    final removed = next.remove(productId);
    if (!removed) next.add(productId);
    emit(state.copyWith(wishlist: next));
    final id = int.tryParse(productId);
    if (id == null) return;
    if (removed) {
      api.cart.removeFromWishlist(id).catchError((_) {});
    } else {
      api.cart.addToWishlist(id).catchError((_) {});
    }
  }

  void removeFromWishlist(String productId) {
    final next = Set<String>.from(state.wishlist)..remove(productId);
    emit(state.copyWith(wishlist: next));
    final id = int.tryParse(productId);
    if (id != null) api.cart.removeFromWishlist(id).catchError((_) {});
  }

  /// "Buy it again" — re-adds the most recent order's items to the cart
  /// (the list endpoint doesn't include line items, so this fetches that
  /// one order's detail first).
  Future<void> repeatOrder() async {
    if (state.apiOrders.isEmpty) return;
    try {
      final detail = await api.orders.fetchOrder(state.apiOrders.first.id);
      final newCart = <String, int>{for (final i in detail.items) i.productId.toString(): i.qty};
      emit(state.copyWith(cart: newCart));
      await _syncWholeCart(newCart);
    } catch (_) {}
  }

  Future<void> _syncWholeCart(Map<String, int> cart) async {
    try {
      await api.cart.clearCart();
      for (final entry in cart.entries) {
        final id = int.tryParse(entry.key);
        if (id != null) await api.cart.addItem(id, qty: entry.value);
      }
    } catch (_) {}
  }

  /// Resets the cart to the selected order's items and returns to the cart
  /// with a clean back-stack — matching the source design's `reorder`.
  Future<void> reorder() async {
    final id = state.selectedOrderId != null ? int.tryParse(state.selectedOrderId!) : state.currentOrder?.id;
    if (id == null) return;
    try {
      final detail = await api.orders.fetchOrder(id);
      final newCart = <String, int>{for (final i in detail.items) i.productId.toString(): i.qty};
      emit(state.copyWith(
        cart: newCart,
        screen: BasketScreen.cart,
        clearSelectedOrderId: true,
        history: const [BasketScreen.home],
      ));
      await _syncWholeCart(newCart);
    } on ApiException catch (_) {
      // Nothing to reorder from (e.g. order fetch failed) — stay put.
    }
  }

  void pdpAdd() {
    final id = pdpProduct(state).id;
    addToCart(id);
    go(BasketScreen.cart);
  }

  // ── Browse: filters / sort / search / view ─────────────────────────

  void setSubcategory(String sub) => emit(state.copyWith(subcategory: sub));

  void toggleView() => emit(state.copyWith(
        view: state.view == CatalogView.grid ? CatalogView.rows : CatalogView.grid,
      ));

  void openFilterSheet() => emit(state.copyWith(sheet: ActiveSheet.filter));

  void closeSheet() => emit(state.copyWith(sheet: ActiveSheet.none));

  void setBand(PriceBand band) => emit(state.copyWith(band: band));

  void setSort(SortOption sort) => emit(state.copyWith(sort: sort));

  void resetFilters() => emit(state.copyWith(band: PriceBand.all, sort: SortOption.popularity));

  void setQuery(String query) => emit(state.copyWith(query: query));

  void clearQuery() => emit(state.copyWith(query: ''));

  void setPdpTab(PdpTab tab) => emit(state.copyWith(pdpTab: tab));

  // ── Coupons ──────────────────────────────────────────────────────────

  void setCouponInput(String value) => emit(state.copyWith(couponInput: value));

  Future<void> applyCoupon() async {
    final code = state.couponInput.trim().toUpperCase();
    await _applyCouponCode(code);
  }

  /// Used by the "My coupons" screen's Apply buttons: prefills the code,
  /// navigates to cart, then validates/applies it — matching the source
  /// design's `apply` action (`setState({coupon, screen:'cart', ...}, ()
  /// => applyCoupon())`).
  Future<void> applyCouponFromCard(String code) async {
    emit(state.copyWith(
      history: [...state.history, state.screen],
      screen: BasketScreen.cart,
      couponInput: code,
      sheet: ActiveSheet.none,
    ));
    await _applyCouponCode(code);
  }

  /// Applies the coupon on the real server-side cart (not just locally) —
  /// `placeOrder` reads `Cart.coupon` directly, so this is what makes the
  /// discount actually carry through to the order that gets placed.
  Future<void> _applyCouponCode(String code) async {
    if (code.isEmpty) {
      emit(state.copyWith(couponMessage: '"—" is not a valid code.'));
      return;
    }
    try {
      await api.cart.applyCoupon(code);
      emit(state.copyWith(appliedCoupon: code, couponMessage: '$code applied.'));
    } on ApiException catch (e) {
      emit(state.copyWith(couponMessage: e.message));
    }
  }

  // ── Checkout: address ────────────────────────────────────────────────

  void goCheckout() => go(BasketScreen.addr);

  void selectAddress(String addressId) => emit(state.copyWith(addressId: addressId));

  void openAddressEdit() {
    emit(state.copyWith(clearAddressFormError: true));
    go(BasketScreen.addrEdit);
  }

  void setNewAddressTag(String tag) => emit(state.copyWith(newAddressTag: tag));

  /// Validates and POSTs a new address (`api.auth.addAddress`), then
  /// refreshes [BasketState.apiAddresses] and selects the new one. Resets
  /// the back-stack to `[home, cart]` on success — from the saved address
  /// screen, back should return to the cart, not the address form.
  Future<void> submitNewAddress({
    required String houseNo,
    required String landmark,
    required String city,
    required String stateName,
    required String pincode,
  }) async {
    if (houseNo.trim().isEmpty) {
      emit(state.copyWith(addressFormError: 'Flat / house no. is required.'));
      return;
    }
    if (city.trim().isEmpty || stateName.trim().isEmpty || pincode.trim().isEmpty) {
      emit(state.copyWith(addressFormError: 'City, state and pincode are required.'));
      return;
    }

    emit(state.copyWith(addressSaving: true, clearAddressFormError: true));
    try {
      final saved = await api.auth.addAddress(ApiAddress(
        id: '',
        addressType: state.newAddressTag.toLowerCase(),
        addressLine1: houseNo.trim(),
        addressLine2: landmark.trim().isEmpty ? null : landmark.trim(),
        city: city.trim(),
        state: stateName.trim(),
        country: 'India',
        pincode: pincode.trim(),
        isDefault: state.apiAddresses.isEmpty,
      ));
      final addresses = [...state.apiAddresses, saved];
      emit(state.copyWith(
        addressSaving: false,
        apiAddresses: addresses,
        addressId: saved.id,
        screen: BasketScreen.addr,
        history: const [BasketScreen.home, BasketScreen.cart],
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(addressSaving: false, addressFormError: e.message));
    } catch (_) {
      emit(state.copyWith(addressSaving: false, addressFormError: 'Could not save address. Try again.'));
    }
  }

  void goToAddress() => go(BasketScreen.addr);

  // ── Checkout: delivery slot ──────────────────────────────────────────

  void goToSlot() => go(BasketScreen.slot);

  void selectDeliveryDay(int index) => emit(state.copyWith(deliveryDay: index));

  void selectDeliverySlot(String slotId) => emit(state.copyWith(deliverySlotId: slotId));

  void goToSummary() => go(BasketScreen.summary);

  // ── Checkout: payment ────────────────────────────────────────────────

  void selectPaymentMethod(String methodId) => emit(state.copyWith(paymentMethodId: methodId));

  /// Resets the back-stack to `[home, cart]` — used both from order
  /// summary ("Choose payment") and from the failure screen ("Retry
  /// payment"), so back always returns to the cart rather than replaying
  /// the whole address/slot/summary chain.
  void goToPay() {
    emit(state.copyWith(
      screen: BasketScreen.pay,
      history: const [BasketScreen.home, BasketScreen.cart],
    ));
  }

  /// Maps the UI's 5 payment options to what `Order.PaymentMode` actually
  /// supports server-side — "Net banking" has no backend equivalent, so it
  /// rides in as a card payment rather than growing its own enum value.
  String _backendPaymentMode(String id) => switch (id) {
        'upi' => 'upi',
        'wallet' => 'wallet',
        'cod' => 'cod',
        _ => 'card',
      };

  Future<void> payNow() async {
    emit(state.copyWith(
      screen: BasketScreen.paying,
      history: const [BasketScreen.home, BasketScreen.cart, BasketScreen.pay],
      trackingStage: 0,
    ));
    await _placeRealOrder(minDelay: const Duration(milliseconds: 1700));
  }

  /// The source design had a dedicated "simulate failure" demo button —
  /// with a real backend there's no payment gateway to fail, so this stays
  /// a pure UI demo of the failure screen rather than calling the API.
  void simulatePaymentFailure() {
    emit(state.copyWith(
      screen: BasketScreen.paying,
      history: const [BasketScreen.home, BasketScreen.cart, BasketScreen.pay],
    ));
    _paymentTimer?.cancel();
    _paymentTimer = Timer(const Duration(milliseconds: 1500), () {
      emit(state.copyWith(
        screen: BasketScreen.failure,
        history: const [BasketScreen.home, BasketScreen.cart, BasketScreen.pay],
      ));
    });
  }

  Future<void> payCashOnDelivery() async {
    emit(state.copyWith(
      paymentMethodId: 'cod',
      screen: BasketScreen.paying,
      history: const [BasketScreen.home],
    ));
    await _placeRealOrder(minDelay: const Duration(milliseconds: 1200));
  }

  /// For now: skips the payment-method screen entirely — checkout goes
  /// straight from order summary to placing the order (COD) and into live
  /// tracking, no "Choose payment"/processing-success detour.
  /// `goToPay`/`payNow`/payment_method_view stay in place, unused, for
  /// when a real payment method picker comes back.
  Future<void> checkoutDirect() async {
    emit(state.copyWith(
      paymentMethodId: 'cod',
      screen: BasketScreen.paying,
      history: const [BasketScreen.home, BasketScreen.cart],
      trackingStage: 0,
    ));
    await _placeRealOrder(minDelay: const Duration(milliseconds: 1200), goToTrackOnSuccess: true);
  }

  /// Places the order from the customer's (already server-synced) cart,
  /// keeping the "paying" screen up for at least [minDelay] even if the
  /// API responds faster, so the processing animation doesn't just flash.
  Future<void> _placeRealOrder({required Duration minDelay, bool goToTrackOnSuccess = false}) async {
    final zoneId = state.zoneId;
    if (zoneId == null) {
      emit(state.copyWith(
        screen: BasketScreen.failure,
        history: const [BasketScreen.home, BasketScreen.cart, BasketScreen.pay],
      ));
      return;
    }
    final delayFuture = Future<void>.delayed(minDelay);
    try {
      final order = await api.orders.placeOrder(
        addressId: state.addressId,
        zone: zoneId,
        paymentMode: _backendPaymentMode(state.paymentMethodId),
      );
      await delayFuture;
      emit(state.copyWith(
        currentOrder: order,
        cart: const {},
        screen: goToTrackOnSuccess ? BasketScreen.track : BasketScreen.success,
        history: const [BasketScreen.home],
      ));
      loadOrders();
      if (goToTrackOnSuccess) await refreshTracking();
    } on ApiException catch (_) {
      await delayFuture;
      emit(state.copyWith(
        screen: BasketScreen.failure,
        history: const [BasketScreen.home, BasketScreen.cart, BasketScreen.pay],
      ));
    }
  }

  // ── Orders / tracking ────────────────────────────────────────────────

  /// Opens order detail and fetches its full line-item detail — [orderId]
  /// is null right after placing an order (there's no id to pass yet other
  /// than [BasketState.currentOrder], which is already the full detail).
  Future<void> openOrderDetail(String? orderId) async {
    emit(state.copyWith(
      history: [...state.history, state.screen],
      screen: BasketScreen.orderDet,
      selectedOrderId: orderId,
      clearSelectedOrderId: orderId == null,
      sheet: ActiveSheet.none,
    ));
    final id = orderId != null ? int.tryParse(orderId) : state.currentOrder?.id;
    if (id == null) return;
    try {
      final detail = await api.orders.fetchOrder(id);
      emit(state.copyWith(currentOrder: detail));
    } catch (_) {}
  }

  static const _statusToStage = {'new': 0, 'packed': 1, 'out_for_delivery': 2, 'delivered': 3};

  Future<void> goToTrack() async {
    go(BasketScreen.track);
    await refreshTracking();
  }

  /// Re-fetches [state.currentOrder] and re-derives [BasketState.trackingStage]
  /// from its real status — replaces the source design's demo-only
  /// "advance status" button, since a customer can't actually move their
  /// own delivery forward.
  Future<void> refreshTracking() async {
    final id = state.currentOrder?.id;
    if (id == null) return;
    try {
      final order = await api.orders.fetchOrder(id);
      emit(state.copyWith(currentOrder: order, trackingStage: _statusToStage[order.status] ?? state.trackingStage));
    } catch (_) {}
  }

  // ── Cancel / return ──────────────────────────────────────────────────

  void openCancelSheet() {
    emit(state.copyWith(
      sheet: ActiveSheet.cancelOrReturn,
      cancelMode: CancelMode.cancel,
      clearCancelReason: true,
    ));
  }

  void openReturnSheet() {
    emit(state.copyWith(
      sheet: ActiveSheet.cancelOrReturn,
      cancelMode: CancelMode.returnItems,
      clearCancelReason: true,
    ));
  }

  void pickCancelReason(String reason) => emit(state.copyWith(cancelReason: reason));

  /// Resets the back-stack to `[home, account]` — dismissing the sheet and
  /// landing on the orders list, not back through order-detail/tracking.
  /// Cancellation calls the real API (only while New/Packed, enforced
  /// server-side); "return items" has no backend model, so it stays the
  /// UI-only demo the source design had.
  Future<void> confirmCancel() async {
    final orderId = state.currentOrder?.id;
    if (state.cancelMode == CancelMode.cancel && orderId != null) {
      try {
        final updated = await api.orders.cancelOrder(orderId);
        emit(state.copyWith(currentOrder: updated));
      } on ApiException catch (_) {}
    }
    emit(state.copyWith(
      sheet: ActiveSheet.none,
      screen: BasketScreen.orders,
      history: const [BasketScreen.home, BasketScreen.account],
    ));
    loadOrders();
  }

  // ── Account sub-pages ────────────────────────────────────────────────

  void goToSupport() => go(BasketScreen.support);

  void goToNotifications() => go(BasketScreen.notifs);
}
