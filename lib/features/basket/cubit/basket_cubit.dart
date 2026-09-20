import 'dart:async';

import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/geo/nominatim_service.dart';
import 'package:fastswipe/core/notifications/push_notifications.dart';
import 'package:fastswipe/core/prefs/app_prefs.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/cubit/basket_state.dart';
import 'package:fastswipe/features/basket/data/basket_api_bundle.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/festival_theme.dart';
import 'package:flutter/foundation.dart';
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
    _splashTimer = Timer(const Duration(milliseconds: 3000), _leaveSplash);
    _bootstrap();
    // Re-register whenever the OS/browser rotates the token — a no-op
    // (401, swallowed) if nobody's signed in yet.
    _tokenRefreshSub = PushNotifications.onTokenRefresh.listen(
      (_) => _registerDevice(),
    );
  }

  final BasketApiBundle api;

  static const int etaMinutes = 12;
  static const int freeDeliveryAbove = 199;
  static const bool showBuyAgain = true;

  Timer? _splashTimer;
  StreamSubscription<String>? _tokenRefreshSub;
  bool _hasSession = false;

  @override
  Future<void> close() {
    _splashTimer?.cancel();
    _tokenRefreshSub?.cancel();
    return super.close();
  }

  /// Upserts this device's current FCM token against the signed-in user.
  /// Best-effort: no session, no token yet (web without a VAPID key), or a
  /// network hiccup all just mean this device stays un-registered until
  /// the next call — never surfaced to the UI.
  Future<void> _registerDevice() async {
    final token = await PushNotifications.currentToken();
    if (token == null) {
      debugPrint('[push] _registerDevice: no token yet, skipping');
      return;
    }
    try {
      await api.auth.registerDevice(
        token: token,
        platform: PushNotifications.platformName,
      );
      debugPrint('[push] _registerDevice: registered ok');
    } catch (e) {
      debugPrint('[push] _registerDevice failed: $e');
    }
  }

  /// If a token is already stored (from a previous run), skip straight past
  /// splash/onboarding/login to home rather than making a returning user
  /// re-authenticate every launch.
  Future<void> _bootstrap() async {
    if (!await api.auth.hasSession()) return;
    // `hasSession` is just a local secure-storage read — trust it, but
    // still let the splash's own timer (`_leaveSplash`) decide when to
    // move on, so the splash always shows for its full fixed duration
    // instead of getting cut short for returning signed-in users. Don't
    // gate the home-data load on `fetchProfile` succeeding: that's a
    // network call, and if it's slow or fails outright, an already-logged-in
    // user would otherwise get dumped back on the login screen for no reason.
    _hasSession = true;
    _loadHomeData();
    _registerDevice();
    try {
      final profile = await api.auth.fetchProfile();
      if (profile != null) {
        emit(
          state.copyWith(
            name: profile.name,
            email: profile.email,
            myReferralCode: profile.referralCode,
            myUserId: profile.id,
            loyaltyPoints: profile.loyaltyPoints,
            role: profile.role,
          ),
        );
      } else {
        // No completed profile (e.g. an admin-provisioned delivery_boy
        // account) — fall back to the role alone so tabs like "Deliveries"
        // still show up for them.
        final role = await api.auth.fetchRole();
        if (role != null) emit(state.copyWith(role: role));
      }
    } catch (_) {
      // Best-effort — the session is still trusted either way; a failed
      // profile fetch just leaves the name greeting blank for now.
    }
  }

  /// Fires every "home screen needs data" fetch in parallel. Each one
  /// manages its own loading/error state independently, so callers don't
  /// await this — it's called once per fresh arrival at home (first
  /// login, post-setup), not on every `goReset(home)`.
  void _loadHomeData() {
    loadCatalog();
    loadAddresses();
    loadGpsLocation();
    loadOrders();
    loadCoupons();
    loadNotifications();
    loadBanners();
    loadFestivalSettings();
    loadSupportConfig();
    loadLoyalty();
  }

  Future<void> loadCatalog() async {
    emit(state.copyWith(catalogLoading: true));
    try {
      final categories = await api.catalog.fetchCategories();
      final products = await api.catalog.fetchProducts(
        ordering: '-ratings_count',
      );
      emit(
        state.copyWith(
          catalogLoading: false,
          apiCategories: categories,
          apiProducts: products,
        ),
      );
    } catch (_) {
      emit(state.copyWith(catalogLoading: false));
    }
  }

  Future<void> loadBanners() async {
    try {
      final banners = await api.promotions.fetchBanners(
        placement: 'home_carousel',
        isActive: true,
      );
      emit(state.copyWith(apiBanners: banners));
    } catch (_) {}
  }

  Future<void> loadFestivalSettings() async {
    try {
      final settings = await api.promotions.fetchFestivalSettings();
      emit(state.copyWith(apiFestivalSettings: settings));
      await _maybeShowFestivalPopup(settings);
    } catch (_) {
      // Best-effort — falls back to the app's built-in festival defaults
      // (see FestivalCalendar), so a failed fetch just means today's
      // festival (if any) can't be admin-overridden this session.
      await _maybeShowFestivalPopup(state.apiFestivalSettings);
    }
  }

  /// Shows the festival popup at most once per day per festival — tracked
  /// on-device via [AppPrefs], not per session, so it doesn't nag on every
  /// app reopen but does reappear for a new festival or the next day.
  Future<void> _maybeShowFestivalPopup(
    List<ApiFestivalSetting> settings,
  ) async {
    final festival = FestivalCalendar.activeToday(settings: settings);
    if (festival == null || !festival.popupEnabled) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (await AppPrefs.hasShownFestivalPopupToday(festival.id, today)) return;
    await AppPrefs.markFestivalPopupShown(festival.id, today);
    emit(state.copyWith(festivalPopup: festival));
  }

  void clearFestivalPopup() => emit(state.copyWith(clearFestivalPopup: true));

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

  /// Best-effort, silent GPS lookup for the Home header's address
  /// subtitle — never prompts beyond the OS's own permission dialog, never
  /// surfaces an error, and simply leaves [BasketState.gpsAddress] null
  /// (falling back to the saved address — see `homeAddressSubtitle`) if
  /// location services are off, permission is denied, or the device just
  /// can't get a fix in time.
  Future<void> loadGpsLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 8),
        ),
      );
      final result = await NominatimService().reverseGeocode(
        LatLng(position.latitude, position.longitude),
      );
      if (result != null && result.displayName.isNotEmpty) {
        emit(state.copyWith(gpsAddress: result.displayName));
      }
    } catch (_) {
      // Best-effort — the saved-address fallback covers this.
    }
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
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: next,
        sheet: ActiveSheet.none,
      ),
    );
  }

  void back() {
    if (state.history.isEmpty) {
      emit(state.copyWith(screen: BasketScreen.home, sheet: ActiveSheet.none));
      return;
    }
    emit(
      state.copyWith(
        screen: state.history.last,
        history: state.history.sublist(0, state.history.length - 1),
        sheet: ActiveSheet.none,
      ),
    );
  }

  /// Jumps to [next] and clears the back-stack — used by the bottom-nav
  /// tabs and anywhere else that should start a fresh flow.
  void goReset(BasketScreen next) {
    emit(
      state.copyWith(screen: next, history: const [], sheet: ActiveSheet.none),
    );
  }

  void goHome() => goReset(BasketScreen.home);

  /// Opens the PDP immediately with whatever's already cached (list screens
  /// only carry `ProductListSerializer`'s lighter shape, so no gallery yet),
  /// then fetches the full `ProductDetailSerializer` shape in the background
  /// and merges it back into `apiProducts` — that's what fills in `images`
  /// for the slider a moment later.
  void openProduct(String productId) {
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: BasketScreen.pdp,
        selectedProductId: productId,
        pdpTab: PdpTab.description,
        sheet: ActiveSheet.none,
        // Reset any half-typed review from whatever product was open last.
        reviewRatingInput: 0,
        reviewCommentInput: '',
        clearReviewFormError: true,
      ),
    );
    final id = int.tryParse(productId);
    if (id == null) return;
    api.catalog
        .fetchProduct(id)
        .then((detail) {
          if (isClosed) return;
          emit(
            state.copyWith(
              apiProducts: [
                for (final p in state.apiProducts)
                  if (p.id == id) detail else p,
              ],
            ),
          );
        })
        .catchError((_) {});
  }

  // ── Product reviews ──────────────────────────────────────────────────

  void setReviewRating(int stars) => emit(state.copyWith(reviewRatingInput: stars));

  void setReviewComment(String value) => emit(state.copyWith(reviewCommentInput: value));

  /// Posts a new review, or — if this signed-in user already has one on
  /// this product (server enforces one review per product per user) —
  /// `PATCH`es theirs instead, so re-submitting from the same form edits
  /// it rather than failing with a uniqueness error. Refetches the product
  /// afterward so both the new review and the server-recalculated
  /// `rating`/`ratingsCount` show up immediately (see
  /// `Product.recalculate_rating` server-side).
  Future<void> submitProductReview(String productId) async {
    final id = int.tryParse(productId);
    if (id == null) return;
    final stars = state.reviewRatingInput;
    if (stars == 0) {
      emit(state.copyWith(reviewFormError: 'Pick a star rating first.'));
      return;
    }
    emit(state.copyWith(reviewSubmitting: true, clearReviewFormError: true));
    try {
      final product = productById(state, productId);
      ApiProductReview? existing;
      if (product != null && state.myUserId != null) {
        for (final r in product.reviews) {
          if (r.userId == state.myUserId) {
            existing = r;
            break;
          }
        }
      }
      final comment = state.reviewCommentInput.trim();
      if (existing != null) {
        await api.catalog.updateReview(existing.id, rating: stars, comment: comment);
      } else {
        await api.catalog.submitReview(productId: id, rating: stars, comment: comment);
      }
      final detail = await api.catalog.fetchProduct(id);
      emit(
        state.copyWith(
          reviewSubmitting: false,
          reviewRatingInput: 0,
          reviewCommentInput: '',
          apiProducts: [for (final p in state.apiProducts) if (p.id == id) detail else p],
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(reviewSubmitting: false, reviewFormError: e.message));
    }
  }

  /// Takes the whole [BasketCategory] (not just its key) so this can pick a
  /// safe starting subcategory itself — some real backend categories have
  /// no subcategories at all, and `category.subs.first` at the call site
  /// threw on those (the "subcategory screen not showing" bug: the tap
  /// crashed before `go` ever ran).
  void openCategory(BasketCategory category) {
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: BasketScreen.list,
        category: category.key,
        subcategory: category.subs.isEmpty ? '' : category.subs.first,
        sheet: ActiveSheet.none,
      ),
    );
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
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: BasketScreen.cart,
        couponInput:
            code ??
            (state.apiCoupons.isNotEmpty ? state.apiCoupons.first.code : ''),
        sheet: ActiveSheet.none,
      ),
    );
  }

  // ── Onboarding / auth (Part 1) ──────────────────────────────────────

  /// Onboarding is a once-ever, first-launch thing (persisted via
  /// [AppPrefs]) — every later launch skips straight from splash to
  /// login instead of replaying it.
  Future<void> _leaveSplash() async {
    if (state.screen != BasketScreen.splash) return;
    if (_hasSession) {
      goReset(BasketScreen.home);
      return;
    }
    final seen = await AppPrefs.hasSeenOnboarding();
    if (state.screen != BasketScreen.splash) return; // re-check post-await
    go(seen ? BasketScreen.login : BasketScreen.onboard);
  }

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

  void setPhone(String value) =>
      emit(state.copyWith(phone: _digitsOnly(value), clearAuthError: true));

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

  void setOtp(String value) =>
      emit(state.copyWith(otp: _digitsOnly(value), clearAuthError: true));

  Future<void> verifyOtp() async {
    if (state.otp.length != 4) {
      emit(state.copyWith(authError: 'Enter all 4 digits to continue.'));
      return;
    }
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      final result = await api.auth.verifyOtp(
        mobileNumber: _fullPhone,
        otpCode: state.otp,
      );
      _registerDevice();
      if (result.isNewUser) {
        emit(state.copyWith(authLoading: false));
        go(BasketScreen.setup);
        return;
      }
      final profile = await api.auth.fetchProfile();
      // See `fetchRole` — an admin-provisioned delivery_boy/admin account
      // never completes a customer profile, so `profile` is null forever
      // and `role` must be recovered separately.
      final role = profile?.role ?? await api.auth.fetchRole() ?? 'customer';
      emit(
        state.copyWith(
          authLoading: false,
          name: profile?.name ?? '',
          email: profile?.email ?? '',
          myReferralCode: profile?.referralCode,
          myUserId: profile?.id,
          loyaltyPoints: profile?.loyaltyPoints ?? 0,
          role: role,
        ),
      );
      goReset(BasketScreen.home);
      _loadHomeData();
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  void setName(String value) => emit(state.copyWith(name: value));

  void setEmail(String value) => emit(state.copyWith(email: value));

  void setReferralCodeInput(String value) =>
      emit(state.copyWith(referralCodeInput: value));

  Future<void> finishSetup() async {
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      final profile = await api.auth.completeProfile(
        state.name.trim(),
        email: state.email.trim(),
        referralCode: state.referralCodeInput.trim(),
      );
      emit(
        state.copyWith(
          authLoading: false,
          myReferralCode: profile.referralCode,
          myUserId: profile.id,
          loyaltyPoints: profile.loyaltyPoints,
          role: profile.role,
        ),
      );
      goReset(BasketScreen.home);
      _loadHomeData();
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  /// Saves an edit to the signed-in user's own name/email — unlike
  /// [finishSetup] (first-time onboarding, `POST`), this `PATCH`s an
  /// already-completed profile and returns to the account screen instead
  /// of resetting into the home flow.
  Future<void> saveProfileEdit() async {
    final name = state.name.trim();
    if (name.isEmpty) {
      emit(state.copyWith(profileFormError: 'Name can\'t be empty'));
      return;
    }
    final email = state.email.trim();
    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      emit(state.copyWith(profileFormError: 'Enter a valid email address'));
      return;
    }
    emit(state.copyWith(profileSaving: true, clearProfileFormError: true));
    try {
      final profile = await api.auth.updateProfile(name, email: email.isEmpty ? null : email);
      emit(state.copyWith(profileSaving: false, name: profile.name, email: profile.email));
      back();
    } on ApiException catch (e) {
      emit(state.copyWith(profileSaving: false, profileFormError: e.message));
    }
  }

  Future<void> signOut() async {
    await api.auth.logout();
    emit(const BasketState());
  }

  static String _digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

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
      final newCart = <String, int>{
        for (final i in detail.items) i.productId.toString(): i.qty,
      };
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
    final id = state.selectedOrderId != null
        ? int.tryParse(state.selectedOrderId!)
        : state.currentOrder?.id;
    if (id == null) return;
    try {
      final detail = await api.orders.fetchOrder(id);
      final newCart = <String, int>{
        for (final i in detail.items) i.productId.toString(): i.qty,
      };
      emit(
        state.copyWith(
          cart: newCart,
          screen: BasketScreen.cart,
          clearSelectedOrderId: true,
          history: const [BasketScreen.home],
        ),
      );
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

  void toggleView() => emit(
    state.copyWith(
      view: state.view == CatalogView.grid
          ? CatalogView.rows
          : CatalogView.grid,
    ),
  );

  void openFilterSheet() => emit(state.copyWith(sheet: ActiveSheet.filter));

  void closeSheet() => emit(state.copyWith(sheet: ActiveSheet.none));

  void setBand(PriceBand band) => emit(state.copyWith(band: band));

  void setSort(SortOption sort) => emit(state.copyWith(sort: sort));

  void resetFilters() =>
      emit(state.copyWith(band: PriceBand.all, sort: SortOption.popularity));

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
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: BasketScreen.cart,
        couponInput: code,
        sheet: ActiveSheet.none,
      ),
    );
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
      emit(
        state.copyWith(appliedCoupon: code, couponMessage: '$code applied.'),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(couponMessage: e.message));
    }
  }

  // ── Checkout: address ────────────────────────────────────────────────

  void goCheckout() => go(BasketScreen.addr);

  void selectAddress(String addressId) =>
      emit(state.copyWith(addressId: addressId));

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
    double? latitude,
    double? longitude,
  }) async {
    if (houseNo.trim().isEmpty) {
      emit(state.copyWith(addressFormError: 'Flat / house no. is required.'));
      return;
    }
    if (city.trim().isEmpty ||
        stateName.trim().isEmpty ||
        pincode.trim().isEmpty) {
      emit(
        state.copyWith(
          addressFormError: 'City, state and pincode are required.',
        ),
      );
      return;
    }

    emit(state.copyWith(addressSaving: true, clearAddressFormError: true));
    try {
      final saved = await api.auth.addAddress(
        ApiAddress(
          id: '',
          addressType: state.newAddressTag.toLowerCase(),
          addressLine1: houseNo.trim(),
          addressLine2: landmark.trim().isEmpty ? null : landmark.trim(),
          city: city.trim(),
          state: stateName.trim(),
          country: 'India',
          pincode: pincode.trim(),
          isDefault: state.apiAddresses.isEmpty,
          latitude: latitude,
          longitude: longitude,
        ),
      );
      final addresses = [...state.apiAddresses, saved];
      emit(
        state.copyWith(
          addressSaving: false,
          apiAddresses: addresses,
          addressId: saved.id,
          screen: BasketScreen.addr,
          history: const [BasketScreen.home, BasketScreen.cart],
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(addressSaving: false, addressFormError: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          addressSaving: false,
          addressFormError: 'Could not save address. Try again.',
        ),
      );
    }
  }

  void goToAddress() => go(BasketScreen.addr);

  // ── Checkout: delivery slot ──────────────────────────────────────────

  void goToSlot() => go(BasketScreen.slot);

  void selectDeliveryDay(int index) => emit(state.copyWith(deliveryDay: index));

  void selectDeliverySlot(String slotId) =>
      emit(state.copyWith(deliverySlotId: slotId));

  void goToSummary() => go(BasketScreen.summary);

  // ── Checkout: payment ────────────────────────────────────────────────

  /// From order summary's "Place order" — shows the QR-code-or-COD choice.
  /// Resets the back-stack to `[home, cart]` so back always returns to the
  /// cart rather than replaying address/slot/summary.
  void goToPaymentChoice() {
    emit(
      state.copyWith(
        screen: BasketScreen.payChoice,
        history: const [BasketScreen.home, BasketScreen.cart],
      ),
    );
  }

  /// From the payment-choice screen's "Pay via UPI QR code" — the QR image
  /// itself is generated client-side from the cart's payable total, so no
  /// backend call happens until the customer actually uploads a screenshot
  /// (see [placeQrOrder]).
  void chooseQrPayment() {
    emit(
      state.copyWith(
        paymentMethodId: 'qr',
        screen: BasketScreen.qrPayment,
        history: const [
          BasketScreen.home,
          BasketScreen.cart,
          BasketScreen.payChoice,
        ],
      ),
    );
  }

  Future<void> payCashOnDelivery() async {
    emit(
      state.copyWith(
        paymentMethodId: 'cod',
        screen: BasketScreen.paying,
        history: const [BasketScreen.home],
      ),
    );
    await _placeRealOrder(minDelay: const Duration(milliseconds: 1200));
  }

  /// From the QR screen, once the customer has picked their payment
  /// screenshot — places the order with it attached as proof. The backend
  /// uploads it to Cloudinary and leaves `payment_status` pending for an
  /// admin to verify by hand; there's no gateway callback to trust here.
  Future<void> placeQrOrder(
    List<int> screenshotBytes,
    String screenshotFilename,
  ) async {
    emit(
      state.copyWith(
        screen: BasketScreen.paying,
        history: const [BasketScreen.home, BasketScreen.cart],
        trackingStage: 0,
      ),
    );
    await _placeRealOrder(
      minDelay: const Duration(milliseconds: 1700),
      screenshotBytes: screenshotBytes,
      screenshotFilename: screenshotFilename,
    );
  }

  /// Places the order from the customer's (already server-synced) cart,
  /// keeping the "paying" screen up for at least [minDelay] even if the API
  /// responds faster, so the processing animation doesn't just flash.
  Future<void> _placeRealOrder({
    required Duration minDelay,
    List<int>? screenshotBytes,
    String? screenshotFilename,
  }) async {
    final delayFuture = Future<void>.delayed(minDelay);
    try {
      final order = await api.orders.placeOrder(
        addressId: state.addressId,
        paymentMode: state.paymentMethodId,
        paymentScreenshotBytes: screenshotBytes,
        paymentScreenshotFilename: screenshotFilename,
      );
      await delayFuture;

      emit(
        state.copyWith(
          currentOrder: order,
          cart: const {},
          screen: BasketScreen.success,
          history: const [BasketScreen.home],
          paymentPopup: PaymentPopup(
            title: 'Order placed',
            message: order.paymentMode == 'qr'
                ? "Your order ${order.orderNumber} has been placed — we'll confirm your payment shortly."
                : 'Your order ${order.orderNumber} has been placed successfully.',
            success: true,
          ),
        ),
      );
      loadOrders();
    } on ApiException catch (e) {
      await delayFuture;
      emit(
        state.copyWith(
          screen: BasketScreen.failure,
          history: const [BasketScreen.home, BasketScreen.cart],
          paymentPopup: PaymentPopup(
            title: 'Could not place order',
            message: e.message,
            success: false,
          ),
        ),
      );
    }
  }

  void clearPaymentPopup() => emit(state.copyWith(clearPaymentPopup: true));

  // ── Orders / tracking ────────────────────────────────────────────────

  /// Opens order detail and fetches its full line-item detail — [orderId]
  /// is null right after placing an order (there's no id to pass yet other
  /// than [BasketState.currentOrder], which is already the full detail).
  Future<void> openOrderDetail(String? orderId) async {
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: BasketScreen.orderDet,
        selectedOrderId: orderId,
        clearSelectedOrderId: orderId == null,
        sheet: ActiveSheet.none,
      ),
    );
    final id = orderId != null ? int.tryParse(orderId) : state.currentOrder?.id;
    if (id == null) return;
    try {
      final detail = await api.orders.fetchOrder(id);
      emit(state.copyWith(currentOrder: detail));
    } catch (_) {}
  }

  // ── Delivery partner ─────────────────────────────────────────────────

  /// Opens a delivery's detail (map + customer + status action) — only
  /// reachable from the "Deliveries" tab, itself only shown for
  /// role='delivery_boy' accounts (see `kBottomNavScreens`/`BasketBottomNav`).
  Future<void> openDeliveryDetail(String orderId) async {
    emit(
      state.copyWith(
        history: [...state.history, state.screen],
        screen: BasketScreen.deliveryDetail,
        selectedOrderId: orderId,
        clearDeliveryActionError: true,
        sheet: ActiveSheet.none,
      ),
    );
    final id = int.tryParse(orderId);
    if (id == null) return;
    try {
      final detail = await api.orders.fetchOrder(id);
      emit(state.copyWith(currentOrder: detail));
    } catch (_) {}
  }

  /// Advances the open delivery to [newStatus] (`out_for_delivery` or
  /// `delivered` — see `DeliveryOrderDetailView`), then refreshes both the
  /// open detail and the list behind it so "Deliveries" reflects it
  /// immediately on back.
  Future<void> updateDeliveryStatus(String newStatus) async {
    final id = state.currentOrder?.id;
    if (id == null) return;
    emit(
      state.copyWith(
        deliveryActionLoading: true,
        clearDeliveryActionError: true,
      ),
    );
    try {
      final updated = await api.orders.setStatus(id, newStatus);
      emit(state.copyWith(deliveryActionLoading: false, currentOrder: updated));
      loadOrders();
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          deliveryActionLoading: false,
          deliveryActionError: e.message,
        ),
      );
    }
  }

  static const _statusToStage = {
    'new': 0,
    'packed': 1,
    'out_for_delivery': 2,
    'delivered': 3,
  };

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
      emit(
        state.copyWith(
          currentOrder: order,
          trackingStage: _statusToStage[order.status] ?? state.trackingStage,
        ),
      );
    } catch (_) {}
  }

  // ── Cancel / return ──────────────────────────────────────────────────

  void openCancelSheet() {
    emit(
      state.copyWith(
        sheet: ActiveSheet.cancelOrReturn,
        cancelMode: CancelMode.cancel,
        clearCancelReason: true,
      ),
    );
  }

  void openReturnSheet() {
    emit(
      state.copyWith(
        sheet: ActiveSheet.cancelOrReturn,
        cancelMode: CancelMode.returnItems,
        clearCancelReason: true,
      ),
    );
  }

  void pickCancelReason(String reason) =>
      emit(state.copyWith(cancelReason: reason));

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
    emit(
      state.copyWith(
        sheet: ActiveSheet.none,
        screen: BasketScreen.orders,
        history: const [BasketScreen.home, BasketScreen.account],
      ),
    );
    loadOrders();
  }

  // ── Account sub-pages ────────────────────────────────────────────────

  /// Best-effort, like [loadBanners]/[loadFestivalSettings] — a failed
  /// fetch just leaves the "Help & support" screen's call/chat/WhatsApp
  /// buttons disabled rather than blocking anything.
  Future<void> loadSupportConfig() async {
    try {
      final config = await api.support.fetchSupportConfig();
      emit(state.copyWith(apiSupportConfig: config));
    } catch (_) {}
  }

  void goToSupport() => go(BasketScreen.support);

  void goToNotifications() => go(BasketScreen.notifs);

  // ── Referrals / loyalty ──────────────────────────────────────────────

  void goToReferrals() {
    go(BasketScreen.referrals);
    loadReferrals();
  }

  void goToLoyalty() {
    go(BasketScreen.loyalty);
    loadLoyalty();
  }

  Future<void> loadReferrals() async {
    try {
      final summary = await api.auth.fetchReferrals();
      emit(state.copyWith(apiReferralSummary: summary));
    } catch (_) {}
  }

  /// Best-effort, like [loadSupportConfig] — also called from
  /// [_loadHomeData] so the points balance is ready before the user ever
  /// opens the loyalty screen (e.g. to show on the account screen).
  Future<void> loadLoyalty() async {
    try {
      final summary = await api.auth.fetchLoyalty();
      emit(state.copyWith(apiLoyaltySummary: summary, loyaltyPoints: summary.points));
    } catch (_) {}
  }

  Future<void> redeemLoyaltyPoints(int points) async {
    emit(state.copyWith(redeemSubmitting: true, clearRedeemMessage: true));
    try {
      final detail = await api.auth.redeemLoyaltyPoints(points);
      final summary = await api.auth.fetchLoyalty();
      emit(
        state.copyWith(
          redeemSubmitting: false,
          redeemMessage: detail,
          apiLoyaltySummary: summary,
          loyaltyPoints: summary.points,
        ),
      );
    } on ApiException catch (e) {
      emit(state.copyWith(redeemSubmitting: false, redeemMessage: e.message));
    }
  }
}
