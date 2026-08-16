import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_api_bundle.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/screens/account_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/address_edit_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/address_list_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/cart_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/categories_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/category_list_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/coupons_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/delivery_slot_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/home_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/login_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/notifications_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/onboarding_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/order_detail_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/order_success_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/order_summary_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/order_tracking_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/orders_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/otp_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/paying_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/payment_failure_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/payment_method_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/product_detail_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/search_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/setup_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/splash_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/support_view.dart';
import 'package:fastswipe/features/basket/presentation/screens/wishlist_view.dart';
import 'package:fastswipe/features/basket/presentation/widgets/bottom_nav.dart';
import 'package:fastswipe/features/basket/presentation/widgets/cancel_sheet.dart';
import 'package:fastswipe/features/basket/presentation/widgets/cart_bar.dart';
import 'package:fastswipe/features/basket/presentation/widgets/filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Root of the "Basket" grocery app, ported from
/// `Basket App - Parts 1-2.dc.html`'s `Component extends DCLogic`: one
/// [BasketCubit] owns a self-managed screen/back-stack state machine (not
/// `go_router` navigation), so tab-resets-history, bottom-sheet, and
/// back-button semantics match the source design exactly.
class BasketApp extends StatelessWidget {
  const BasketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BasketCubit(BasketApiBundle()),
      // The app-wide theme (core/theme/app_theme.dart, used by the
      // restaurant/delivery dashboards) sets FilledButton/OutlinedButton
      // `minimumSize: Size.fromHeight(56)` for full-bleed buttons there.
      // `Size.fromHeight` has an infinite width component — harmless when a
      // button is the sole child of a bounded-width parent, but it throws
      // "BoxConstraints forces an infinite width" the moment a button sits
      // in a `Row` without an `Expanded`/fixed-width wrapper, which this
      // feature does throughout (every sticky action bar). Basket sets
      // every button's color/shape explicitly already, so the only thing
      // worth inheriting from the ambient theme is typography — reset just
      // the button minimum sizes here rather than auditing every call site.
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Theme(
            data: theme.copyWith(
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(minimumSize: Size.zero),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(minimumSize: Size.zero),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(minimumSize: Size.zero),
              ),
            ),
            child: const _BasketRoot(),
          );
        },
      ),
    );
  }
}

class _BasketRoot extends StatelessWidget {
  const _BasketRoot();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final screen = context.select((BasketCubit c) => c.state.screen);
    // `BasketApp` is mounted as a single go_router route with no nested
    // Navigator stack of its own — every "screen" here is just cubit state,
    // not a pushed route — so without this, the hardware/gesture back
    // button has nothing to pop and exits the app immediately from
    // anywhere. Only let that system-level pop through once we're already
    // at a true root with nothing behind it (home once signed in; splash
    // before that — `_leaveSplash` is the *only* place that ever moves off
    // `splash` and it always uses `go()`, so splash is the one pre-auth
    // screen `back()` can find with an empty history). Every other screen
    // routes back through the same `cubit.back()` the on-screen back arrows
    // use — critically, that also stops `back()`'s "nothing to pop -> go
    // home" fallback from ever firing on a pre-auth screen and skipping
    // login/OTP.
    final atRoot = context.select(
      (BasketCubit c) =>
          c.state.history.isEmpty && (c.state.screen == BasketScreen.home || c.state.screen == BasketScreen.splash),
    );
    return PopScope(
      canPop: atRoot,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        cubit.back();
      },
      child: switch (screen) {
        BasketScreen.splash => const SplashView(),
        BasketScreen.onboard => const OnboardingView(),
        BasketScreen.login => const LoginView(),
        BasketScreen.otp => const OtpView(),
        BasketScreen.setup => const SetupView(),
        _ => const _ShoppingShell(),
      },
    );
  }
}

/// Shared page background + bottom nav + floating cart bar + modal sheets
/// for every screen past the pre-auth flow.
class _ShoppingShell extends StatelessWidget {
  const _ShoppingShell();

  @override
  Widget build(BuildContext context) {
    final screen = context.select((BasketCubit c) => c.state.screen);
    final sheet = context.select((BasketCubit c) => c.state.sheet);
    final hasCartItems = context.select((BasketCubit c) => cartTotals(c.state).itemCount > 0);

    final showBottomNav = kBottomNavScreens.contains(screen);
    final showCartBar = hasCartItems && kCartBarScreens.contains(screen);

    return Scaffold(
      backgroundColor: BasketColors.page,
      body: Stack(
        children: [
          Positioned.fill(child: _screenFor(screen)),
          if (showCartBar) const Positioned(left: 14, right: 14, bottom: 14, child: CartBar()),
          if (sheet == ActiveSheet.filter) const FilterSheet(),
          if (sheet == ActiveSheet.cancelOrReturn) const CancelSheet(),
        ],
      ),
      bottomNavigationBar: showBottomNav ? const BasketBottomNav() : null,
    );
  }

  Widget _screenFor(BasketScreen screen) {
    return switch (screen) {
      BasketScreen.home => const HomeView(),
      BasketScreen.cats => const CategoriesView(),
      BasketScreen.list => const CategoryListView(),
      BasketScreen.search => const SearchView(),
      BasketScreen.pdp => const ProductDetailView(),
      BasketScreen.cart => const CartView(),
      BasketScreen.account => const AccountView(),
      BasketScreen.wish => const WishlistView(),
      BasketScreen.addr => const AddressListView(),
      BasketScreen.addrEdit => const AddressEditView(),
      BasketScreen.slot => const DeliverySlotView(),
      BasketScreen.summary => const OrderSummaryView(),
      BasketScreen.pay => const PaymentMethodView(),
      BasketScreen.paying => const PayingView(),
      BasketScreen.success => const OrderSuccessView(),
      BasketScreen.failure => const PaymentFailureView(),
      BasketScreen.orders => const OrdersView(),
      BasketScreen.orderDet => const OrderDetailScreenView(),
      BasketScreen.track => const OrderTrackingView(),
      BasketScreen.coupons => const CouponsView(),
      BasketScreen.notifs => const NotificationsView(),
      BasketScreen.support => const SupportView(),
      BasketScreen.splash ||
      BasketScreen.onboard ||
      BasketScreen.login ||
      BasketScreen.otp ||
      BasketScreen.setup =>
        const HomeView(),
    };
  }
}
