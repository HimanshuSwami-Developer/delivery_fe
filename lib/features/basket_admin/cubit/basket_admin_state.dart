import 'package:equatable/equatable.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/models/report_models.dart';
import 'package:fastswipe/core/basket_api/models/zone_models.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_enums.dart';

/// Single immutable state for the whole Basket Admin console, mirroring the
/// source design's one-component `state` object (see `Basket Admin.dc.html`).
/// Navigation is a flat `page` field, not a back-stack — the only two pages
/// reached by drilling in (`orderDet`, `productNew`) both have an explicit
/// "back" affordance that returns straight to their list page, matching the
/// source exactly.
class BasketAdminState extends Equatable {
  const BasketAdminState({
    this.screen = AdminScreen.login,
    this.page = AdminPage.dash,
    this.mobileNumber = '',
    this.otpCode = '',
    this.otpSent = false,
    this.authLoading = false,
    this.authError,
    this.adminName,
    this.adminMobile,
    this.zone = 0,
    this.range = '14d',
    this.catTab = 'All',
    this.status = 'All',
    this.sel = '',
    this.modal = AdminModal.none,
    this.assign,
    this.orderStatus = 'new',
    this.month = 'aug',
    this.audience = 'All users',
    this.apiZones = const [],
    this.apiOrders = const [],
    this.ordersLoading = false,
    this.currentOrder,
    this.apiCategories = const [],
    this.apiProducts = const [],
    this.productsLoading = false,
    this.currentProduct,
    this.apiStocks = const [],
    this.stocksLoading = false,
    this.apiCustomers = const [],
    this.customersLoading = false,
    this.apiPartners = const [],
    this.partnersLoading = false,
    this.editingPartner,
    this.apiCoupons = const [],
    this.editingCoupon,
    this.editingCategory,
    this.apiBanners = const [],
    this.editingBanner,
    this.apiNotifications = const [],
    this.dashboardReport,
    this.dashboardLoading = false,
    this.salesReport,
    this.gstReport,
  });

  final AdminScreen screen;
  final AdminPage page;

  /// Mobile number entered on the sign-in form (E.164-ish, e.g. `+91...`).
  final String mobileNumber;

  /// OTP code entered after `sendOtp` succeeds.
  final String otpCode;

  /// Whether `sendOtp` has succeeded — switches the form from
  /// "enter mobile number" to "enter the code we sent".
  final bool otpSent;

  final bool authLoading;
  final String? authError;

  /// The signed-in admin's display name/mobile (from `GET /auth/profile/`),
  /// shown in the sidebar profile row in place of the source design's
  /// static "Priya N.".
  final String? adminName;
  final String? adminMobile;

  /// Index into [apiZones] for the header's zone switcher.
  final int zone;

  /// Dashboard sales-chart range pill: `'7d' | '14d' | '30d'` (cosmetic
  /// only — the chart values don't actually change, matching the source).
  final String range;

  /// Products page category-tab filter.
  final String catTab;

  /// Orders page status-tab filter.
  final String status;

  /// Selected order id for the order-detail screen.
  final String sel;

  final AdminModal modal;

  /// Delivery partner currently assigned/selected in the assign flow, or
  /// null when the selected order has none.
  final ApiDeliveryPartner? assign;

  /// Status shown/edited on the order-detail screen for [sel].
  final String orderStatus;

  /// GST report month key: `'aug' | 'jul' | 'jun'`.
  final String month;

  /// Notification compose audience.
  final String audience;

  // ── Live backend data (fetched via BasketAdminApi; see BasketAdminCubit) ──

  /// Real dark stores/zones — [zone] indexes into this.
  final List<ApiZone> apiZones;

  final List<ApiOrder> apiOrders;
  final bool ordersLoading;

  /// Full detail (with line items) for [sel], fetched by `openOrder`.
  final ApiOrder? currentOrder;

  final List<ApiCategory> apiCategories;
  final List<ApiProduct> apiProducts;
  final bool productsLoading;

  /// The product shown on the Add/Edit Product page.
  final ApiProduct? currentProduct;

  final List<ApiProductStock> apiStocks;
  final bool stocksLoading;

  final List<AdminCustomerRow> apiCustomers;
  final bool customersLoading;

  final List<ApiDeliveryPartner> apiPartners;
  final bool partnersLoading;

  /// The partner shown on [AdminModal.partnerForm] — null means the modal
  /// is creating a new one, non-null means it's editing this one.
  final ApiDeliveryPartner? editingPartner;

  final List<ApiCoupon> apiCoupons;

  /// The coupon shown on [AdminModal.addCoupon] — null means the modal is
  /// creating a new one, non-null means it's editing this one.
  final ApiCoupon? editingCoupon;

  /// The category shown on [AdminModal.addCategory] — null means create,
  /// non-null means edit.
  final ApiCategory? editingCategory;

  final List<ApiBanner> apiBanners;

  /// The banner shown on [AdminModal.addBanner] — null means the modal is
  /// creating a new one, non-null means it's editing this one.
  final ApiBanner? editingBanner;

  final List<ApiNotification> apiNotifications;

  final DashboardReport? dashboardReport;
  final bool dashboardLoading;
  final SalesReport? salesReport;
  final GstReport? gstReport;

