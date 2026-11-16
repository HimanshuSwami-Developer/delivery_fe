import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_state.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_api.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_enums.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_app_update_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_delivery_settings_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_banners_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_categories_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_coupons_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_customers_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_dashboard_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_festival_settings_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_gst_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_inventory_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_login_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_notifications_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_order_detail_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_orders_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_partners_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_product_new_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_products_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_sales_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_form_modals.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_sidebar.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_topbar.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/assign_partner_modal.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/partner_form_modal.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root of the "Basket Admin" console, ported from `Basket Admin.dc.html`'s
/// `Component extends DCLogic`. Unlike the customer app, navigation here is
/// a flat `page` field (not a back-stack) — every page is reached directly
/// from the sidebar, and the two drill-in pages (order detail, add
/// product) carry their own explicit "back" link.
class BasketAdminApp extends StatelessWidget {
  const BasketAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BasketAdminCubit(BasketAdminApi()),
      child: Builder(
        builder: (context) {
          return Theme(
            data: adminTheme(Theme.of(context)),
            child: const _AdminRoot(),
          );
        },
      ),
    );
  }
}

class _AdminRoot extends StatelessWidget {
  const _AdminRoot();

  @override
  Widget build(BuildContext context) {
    final screen = context.select((BasketAdminCubit c) => c.state.screen);
    // This console was built desktop-first — a fixed 238px sidebar plus a
    // topbar with a fixed-width search box that together need ~900px to
    // lay out at all. Below that (any phone,
    // or a narrow browser window) it used to overflow outright. Narrow
    // screens now get the sidebar as a `Drawer` (opened via a hamburger
    // button in `AdminTopBar`) instead of pinned inline, same threshold
    // `AdminLoginView` already uses for its own narrow/wide split.
    final narrow = MediaQuery.sizeOf(context).width < 900;
    return BlocListener<BasketAdminCubit, BasketAdminState>(
      listenWhen: (a, b) => b.newOrderAlertSeq != a.newOrderAlertSeq && b.screen == AdminScreen.app,
      listener: (context, state) {
        final n = state.newOrderAlertCount;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            width: narrow ? null : 420,
            duration: const Duration(seconds: 6),
            content: Text(n == 1 ? '🛒 New order received' : '🛒 $n new orders received'),
            action: SnackBarAction(label: 'View', onPressed: context.read<BasketAdminCubit>().goNewOrders),
          ));
      },
      child: Scaffold(
        backgroundColor: AdminColors.backdrop,
        drawer: narrow && screen == AdminScreen.app ? const Drawer(width: 238, child: SafeArea(child: AdminSidebar())) : null,
        body: screen == AdminScreen.login ? const AdminLoginView() : _AdminShell(narrow: narrow),
      ),
    );
  }
}

/// Sidebar + topbar + the active page, with the assign-partner modal
/// overlaid on top when open. [narrow] pulls the sidebar out into the
/// Scaffold's `Drawer` instead of pinning it inline — see `_AdminRoot`.
class _AdminShell extends StatelessWidget {
  const _AdminShell({required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final modal = context.select((BasketAdminCubit c) => c.state.modal);

    return SafeArea(
      child: Stack(
        children: [
          Row(
            children: [
              if (!narrow) const AdminSidebar(),
              Expanded(
                child: Column(
                  children: [
                    AdminTopBar(narrow: narrow),
                    Expanded(
                      child: ColoredBox(
                        color: AdminColors.card,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(26, 22, 26, 30),
                          child: const _AdminPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (modal == AdminModal.assign) const AssignPartnerModal(),
          if (modal == AdminModal.addCategory) const AddCategoryModal(),
          if (modal == AdminModal.addSubcategory) const AddSubcategoryModal(),
          if (modal == AdminModal.partnerForm) const PartnerFormModal(),
          if (modal == AdminModal.addCoupon) const AddCouponModal(),
          if (modal == AdminModal.addBanner) const AddBannerModal(),
          if (modal == AdminModal.editFestival) const EditFestivalSettingModal(),
        ],
      ),
    );
  }
}

class _AdminPage extends StatelessWidget {
  const _AdminPage();

  @override
  Widget build(BuildContext context) {
    final page = context.select((BasketAdminCubit c) => c.state.page);
    return switch (page) {
      AdminPage.dash => const AdminDashboardView(),
      AdminPage.orders => const AdminOrdersView(),
      AdminPage.orderDet => const AdminOrderDetailView(),
      AdminPage.products => const AdminProductsView(),
      AdminPage.productNew => const AdminProductNewView(),
      AdminPage.categories => const AdminCategoriesView(),
      AdminPage.inventory => const AdminInventoryView(),
      AdminPage.delivery => const AdminDeliverySettingsView(),
      AdminPage.appUpdate => const AdminAppUpdateView(),
      AdminPage.customers => const AdminCustomersView(),
      AdminPage.partners => const AdminPartnersView(),
      AdminPage.coupons => const AdminCouponsView(),
      AdminPage.banners => const AdminBannersView(),
      AdminPage.festivals => const AdminFestivalSettingsView(),
      AdminPage.notifs => const AdminNotificationsView(),
      AdminPage.sales => const AdminSalesView(),
      AdminPage.gst => const AdminGstView(),
    };
  }
}
