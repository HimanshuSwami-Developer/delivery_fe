import 'package:equatable/equatable.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/core/basket_api/models/delivery_models.dart';
import 'package:fastswipe/core/basket_api/models/order_models.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/core/basket_api/models/report_models.dart';
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
    this.range = '14d',
    this.catTab = 'All',
    this.status = 'All',
    this.sel = '',
    this.modal = AdminModal.none,
    this.assign,
    this.orderStatus = 'new',
    this.month = 'aug',
    this.audience = 'All users',
    this.apiOrders = const [],
    this.ordersLoading = false,
    this.newOrdersCount = 0,
    this.newOrderAlertSeq = 0,
    this.newOrderAlertCount = 0,
    this.currentOrder,
    this.apiCategories = const [],
    this.categoriesLoading = false,
    this.apiProducts = const [],
    this.productsLoading = false,
    this.currentProduct,
    this.apiStocks = const [],
    this.stocksLoading = false,
    this.stockCatTab = 'All',
    this.stockState,
    this.stockSearch = '',
    this.stockPage = 1,
    this.stockCount = 0,
    this.stockSummary,
    this.apiCustomers = const [],
    this.customersLoading = false,
    this.apiPartners = const [],
    this.partnersLoading = false,
    this.editingPartner,
    this.apiCoupons = const [],
    this.editingCoupon,
    this.editingCategory,
    this.apiSubcategories = const [],
    this.editingSubcategory,
    this.addSubcategoryCategory,
    this.apiBanners = const [],
    this.editingBanner,
    this.apiFestivalSettings = const [],
    this.editingFestivalSetting,
    this.apiNotifications = const [],
    this.dashboardReport,
    this.dashboardLoading = false,
    this.salesReport,
    this.salesError,
    this.deliveredSalesPeriod = 'daily',
    this.deliveredSales,
    this.deliveredSalesLoading = false,
    this.deliveredSalesError,
    this.gstReport,
    this.gstError,
    this.gstRates = const [],
    this.storeSettings,
    this.deliverySettings,
    this.deliverySettingsSaving = false,
    this.deliverySettingsError,
    this.storeSettingsSaving = false,
    this.storeSettingsError,
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

  final List<ApiOrder> apiOrders;
  final bool ordersLoading;

  /// Orders still in `new` status (not packed yet) — drives the red badge
  /// on the sidebar's Orders link and the top-bar bell. Polled every 30 s
  /// by `BasketAdminCubit`.
  final int newOrdersCount;

  /// Bumped each time polling sees [newOrdersCount] go up, so the shell can
  /// show a one-off "new order" snackbar; [newOrderAlertCount] is how many
  /// arrived since the previous poll.
  final int newOrderAlertSeq;
  final int newOrderAlertCount;

  /// Full detail (with line items) for [sel], fetched by `openOrder`.
  final ApiOrder? currentOrder;

  final List<ApiCategory> apiCategories;
  final bool categoriesLoading;
  final List<ApiProduct> apiProducts;
  final bool productsLoading;

  /// The product shown on the Add/Edit Product page.
  final ApiProduct? currentProduct;

  final List<ApiProductStock> apiStocks;
  final bool stocksLoading;

  /// Inventory screen's category-tab filter — a category key, or 'All'.
  final String stockCatTab;

  /// Inventory screen's stock-state chip filter — 'healthy' | 'low' |
  /// 'out_of_stock', or null for "All states".
  final String? stockState;

  /// Inventory screen's search box text.
  final String stockSearch;

  /// Inventory screen's current page (1-indexed) and the total matching
  /// row count from the last fetch's pagination envelope, used together to
  /// render page controls (`loadStocks` in the cubit does the actual
  /// page-size math).
  final int stockPage;
  final int stockCount;

  /// True totals across all inventory, independent of [stockPage]/filters —
  /// see [BasketAdminCubit.loadStocksSummary].
  final StockSummary? stockSummary;

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

  /// All subcategories across every category — filtered client-side by
  /// `categoryId` when rendering a given category's chips, rather than
  /// re-fetching per card.
  final List<ApiSubcategory> apiSubcategories;

  /// The subcategory shown on [AdminModal.addSubcategory] — null means
  /// create, non-null means edit.
  final ApiSubcategory? editingSubcategory;

  /// Which category a new/edited subcategory belongs to — set whenever
  /// [AdminModal.addSubcategory] opens (for a new one, from whichever
  /// category's "+" chip was tapped; for editing, derived from the
  /// subcategory's own `categoryId`).
  final ApiCategory? addSubcategoryCategory;

  final List<ApiBanner> apiBanners;

  /// The banner shown on [AdminModal.addBanner] — null means the modal is
  /// creating a new one, non-null means it's editing this one.
  final ApiBanner? editingBanner;

  /// One row per festival — see [AdminPage.festivals].
  final List<ApiFestivalSetting> apiFestivalSettings;

  /// The row shown on [AdminModal.editFestival] — always non-null while
  /// that modal is open (unlike banners, there's no "create new" here;
  /// every festival's row already exists, seeded server-side).
  final ApiFestivalSetting? editingFestivalSetting;

  final List<ApiNotification> apiNotifications;

  final DashboardReport? dashboardReport;
  final bool dashboardLoading;
  final SalesReport? salesReport;

  /// Set when [BasketAdminCubit.loadSales] fails — without this, a failure
  /// left `salesReport` null forever with no way to tell "still loading"
  /// from "failed", so the screen just spun indefinitely.
  final String? salesError;

  /// "Delivered sales" period tab: 'daily' | 'weekly' | 'monthly' | 'yearly'.
  final String deliveredSalesPeriod;
  final DeliveredSalesReport? deliveredSales;
  final bool deliveredSalesLoading;
  final String? deliveredSalesError;
  final GstReport? gstReport;
  final String? gstError;

  /// Admin-defined CGST/SGST rates — managed on the GST screen, picked on
  /// the product form. See [BasketAdminCubit.loadGstRates].
  final List<ApiGstRate> gstRates;

  /// The seller's own GST profile (business name/address/GSTIN), edited on
  /// the GST screen's settings panel — see [BasketAdminCubit.loadStoreSettings]
  /// / [BasketAdminCubit.saveStoreSettings].
  final StoreGstSettings? storeSettings;

  /// "Delivery charges" page — see [BasketAdminCubit.loadDeliverySettings].
  final ApiDeliverySettings? deliverySettings;
  final bool deliverySettingsSaving;
  final String? deliverySettingsError;
  final bool storeSettingsSaving;
  final String? storeSettingsError;

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
    List<ApiOrder>? apiOrders,
    bool? ordersLoading,
    int? newOrdersCount,
    int? newOrderAlertSeq,
    int? newOrderAlertCount,
    ApiOrder? currentOrder,
    List<ApiCategory>? apiCategories,
    bool? categoriesLoading,
    List<ApiProduct>? apiProducts,
    bool? productsLoading,
    ApiProduct? currentProduct,
    bool clearCurrentProduct = false,
    List<ApiProductStock>? apiStocks,
    bool? stocksLoading,
    String? stockCatTab,
    String? stockState,
    bool clearStockState = false,
    String? stockSearch,
    int? stockPage,
    int? stockCount,
    StockSummary? stockSummary,
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
    List<ApiSubcategory>? apiSubcategories,
    ApiSubcategory? editingSubcategory,
    bool clearEditingSubcategory = false,
    ApiCategory? addSubcategoryCategory,
    bool clearAddSubcategoryCategory = false,
    List<ApiBanner>? apiBanners,
    ApiBanner? editingBanner,
    bool clearEditingBanner = false,
    List<ApiFestivalSetting>? apiFestivalSettings,
    ApiFestivalSetting? editingFestivalSetting,
    bool clearEditingFestivalSetting = false,
    List<ApiNotification>? apiNotifications,
    DashboardReport? dashboardReport,
    bool? dashboardLoading,
    SalesReport? salesReport,
    String? salesError,
    bool clearSalesError = false,
    String? deliveredSalesPeriod,
    DeliveredSalesReport? deliveredSales,
    bool? deliveredSalesLoading,
    String? deliveredSalesError,
    bool clearDeliveredSalesError = false,
    GstReport? gstReport,
    String? gstError,
    bool clearGstError = false,
    List<ApiGstRate>? gstRates,
    StoreGstSettings? storeSettings,
    ApiDeliverySettings? deliverySettings,
    bool? deliverySettingsSaving,
    String? deliverySettingsError,
    bool clearDeliverySettingsError = false,
    bool? storeSettingsSaving,
    String? storeSettingsError,
    bool clearStoreSettingsError = false,
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
      range: range ?? this.range,
      catTab: catTab ?? this.catTab,
      status: status ?? this.status,
      sel: sel ?? this.sel,
      modal: modal ?? this.modal,
      assign: clearAssign ? null : (assign ?? this.assign),
      orderStatus: orderStatus ?? this.orderStatus,
      month: month ?? this.month,
      audience: audience ?? this.audience,
      apiOrders: apiOrders ?? this.apiOrders,
      ordersLoading: ordersLoading ?? this.ordersLoading,
      newOrdersCount: newOrdersCount ?? this.newOrdersCount,
      newOrderAlertSeq: newOrderAlertSeq ?? this.newOrderAlertSeq,
      newOrderAlertCount: newOrderAlertCount ?? this.newOrderAlertCount,
      currentOrder: currentOrder ?? this.currentOrder,
      apiCategories: apiCategories ?? this.apiCategories,
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      apiProducts: apiProducts ?? this.apiProducts,
      productsLoading: productsLoading ?? this.productsLoading,
      currentProduct: clearCurrentProduct ? null : (currentProduct ?? this.currentProduct),
      apiStocks: apiStocks ?? this.apiStocks,
      stocksLoading: stocksLoading ?? this.stocksLoading,
      stockCatTab: stockCatTab ?? this.stockCatTab,
      stockState: clearStockState ? null : (stockState ?? this.stockState),
      stockSearch: stockSearch ?? this.stockSearch,
      stockPage: stockPage ?? this.stockPage,
      stockCount: stockCount ?? this.stockCount,
      stockSummary: stockSummary ?? this.stockSummary,
      apiCustomers: apiCustomers ?? this.apiCustomers,
      customersLoading: customersLoading ?? this.customersLoading,
      apiPartners: apiPartners ?? this.apiPartners,
      partnersLoading: partnersLoading ?? this.partnersLoading,
      editingPartner: clearEditingPartner ? null : (editingPartner ?? this.editingPartner),
      apiCoupons: apiCoupons ?? this.apiCoupons,
      editingCoupon: clearEditingCoupon ? null : (editingCoupon ?? this.editingCoupon),
      editingCategory: clearEditingCategory ? null : (editingCategory ?? this.editingCategory),
      apiSubcategories: apiSubcategories ?? this.apiSubcategories,
      editingSubcategory: clearEditingSubcategory ? null : (editingSubcategory ?? this.editingSubcategory),
      addSubcategoryCategory: clearAddSubcategoryCategory ? null : (addSubcategoryCategory ?? this.addSubcategoryCategory),
      apiBanners: apiBanners ?? this.apiBanners,
      editingBanner: clearEditingBanner ? null : (editingBanner ?? this.editingBanner),
      apiFestivalSettings: apiFestivalSettings ?? this.apiFestivalSettings,
      editingFestivalSetting: clearEditingFestivalSetting ? null : (editingFestivalSetting ?? this.editingFestivalSetting),
      apiNotifications: apiNotifications ?? this.apiNotifications,
      dashboardReport: dashboardReport ?? this.dashboardReport,
      dashboardLoading: dashboardLoading ?? this.dashboardLoading,
      salesReport: salesReport ?? this.salesReport,
      salesError: clearSalesError ? null : (salesError ?? this.salesError),
      deliveredSalesPeriod: deliveredSalesPeriod ?? this.deliveredSalesPeriod,
      deliveredSales: deliveredSales ?? this.deliveredSales,
      deliveredSalesLoading: deliveredSalesLoading ?? this.deliveredSalesLoading,
      deliveredSalesError: clearDeliveredSalesError ? null : (deliveredSalesError ?? this.deliveredSalesError),
      gstReport: gstReport ?? this.gstReport,
      gstError: clearGstError ? null : (gstError ?? this.gstError),
      gstRates: gstRates ?? this.gstRates,
      storeSettings: storeSettings ?? this.storeSettings,
      deliverySettings: deliverySettings ?? this.deliverySettings,
      deliverySettingsSaving: deliverySettingsSaving ?? this.deliverySettingsSaving,
      deliverySettingsError: clearDeliverySettingsError ? null : (deliverySettingsError ?? this.deliverySettingsError),
      storeSettingsSaving: storeSettingsSaving ?? this.storeSettingsSaving,
      storeSettingsError: clearStoreSettingsError ? null : (storeSettingsError ?? this.storeSettingsError),
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
        range,
        catTab,
        status,
        sel,
        modal,
        assign,
        orderStatus,
        month,
        audience,
        apiOrders,
        ordersLoading,
        newOrdersCount,
        newOrderAlertSeq,
        newOrderAlertCount,
        currentOrder,
        apiCategories,
        categoriesLoading,
        apiProducts,
        productsLoading,
        currentProduct,
        apiStocks,
        stocksLoading,
        stockCatTab,
        stockState,
        stockSearch,
        stockPage,
        stockCount,
        stockSummary,
        apiCustomers,
        customersLoading,
        apiPartners,
        partnersLoading,
        editingPartner,
        apiCoupons,
        editingCoupon,
        editingCategory,
        apiSubcategories,
        editingSubcategory,
        addSubcategoryCategory,
        apiBanners,
        editingBanner,
        apiFestivalSettings,
        editingFestivalSetting,
        apiNotifications,
        dashboardReport,
        dashboardLoading,
        salesReport,
        salesError,
        deliveredSalesPeriod,
        deliveredSales,
        deliveredSalesLoading,
        deliveredSalesError,
        gstReport,
        gstError,
        gstRates,
        storeSettings,
        deliverySettings,
        deliverySettingsSaving,
        deliverySettingsError,
        storeSettingsSaving,
        storeSettingsError,
      ];
}
