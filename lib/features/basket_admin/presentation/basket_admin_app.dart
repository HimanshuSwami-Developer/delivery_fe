import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_api.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_enums.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_banners_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_categories_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_coupons_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_customers_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_dashboard_view.dart';
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
import 'package:fastswipe/features/basket_admin/presentation/screens/admin_zones_view.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_sidebar.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_topbar.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/assign_partner_modal.dart';
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
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: Size.zero)),
              outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: Size.zero)),
            ),
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
    return Scaffold(
      backgroundColor: AdminColors.backdrop,
      body: screen == AdminScreen.login ? const AdminLoginView() : const _AdminShell(),
    );
  }
}

/// Sidebar + topbar + the active page, with the assign-partner modal
/// overlaid on top when open.
class _AdminShell extends StatelessWidget {
  const _AdminShell();

  @override
  Widget build(BuildContext context) {
    final modal = context.select((BasketAdminCubit c) => c.state.modal);

    return SafeArea(
      child: Stack(
        children: [
          Row(
            children: [
              const AdminSidebar(),
              Expanded(
                child: Column(
                  children: [
                    const AdminTopBar(),
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
      AdminPage.customers => const AdminCustomersView(),
      AdminPage.partners => const AdminPartnersView(),
      AdminPage.coupons => const AdminCouponsView(),
      AdminPage.banners => const AdminBannersView(),
      AdminPage.notifs => const AdminNotificationsView(),
      AdminPage.sales => const AdminSalesView(),
      AdminPage.gst => const AdminGstView(),
      AdminPage.zones => const AdminZonesView(),
    };
  }
}
