import 'dart:async';

import 'package:fastswipe/core/router/app_routes.dart';
import 'package:fastswipe/features/auth/bloc/auth_bloc.dart';
import 'package:fastswipe/features/auth/data/models/user.dart';
import 'package:fastswipe/features/auth/presentation/login_screen.dart';
import 'package:fastswipe/features/customer/presentation/home_screen.dart';
import 'package:fastswipe/features/delivery/presentation/dashboard_screen.dart';
import 'package:fastswipe/features/restaurant/presentation/dashboard_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Bridges a [Bloc]'s stream to a [Listenable] so [GoRouter] re-evaluates
/// `redirect` whenever [AuthBloc]'s state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

String _homeRouteFor(UserRole role) {
  switch (role) {
    case UserRole.customer:
      return AppRoutes.customerHome;
    case UserRole.restaurant:
      return AppRoutes.restaurantDashboard;
    case UserRole.delivery:
      return AppRoutes.deliveryDashboard;
  }
}

GoRouter buildAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isOnLoginRoute = state.matchedLocation == AppRoutes.login;

      if (authState is AuthAuthenticated) {
        return isOnLoginRoute ? _homeRouteFor(authState.user.role) : null;
      }

      return isOnLoginRoute ? null : AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.restaurantDashboard,
        builder: (context, state) => const RestaurantDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.deliveryDashboard,
        builder: (context, state) => const DeliveryDashboardScreen(),
      ),
    ],
  );
}
