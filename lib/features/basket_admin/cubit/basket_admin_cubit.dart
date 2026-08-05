import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_api.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_enums.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Owns every action in the Basket Admin console — sign in/out, sidebar
/// navigation + the data fetch each page needs, the order status/
/// assign-partner flow, and the coupon/banner/zone toggles — ported from
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

  Future<void> sendOtp() async {
    final mobile = state.mobileNumber.trim();
    if (mobile.isEmpty) {
      emit(state.copyWith(authError: 'Enter your work mobile number.'));
      return;
    }
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.sendOtp(mobile);
      emit(state.copyWith(authLoading: false, otpSent: true));
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  Future<void> resendOtp() async {
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.resendOtp(state.mobileNumber.trim());
      emit(state.copyWith(authLoading: false));
    } on ApiException catch (e) {
      emit(state.copyWith(authLoading: false, authError: e.message));
    }
  }

  /// Changes the number after `sendOtp`, back to the mobile-number step.
  void editMobileNumber() => emit(state.copyWith(otpSent: false, otpCode: '', clearAuthError: true));

  Future<void> verifyOtp() async {
    if (state.otpCode.trim().isEmpty) {
      emit(state.copyWith(authError: 'Enter the code we sent you.'));
      return;
    }
    emit(state.copyWith(authLoading: true, clearAuthError: true));
    try {
      await api.auth.verifyOtp(mobileNumber: state.mobileNumber.trim(), otpCode: state.otpCode.trim());
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
    await api.auth.logout();
    emit(const BasketAdminState());
  }

  // ── Shell-wide data (zone switcher) ─────────────────────────────────────

  void _loadShellData() {
    loadZones();
    loadDashboard();
  }

  Future<void> loadZones() async {
    try {
      final zones = await api.zones.fetchZones();
      emit(state.copyWith(apiZones: zones));
    } catch (_) {}
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
      case AdminPage.customers:
        loadCustomers();
      case AdminPage.partners:
        loadPartners();
      case AdminPage.coupons:
        loadCoupons();
      case AdminPage.banners:
        loadBanners();
      case AdminPage.notifs:
        loadNotifications();
      case AdminPage.sales:
        loadSales();
      case AdminPage.gst:
        loadGst();
      case AdminPage.zones:
        loadZones();
      case AdminPage.orderDet:
      case AdminPage.productNew:
        break;
    }
  }

  void goOrders() => go(AdminPage.orders);
  void goProducts() => go(AdminPage.products);
  void goProductNew() => go(AdminPage.productNew);
  void goCategories() => go(AdminPage.categories);
  void goInventory() => go(AdminPage.inventory);

  void cycleZone() {
    if (state.apiZones.isEmpty) return;
    emit(state.copyWith(zone: (state.zone + 1) % state.apiZones.length));
    if (state.page == AdminPage.inventory) loadStocks();
  }

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
    } on ApiException catch (_) {}
  }

  void openAssign() {
    if (state.apiPartners.isEmpty) loadPartners();
    emit(state.copyWith(modal: AdminModal.assign));
  }

  void closeModal() => emit(state.copyWith(modal: AdminModal.none));

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

  void setGstSlab(String slab) => emit(state.copyWith(gstSlab: slab));

  void toggleSkuZone(String zone) {
    final next = Map<String, bool>.from(state.skuZones);
    next[zone] = !(next[zone] ?? false);
    emit(state.copyWith(skuZones: next));
  }

  Future<void> loadCategories() async {
    try {
      final categories = await api.catalog.fetchCategories();
      emit(state.copyWith(apiCategories: categories));
    } catch (_) {}
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

  // ── Inventory ─────────────────────────────────────────────────────────

  Future<void> loadStocks() async {
    emit(state.copyWith(stocksLoading: true));
    try {
      final zoneId = state.apiZones.isNotEmpty && state.zone < state.apiZones.length ? state.apiZones[state.zone].id : null;
      final stocks = await api.catalog.fetchStocks(zone: zoneId);
      emit(state.copyWith(stocksLoading: false, apiStocks: stocks));
    } catch (_) {
      emit(state.copyWith(stocksLoading: false));
    }
  }

  Future<void> adjustStock(int stockId, int delta) async {
    try {
      final updated = await api.catalog.adjustStock(stockId, delta);
      final next = [
        for (final s in state.apiStocks) if (s.id == stockId) updated else s,
      ];
      emit(state.copyWith(apiStocks: next));
    } on ApiException catch (_) {}
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

  // ── Coupons / banners ────────────────────────────────────────────────

  Future<void> loadCoupons() async {
    try {
      final coupons = await api.promotions.fetchCoupons();
      emit(state.copyWith(apiCoupons: coupons));
    } catch (_) {}
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

  Future<void> toggleBanner(int id, bool isActive) async {
    try {
      final updated = await api.promotions.setBannerActive(id, isActive);
      final next = [
        for (final b in state.apiBanners) if (b.id == id) updated else b,
      ];
      emit(state.copyWith(apiBanners: next));
    } on ApiException catch (_) {}
  }

  // ── Zones & stores ────────────────────────────────────────────────────

  Future<void> toggleZoneStore(int id, bool isOpen) async {
    try {
      final updated = await api.zones.setZoneOpen(id, isOpen);
      final next = [
        for (final z in state.apiZones) if (z.id == id) updated else z,
      ];
      emit(state.copyWith(apiZones: next));
    } on ApiException catch (_) {}
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
      emit(state.copyWith(salesReport: report));
    } catch (_) {}
  }

  static const _gstMonthCodes = {'aug': '2026-08', 'jul': '2026-07', 'jun': '2026-06'};

  void setMonth(String month) {
    emit(state.copyWith(month: month));
    loadGst();
  }

  Future<void> loadGst() async {
    try {
      final report = await api.reports.fetchGst(month: _gstMonthCodes[state.month]);
      emit(state.copyWith(gstReport: report));
    } catch (_) {}
  }
}