  BasketAdminState copyWith({
    AdminScreen? screen,
    AdminPage? page,
    String? mobileNumber,
    String? otpCode,
    bool? otpSent,
    bool? authLoading,
    String? authError,
    bool clearAuthError = false,
    String? adminName,
    String? adminMobile,
    int? zone,
    String? range,
    String? catTab,
    String? status,
    String? sel,
    AdminModal? modal,
    ApiDeliveryPartner? assign,
    bool clearAssign = false,
    String? orderStatus,
    String? month,
    String? audience,
    List<ApiZone>? apiZones,
    List<ApiOrder>? apiOrders,
    bool? ordersLoading,
    ApiOrder? currentOrder,
    List<ApiCategory>? apiCategories,
    List<ApiProduct>? apiProducts,
    bool? productsLoading,
    ApiProduct? currentProduct,
    bool clearCurrentProduct = false,
    List<ApiProductStock>? apiStocks,
    bool? stocksLoading,
    List<AdminCustomerRow>? apiCustomers,
    bool? customersLoading,
    List<ApiDeliveryPartner>? apiPartners,
    bool? partnersLoading,
    ApiDeliveryPartner? editingPartner,
    bool clearEditingPartner = false,
    List<ApiCoupon>? apiCoupons,
    ApiCoupon? editingCoupon,
    bool clearEditingCoupon = false,
    ApiCategory? editingCategory,
    bool clearEditingCategory = false,
    List<ApiBanner>? apiBanners,
    ApiBanner? editingBanner,
    bool clearEditingBanner = false,
    List<ApiNotification>? apiNotifications,
    DashboardReport? dashboardReport,
    bool? dashboardLoading,
    SalesReport? salesReport,
    GstReport? gstReport,
  }) {
    return BasketAdminState(
      screen: screen ?? this.screen,
      page: page ?? this.page,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      otpCode: otpCode ?? this.otpCode,
      otpSent: otpSent ?? this.otpSent,
      authLoading: authLoading ?? this.authLoading,
      authError: clearAuthError ? null : (authError ?? this.authError),
      adminName: adminName ?? this.adminName,
      adminMobile: adminMobile ?? this.adminMobile,
      zone: zone ?? this.zone,
      range: range ?? this.range,
      catTab: catTab ?? this.catTab,
      status: status ?? this.status,
      sel: sel ?? this.sel,
      modal: modal ?? this.modal,
      assign: clearAssign ? null : (assign ?? this.assign),
      orderStatus: orderStatus ?? this.orderStatus,
      month: month ?? this.month,
      audience: audience ?? this.audience,
      apiZones: apiZones ?? this.apiZones,
      apiOrders: apiOrders ?? this.apiOrders,
      ordersLoading: ordersLoading ?? this.ordersLoading,
      currentOrder: currentOrder ?? this.currentOrder,
      apiCategories: apiCategories ?? this.apiCategories,
      apiProducts: apiProducts ?? this.apiProducts,
      productsLoading: productsLoading ?? this.productsLoading,
      currentProduct: clearCurrentProduct ? null : (currentProduct ?? this.currentProduct),
      apiStocks: apiStocks ?? this.apiStocks,
      stocksLoading: stocksLoading ?? this.stocksLoading,
      apiCustomers: apiCustomers ?? this.apiCustomers,
      customersLoading: customersLoading ?? this.customersLoading,
      apiPartners: apiPartners ?? this.apiPartners,
      partnersLoading: partnersLoading ?? this.partnersLoading,
      editingPartner: clearEditingPartner ? null : (editingPartner ?? this.editingPartner),
      apiCoupons: apiCoupons ?? this.apiCoupons,
      editingCoupon: clearEditingCoupon ? null : (editingCoupon ?? this.editingCoupon),
      editingCategory: clearEditingCategory ? null : (editingCategory ?? this.editingCategory),
      apiBanners: apiBanners ?? this.apiBanners,
      editingBanner: clearEditingBanner ? null : (editingBanner ?? this.editingBanner),
      apiNotifications: apiNotifications ?? this.apiNotifications,
      dashboardReport: dashboardReport ?? this.dashboardReport,
      dashboardLoading: dashboardLoading ?? this.dashboardLoading,
      salesReport: salesReport ?? this.salesReport,
      gstReport: gstReport ?? this.gstReport,
    );
  }

  @override
  List<Object?> get props => [
        screen,
        page,
        mobileNumber,
        otpCode,
        otpSent,
        authLoading,
        authError,
        adminName,
        adminMobile,
        zone,
        range,
        catTab,
        status,
        sel,
        modal,
        assign,
        orderStatus,
        month,
        audience,
        apiZones,
        apiOrders,
        ordersLoading,
        currentOrder,
        apiCategories,
        apiProducts,
        productsLoading,
        currentProduct,
        apiStocks,
        stocksLoading,
        apiCustomers,
        customersLoading,
        apiPartners,
        partnersLoading,
        editingPartner,
        apiCoupons,
        editingCoupon,
        editingCategory,
        apiBanners,
        editingBanner,
        apiNotifications,
        dashboardReport,
        dashboardLoading,
        salesReport,
        gstReport,
      ];
}
