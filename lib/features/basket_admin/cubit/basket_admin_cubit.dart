import 'dart:async';

import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/models/report_models.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_api.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_enums.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns every action in the Basket Admin console — sign in/out, sidebar
/// navigation + the data fetch each page needs, the order status/
/// assign-partner flow, and the coupon/banner toggles — ported from
/// `Basket Admin.dc.html`'s `Component` class, with every page's mock
/// tables swapped for live calls through [BasketAdminApi].
class BasketAdminCubit extends Cubit<BasketAdminState> {
  BasketAdminCubit(this.api) : super(const BasketAdminState()) {
    _bootstrap();
  }

  final BasketAdminApi api;

  /// On cold start, if a token is already stored (from a previous run),
  /// try to resume the session instead of forcing sign-in again — but only
  /// onto the console itself if that account is still `role='admin'`.
  Future<void> _bootstrap() async {
    if (!await api.auth.hasSession()) return;
    try {
      final profile = await api.auth.fetchProfile();
      if (profile != null && profile.isAdmin) {
        emit(state.copyWith(
          screen: AdminScreen.app,
          page: AdminPage.dash,
          adminName: profile.name,
          adminMobile: profile.mobileNumber,
        ));
        _loadShellData();
      } else {
        await api.auth.logout();
      }
    } catch (_) {
      // Stale/expired token with no network to refresh it — fall back to
      // the sign-in screen rather than getting stuck on a blank state.
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────

  void setMobileNumber(String value) => emit(state.copyWith(mobileNumber: value, clearAuthError: true));

  void setOtpCode(String value) => emit(state.copyWith(otpCode: value, clearAuthError: true));

  /// Admin sign-in is master-OTP only (`settings.MASTER_OTP`) — no SMS, no
  /// OTP row, so there's nothing to actually "send". This just moves the
  /// UI to the code-entry step; [verifyOtp] does the real network call.
  Future<void> sendOtp() async {
    final mobile = state.mobileNumber.trim();
    if (mobile.isEmpty) {
      emit(state.copyWith(authError: 'Enter your work mobile number.'));
      return;
    }
    emit(state.copyWith(otpSent: true, clearAuthError: true));
  }

  /// Changes the number after `sendOtp`, back to the mobile-number step.
  void editMobileNumber() => emit(state.copyWith(otpSent: false, otpCode: '', clearAuthError: true));

  Future<void> verifyOtp() async {
    if (state.otpCode.trim().isEmpty) {
      emit(state.copyWith(authError: 'Enter your admin access code.'));
      return;
    }
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.masterLogin(mobileNumber: state.mobileNumber.trim(), masterOtp: state.otpCode.trim());
      final profile = await api.auth.fetchProfile();
      if (profile == null || !profile.isAdmin) {
        await api.auth.logout();
        emit(state.copyWith(
          authLoading: false,
          authError: 'This account does not have console access. Ask ops to grant the admin role.',
        ));
        return;
      }
      emit(state.copyWith(
        authLoading: false,
        screen: AdminScreen.app,
        page: AdminPage.dash,
        adminName: profile.name,
        adminMobile: profile.mobileNumber,
      ));
      _loadShellData();
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  Future<void> signOut() async {
    _stopNewOrdersPolling();
    await api.auth.logout();
    emit(const BasketAdminState());
  }

  // ── Shell-wide data (store) ──────────────────────────────────────────────

  void _loadShellData() {
    loadDashboard();
    _startNewOrdersPolling();
  }

  // ── New-order badge ───────────────────────────────────────────────────

  static const _newOrdersPollInterval = Duration(seconds: 30);
  Timer? _newOrdersPoll;

  /// Whether [refreshNewOrdersCount] has a real baseline yet — the first
  /// fetch after sign-in only sets the count, it never fires the
  /// "new order" alert for orders that were already waiting.
  bool _newOrdersBaselineSet = false;

  void _startNewOrdersPolling() {
    _stopNewOrdersPolling();
    refreshNewOrdersCount();
    _newOrdersPoll = Timer.periodic(_newOrdersPollInterval, (_) => refreshNewOrdersCount());
  }

  void _stopNewOrdersPolling() {
    _newOrdersPoll?.cancel();
    _newOrdersPoll = null;
    _newOrdersBaselineSet = false;
  }

  /// Re-reads how many orders are still `new`. If that went up since the
  /// last check, bumps [BasketAdminState.newOrderAlertSeq] (the shell shows
  /// a snackbar for it) and refreshes the Orders table if it's open.
  Future<void> refreshNewOrdersCount() async {
    if (state.screen != AdminScreen.app) return;
    try {
      final count = await api.orders.countOrders(status: kOrderStatusToCode['New']);
      if (isClosed || state.screen != AdminScreen.app) return;
      final arrived = count - state.newOrdersCount;
      if (_newOrdersBaselineSet && arrived > 0) {
        emit(state.copyWith(
          newOrdersCount: count,
          newOrderAlertSeq: state.newOrderAlertSeq + 1,
          newOrderAlertCount: arrived,
        ));
        if (state.page == AdminPage.orders) loadOrders();
        if (state.page == AdminPage.dash) loadDashboard();
      } else {
        emit(state.copyWith(newOrdersCount: count));
      }
      _newOrdersBaselineSet = true;
    } catch (_) {
      // Network blip — keep the last known count, try again next tick.
    }
  }

  /// Bell / snackbar "View": the Orders page filtered to just `New`.
  void goNewOrders() {
    emit(state.copyWith(status: 'New'));
    go(AdminPage.orders);
  }

  // ── Navigation ────────────────────────────────────────────────────────

  void go(AdminPage page) {
    emit(state.copyWith(page: page, modal: AdminModal.none));
    _loadForPage(page);
  }

  void _loadForPage(AdminPage page) {
    switch (page) {
      case AdminPage.dash:
        loadDashboard();
      case AdminPage.orders:
        loadOrders();
      case AdminPage.products:
        loadProducts();
        if (state.apiCategories.isEmpty) loadCategories();
      case AdminPage.categories:
        loadCategories();
      case AdminPage.inventory:
        loadStocks();
        loadStocksSummary();
        if (state.apiCategories.isEmpty) loadCategories();
      case AdminPage.customers:
        loadCustomers();
      case AdminPage.partners:
        loadPartners();
      case AdminPage.coupons:
        loadCoupons();
      case AdminPage.banners:
        loadBanners();
      case AdminPage.festivals:
        loadFestivalSettings();
      case AdminPage.notifs:
        loadNotifications();
      case AdminPage.delivery:
        loadDeliverySettings();
      case AdminPage.sales:
        loadSales();
        loadDeliveredSales();
      case AdminPage.gst:
        loadGst();
        loadGstRates();
        if (state.storeSettings == null) loadStoreSettings();
      case AdminPage.orderDet:
      case AdminPage.productNew:
      case AdminPage.appUpdate:
        break;
    }
  }

  void goOrders() => go(AdminPage.orders);
  void goProducts() => go(AdminPage.products);

  /// [product] null opens a blank draft (create); non-null opens that
  /// product prefilled (edit) — see `AdminProductNewView`.
  void goProductNew({ApiProduct? product}) {
    emit(state.copyWith(
      page: AdminPage.productNew,
      modal: AdminModal.none,
      currentProduct: product,
      clearCurrentProduct: product == null,
    ));
    loadGstRates();
  }

  void goCategories() => go(AdminPage.categories);
  void goInventory() => go(AdminPage.inventory);

  // ── Dashboard ─────────────────────────────────────────────────────────

  void setRange(String range) => emit(state.copyWith(range: range));

  Future<void> loadDashboard() async {
    emit(state.copyWith(dashboardLoading: true));
    try {
      final report = await api.reports.fetchDashboard();
      emit(state.copyWith(dashboardLoading: false, dashboardReport: report));
    } catch (_) {
      emit(state.copyWith(dashboardLoading: false));
    }
  }

  // ── Orders ────────────────────────────────────────────────────────────

  void setStatus(String status) {
    emit(state.copyWith(status: status));
    loadOrders();
  }

  Future<void> loadOrders() async {
    emit(state.copyWith(ordersLoading: true));
    try {
      final code = state.status == 'All' ? null : kOrderStatusToCode[state.status];
      final orders = await api.orders.fetchOrders(status: code);
      emit(state.copyWith(ordersLoading: false, apiOrders: orders));
    } catch (_) {
      emit(state.copyWith(ordersLoading: false));
    }
  }

  Future<void> openOrder(String id) async {
    emit(state.copyWith(page: AdminPage.orderDet, sel: id, modal: AdminModal.none));
    final orderId = int.tryParse(id);
    if (orderId == null) return;
    try {
      if (state.apiPartners.isEmpty) await loadPartners();
      final order = await api.orders.fetchOrder(orderId);
      final matches = state.apiPartners.where((p) => p.id == order.deliveryPartnerId);
      emit(state.copyWith(
        currentOrder: order,
        orderStatus: kOrderStatusFromCode[order.status] ?? order.status,
        assign: matches.isNotEmpty ? matches.first : null,
        clearAssign: matches.isEmpty,
      ));
    } on ApiException catch (_) {}
  }

  Future<void> setOrderStatus(String status) async {
    emit(state.copyWith(orderStatus: status));
    final orderId = int.tryParse(state.sel);
    final code = kOrderStatusToCode[status];
    if (orderId == null || code == null) return;
    try {
      final order = await api.orders.setStatus(orderId, code);
      emit(state.copyWith(currentOrder: order));
      loadOrders();
      refreshNewOrdersCount();
    } on ApiException catch (_) {}
  }

  void openAssign() {
    if (state.apiPartners.isEmpty) loadPartners();
    emit(state.copyWith(modal: AdminModal.assign));
  }

  void closeModal() => emit(state.copyWith(
        modal: AdminModal.none,
        clearEditingPartner: true,
        clearEditingCategory: true,
        clearEditingCoupon: true,
        clearEditingBanner: true,
        clearEditingFestivalSetting: true,
      ));

  /// [category] null opens the form blank (create); non-null opens it
  /// prefilled (edit) — see `AddCategoryModal`.
  void openAddCategory({ApiCategory? category}) {
    emit(state.copyWith(modal: AdminModal.addCategory, editingCategory: category, clearEditingCategory: category == null));
  }

  /// [subcategory] null opens the form blank (create, under [category]);
  /// non-null opens it prefilled (edit) — see `AddSubcategoryModal`.
  void openAddSubcategory({required ApiCategory category, ApiSubcategory? subcategory}) {
    emit(
      state.copyWith(
        modal: AdminModal.addSubcategory,
        addSubcategoryCategory: category,
        editingSubcategory: subcategory,
        clearEditingSubcategory: subcategory == null,
      ),
    );
  }

  /// [coupon] null opens the form blank (create); non-null opens it
  /// prefilled (edit) — see `AddCouponModal`.
  void openAddCoupon({ApiCoupon? coupon}) {
    emit(state.copyWith(modal: AdminModal.addCoupon, editingCoupon: coupon, clearEditingCoupon: coupon == null));
  }

  /// [banner] null opens the form blank (create); non-null opens it
  /// prefilled (edit) — see `AddBannerModal`.
  void openAddBanner({ApiBanner? banner}) {
    emit(state.copyWith(modal: AdminModal.addBanner, editingBanner: banner, clearEditingBanner: banner == null));
  }

  /// [partner] null opens the form blank (create); non-null opens it
  /// prefilled (edit) — see `PartnerFormModal`.
  void openPartnerForm({ApiDeliveryPartner? partner}) {
    emit(state.copyWith(modal: AdminModal.partnerForm, editingPartner: partner, clearEditingPartner: partner == null));
  }

  void pickAssign(ApiDeliveryPartner partner) => emit(state.copyWith(assign: partner));

  /// Confirms the currently-picked partner and, if the order was `New`,
  /// advances it to `Packed` — matching the source design's
  /// `confirmAssign` (the backend does this same auto-advance server-side).
  Future<void> confirmAssign() async {
    final partner = state.assign;
    final orderId = int.tryParse(state.sel);
    if (partner == null || orderId == null) {
      emit(state.copyWith(modal: AdminModal.none));
      return;
    }
    try {
      final order = await api.orders.assignPartner(orderId, partner.id);
      emit(state.copyWith(
        modal: AdminModal.none,
        currentOrder: order,
        orderStatus: kOrderStatusFromCode[order.status] ?? order.status,
      ));
      loadOrders();
      refreshNewOrdersCount();
    } on ApiException catch (_) {
      emit(state.copyWith(modal: AdminModal.none));
    }
  }

  /// "Assign" action from a Partners-page row: jumps to that partner's
  /// current order (if on a trip, otherwise nothing to jump to) with the
  /// assign modal open. Falls back to whatever order is already `sel`.
  void assignPartnerFromRow(ApiDeliveryPartner partner) {
    emit(state.copyWith(page: AdminPage.orderDet, modal: AdminModal.assign, assign: partner));
  }

  // ── Products / Categories ────────────────────────────────────────────

  /// Holds a category *key* (or `'All'`) — `admin_products_view` builds its
  /// tabs from the real [BasketAdminState.apiCategories] now, not the old
  /// static mock list.
  void setCatTab(String key) => emit(state.copyWith(catTab: key));

  Future<void> loadCategories() async {
    emit(state.copyWith(categoriesLoading: true));
    try {
      final categories = await api.catalog.fetchCategories();
      emit(state.copyWith(categoriesLoading: false, apiCategories: categories));
    } catch (_) {
      emit(state.copyWith(categoriesLoading: false));
    }
    loadSubcategories();
  }

  /// Unfiltered — every subcategory across every category, so the
  /// Categories page can render each card's chips (filtered client-side by
  /// `categoryId`) without a fetch per card.
  Future<void> loadSubcategories() async {
    try {
      final subcategories = await api.catalog.fetchSubcategories();
      emit(state.copyWith(apiSubcategories: subcategories));
    } catch (_) {}
  }

  /// Rethrows [ApiException] like [createCategory] — see that method's doc.
  Future<ApiSubcategory> createSubcategory(Map<String, dynamic> data) async {
    final created = await api.catalog.createSubcategory(data);
    emit(state.copyWith(apiSubcategories: [...state.apiSubcategories, created]));
    return created;
  }

  Future<ApiSubcategory> updateSubcategory(int id, Map<String, dynamic> data) async {
    final updated = await api.catalog.updateSubcategory(id, data);
    final next = [for (final s in state.apiSubcategories) if (s.id == id) updated else s];
    emit(state.copyWith(apiSubcategories: next));
    return updated;
  }

  Future<void> deleteSubcategory(int id) async {
    await api.catalog.deleteSubcategory(id);
    emit(state.copyWith(apiSubcategories: state.apiSubcategories.where((s) => s.id != id).toList()));
  }

  /// Rethrows [ApiException] rather than swallowing it (unlike the `load*`
  /// methods above) — the caller is always a modal/form with its own local
  /// loading spinner and inline error text, so it needs the failure back.
  Future<ApiCategory> createCategory(Map<String, dynamic> data) async {
    final created = await api.catalog.createCategory(data);
    emit(state.copyWith(apiCategories: [...state.apiCategories, created]));
    return created;
  }

  Future<ApiCategory> updateCategory(String key, Map<String, dynamic> data) async {
    final updated = await api.catalog.updateCategory(key, data);
    final next = [for (final c in state.apiCategories) if (c.key == key) updated else c];
    emit(state.copyWith(apiCategories: next));
    return updated;
  }

  Future<void> deleteCategory(String key) async {
    await api.catalog.deleteCategory(key);
    emit(state.copyWith(apiCategories: state.apiCategories.where((c) => c.key != key).toList()));
  }

  Future<void> loadProducts() async {
    emit(state.copyWith(productsLoading: true));
    try {
      final products = await api.catalog.fetchProducts(ordering: 'name');
      emit(state.copyWith(productsLoading: false, apiProducts: products));
    } catch (_) {
      emit(state.copyWith(productsLoading: false));
    }
  }

  Future<ApiProduct> createProduct(Map<String, dynamic> data) async {
    final created = await api.catalog.createProduct(data);
    emit(state.copyWith(apiProducts: [...state.apiProducts, created]));
    return created;
  }

  Future<ApiProduct> updateProduct(int id, Map<String, dynamic> data) async {
    final updated = await api.catalog.updateProduct(id, data);
    final next = [for (final p in state.apiProducts) if (p.id == id) updated else p];
    emit(state.copyWith(apiProducts: next));
    return updated;
  }

  Future<void> deleteProduct(int id) async {
    await api.catalog.deleteProduct(id);
    emit(state.copyWith(apiProducts: state.apiProducts.where((p) => p.id != id).toList()));
  }

  /// Rethrows [ApiException] (unlike the fire-and-forget toggles below) so
  /// the row can surface *why* a toggle failed instead of just silently
  /// staying on its old state.
  Future<void> toggleProduct(int id, bool isActive) async {
    final updated = await api.catalog.setProductActive(id, isActive);
    final next = [
      for (final p in state.apiProducts) if (p.id == id) updated else p,
    ];
    emit(state.copyWith(apiProducts: next));
  }

  // ── Inventory ─────────────────────────────────────────────────────────

  static const stockPageSize = 20;

  Future<void> loadStocks() async {
    emit(state.copyWith(stocksLoading: true));
    try {
      final page = await api.catalog.fetchStocks(
        category: state.stockCatTab == 'All' ? null : state.stockCatTab,
        state: state.stockState,
        search: state.stockSearch,
        page: state.stockPage,
        pageSize: stockPageSize,
      );
      emit(state.copyWith(stocksLoading: false, apiStocks: page.items, stockCount: page.count));
    } catch (_) {
      emit(state.copyWith(stocksLoading: false));
    }
  }

  /// The 4 stat cards need true totals across all inventory — the table
  /// itself only ever holds one filtered/paginated page, which is never
  /// the right source for "how many SKUs are out of stock overall".
  Future<void> loadStocksSummary() async {
    try {
      final summary = await api.catalog.fetchStocksSummary();
      emit(state.copyWith(stockSummary: summary));
    } catch (_) {}
  }

  void setStockCatTab(String key) {
    emit(state.copyWith(stockCatTab: key, stockPage: 1));
    loadStocks();
  }

  /// [stateFilter] null means "All states".
  void setStockStateFilter(String? stateFilter) {
    emit(state.copyWith(stockState: stateFilter, clearStockState: stateFilter == null, stockPage: 1));
    loadStocks();
  }

  Timer? _stockSearchDebounce;

  void setStockSearch(String query) {
    emit(state.copyWith(stockSearch: query, stockPage: 1));
    _stockSearchDebounce?.cancel();
    _stockSearchDebounce = Timer(const Duration(milliseconds: 400), loadStocks);
  }

  void goToStockPage(int page) {
    emit(state.copyWith(stockPage: page));
    loadStocks();
  }

  Future<void> adjustStock(int stockId, int delta) async {
    final updated = await api.catalog.adjustStock(stockId, delta);
    final next = [
      for (final s in state.apiStocks) if (s.id == stockId) updated else s,
    ];
    emit(state.copyWith(apiStocks: next));
    // A single row's on_hand crossing the reorder threshold (or hitting
    // zero) changes the global low/out-of-stock counts, so the summary
    // cards need a refresh too — not just the row that moved.
    loadStocksSummary();
  }

  @override
  Future<void> close() {
    _stockSearchDebounce?.cancel();
    _newOrdersPoll?.cancel();
    return super.close();
  }

  // ── Customers / Partners ─────────────────────────────────────────────

  Future<void> loadCustomers() async {
    emit(state.copyWith(customersLoading: true));
    try {
      final customers = await api.reports.fetchCustomers();
      emit(state.copyWith(customersLoading: false, apiCustomers: customers));
    } catch (_) {
      emit(state.copyWith(customersLoading: false));
    }
  }

  Future<void> loadPartners() async {
    emit(state.copyWith(partnersLoading: true));
    try {
      final partners = await api.delivery.fetchPartners();
      emit(state.copyWith(partnersLoading: false, apiPartners: partners));
    } catch (_) {
      emit(state.copyWith(partnersLoading: false));
    }
  }

  Future<ApiDeliveryPartner> createPartner(Map<String, dynamic> data) async {
    final created = await api.delivery.createPartner(data);
    emit(state.copyWith(apiPartners: [...state.apiPartners, created]));
    return created;
  }

  Future<ApiDeliveryPartner> updatePartner(int id, Map<String, dynamic> data) async {
    final updated = await api.delivery.updatePartner(id, data);
    final next = [for (final p in state.apiPartners) if (p.id == id) updated else p];
    emit(state.copyWith(apiPartners: next));
    return updated;
  }

  // ── Coupons / banners ────────────────────────────────────────────────

  Future<void> loadCoupons() async {
    try {
      final coupons = await api.promotions.fetchCoupons();
      emit(state.copyWith(apiCoupons: coupons));
    } catch (_) {}
  }

  Future<ApiCoupon> createCoupon(Map<String, dynamic> data) async {
    final created = await api.promotions.createCoupon(data);
    emit(state.copyWith(apiCoupons: [...state.apiCoupons, created]));
    return created;
  }

  Future<ApiCoupon> updateCoupon(String code, Map<String, dynamic> data) async {
    final updated = await api.promotions.updateCoupon(code, data);
    final next = [for (final c in state.apiCoupons) if (c.code == code) updated else c];
    emit(state.copyWith(apiCoupons: next));
    return updated;
  }

  Future<void> deleteCoupon(String code) async {
    await api.promotions.deleteCoupon(code);
    emit(state.copyWith(apiCoupons: state.apiCoupons.where((c) => c.code != code).toList()));
  }

  Future<void> toggleCoupon(String code, bool isActive) async {
    try {
      final updated = await api.promotions.setCouponActive(code, isActive);
      final next = [
        for (final c in state.apiCoupons) if (c.code == code) updated else c,
      ];
      emit(state.copyWith(apiCoupons: next));
    } on ApiException catch (_) {}
  }

  Future<void> loadBanners() async {
    try {
      final banners = await api.promotions.fetchBanners();
      emit(state.copyWith(apiBanners: banners));
    } catch (_) {}
  }

  Future<ApiBanner> createBanner(Map<String, dynamic> data) async {
    final created = await api.promotions.createBanner(data);
    emit(state.copyWith(apiBanners: [...state.apiBanners, created]));
    return created;
  }

  Future<void> toggleBanner(int id, bool isActive) async {
    try {
      final updated = await api.promotions.setBannerActive(id, isActive);
      final next = [
        for (final b in state.apiBanners) if (b.id == id) updated else b,
      ];
      emit(state.copyWith(apiBanners: next));
    } on ApiException catch (_) {}
  }

  Future<ApiBanner> updateBanner(int id, Map<String, dynamic> data) async {
    final updated = await api.promotions.updateBanner(id, data);
    final next = [for (final b in state.apiBanners) if (b.id == id) updated else b];
    emit(state.copyWith(apiBanners: next));
    return updated;
  }

  Future<void> deleteBanner(int id) async {
    await api.promotions.deleteBanner(id);
    emit(state.copyWith(apiBanners: state.apiBanners.where((b) => b.id != id).toList()));
  }

  Future<void> loadFestivalSettings() async {
    try {
      final settings = await api.promotions.fetchFestivalSettings();
      emit(state.copyWith(apiFestivalSettings: settings));
    } catch (_) {}
  }

  /// Opens the edit form for one festival's row — see
  /// `AdminFestivalSettingsView`. Unlike banners, there's always exactly
  /// one row per festival (seeded server-side), so this only ever edits.
  void openEditFestivalSetting(ApiFestivalSetting setting) {
    emit(state.copyWith(modal: AdminModal.editFestival, editingFestivalSetting: setting));
  }

  Future<ApiFestivalSetting> updateFestivalSetting(int id, Map<String, dynamic> data) async {
    final updated = await api.promotions.updateFestivalSetting(id, data);
    final next = [for (final s in state.apiFestivalSettings) if (s.id == id) updated else s];
    emit(state.copyWith(apiFestivalSettings: next));
    return updated;
  }

  // ── Notifications ─────────────────────────────────────────────────────

  void setAudience(String audience) => emit(state.copyWith(audience: audience));

  Future<void> loadNotifications() async {
    try {
      final notifications = await api.promotions.fetchNotifications();
      emit(state.copyWith(apiNotifications: notifications));
    } catch (_) {}
  }

  /// Composes and immediately sends a campaign to the current [audience] —
  /// collapses the source design's separate "compose" (local-only) and
  /// "send" steps into one real call, since there's no draft-editing UI.
  Future<void> sendNotification({required String title, required String body}) async {
    try {
      final draft = await api.promotions.createNotification(title: title, body: body, audience: _audienceCode(state.audience));
      await api.promotions.sendNotification(draft.id);
      loadNotifications();
    } on ApiException catch (_) {}
  }

  String _audienceCode(String label) => switch (label) {
        'Cart abandoners' => 'cart_abandoners',
        'Gold + Platinum' => 'gold_platinum',
        _ => 'all',
      };

  // ── Sales / GST reports ──────────────────────────────────────────────

  Future<void> loadSales() async {
    try {
      final report = await api.reports.fetchSales();
      emit(state.copyWith(salesReport: report, clearSalesError: true));
    } on ApiException catch (e) {
      // Without this, a failure left `salesReport` null forever with no
      // way to tell "still loading" from "failed" — the screen just spun
      // indefinitely instead of showing what actually went wrong.
      emit(state.copyWith(salesError: e.message));
    }
  }

  /// Loads the "Delivered sales" report for [period] (or the current tab).
  Future<void> loadDeliveredSales([String? period]) async {
    final p = period ?? state.deliveredSalesPeriod;
    emit(state.copyWith(deliveredSalesPeriod: p, deliveredSalesLoading: true, clearDeliveredSalesError: true));
    try {
      final report = await api.reports.fetchDeliveredSales(period: p);
      // A faster tab switch may have superseded this request.
      if (state.deliveredSalesPeriod != p) return;
      emit(state.copyWith(deliveredSales: report, deliveredSalesLoading: false));
    } on ApiException catch (e) {
      if (state.deliveredSalesPeriod != p) return;
      emit(state.copyWith(deliveredSalesLoading: false, deliveredSalesError: e.message));
    }
  }

  /// month state key ('aug'/'jul'/'jun') -> the "YYYY-MM" the report
  /// endpoints expect. Also used directly by [AdminGstView] to build the
  /// GSTR-1/GSTR-3B export requests for whichever month pill is selected.
  static const gstMonthCodes = {'aug': '2026-08', 'jul': '2026-07', 'jun': '2026-06'};

  void setMonth(String month) {
    emit(state.copyWith(month: month));
    loadGst();
  }

  Future<void> loadGst() async {
    try {
      final report = await api.reports.fetchGst(month: gstMonthCodes[state.month]);
      emit(state.copyWith(gstReport: report, clearGstError: true));
    } on ApiException catch (e) {
      emit(state.copyWith(gstError: e.message));
    }
  }

  // ── GST rates (CGST + SGST) ─────────────────────────────────────────

  Future<void> loadGstRates() async {
    try {
      final rates = await api.catalog.fetchGstRates();
      emit(state.copyWith(gstRates: rates));
    } on ApiException catch (_) {
      // Best-effort — the product form falls back to its current value.
    }
  }

  /// Creates ([id] null) or updates a GST rate. Returns an error message,
  /// or null on success.
  Future<String?> saveGstRate({int? id, required String name, required double cgstPct, required double sgstPct}) async {
    final data = {'name': name, 'cgst_pct': cgstPct.toStringAsFixed(2), 'sgst_pct': sgstPct.toStringAsFixed(2)};
    try {
      if (id == null) {
        await api.catalog.createGstRate(data);
      } else {
        await api.catalog.updateGstRate(id, data);
      }
      await loadGstRates();
      // Products on an edited rate now have a different customer price.
      if (id != null) loadProducts();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteGstRate(int id) async {
    try {
      await api.catalog.deleteGstRate(id);
      await loadGstRates();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// The seller's own GST profile (business name/address/GSTIN) shown on
  /// the GST screen's settings panel — see `StoreSettingsView`.
  Future<void> loadStoreSettings() async {
    try {
      final settings = await api.reports.fetchStoreSettings();
      emit(state.copyWith(storeSettings: settings, clearStoreSettingsError: true));
    } on ApiException catch (e) {
      emit(state.copyWith(storeSettingsError: e.message));
    }
  }

  /// Saves the GST settings panel's edits — takes effect on the very next
  /// invoice/GSTR-1/GSTR-3B generated, no deploy needed.
  Future<bool> saveStoreSettings(StoreGstSettings settings) async {
    emit(state.copyWith(storeSettingsSaving: true, clearStoreSettingsError: true));
    try {
      final saved = await api.reports.updateStoreSettings(settings);
      emit(state.copyWith(storeSettings: saved, storeSettingsSaving: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(storeSettingsSaving: false, storeSettingsError: e.message));
      return false;
    }
  }

  // ── Delivery charges ────────────────────────────────────────────────

  Future<void> loadDeliverySettings() async {
    try {
      final settings = await api.reports.fetchDeliverySettings();
      emit(state.copyWith(deliverySettings: settings, clearDeliverySettingsError: true));
    } on ApiException catch (e) {
      emit(state.copyWith(deliverySettingsError: e.message));
    }
  }

  Future<bool> saveDeliverySettings(ApiDeliverySettings settings) async {
    emit(state.copyWith(deliverySettingsSaving: true, clearDeliverySettingsError: true));
    try {
      final saved = await api.reports.updateDeliverySettings(settings);
      emit(state.copyWith(deliverySettings: saved, deliverySettingsSaving: false));
      return true;
    } on ApiException catch (e) {
      emit(state.copyWith(deliverySettingsSaving: false, deliverySettingsError: e.message));
      return false;
    }
  }
}
