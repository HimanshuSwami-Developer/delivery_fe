import 'dart:async';

import 'package:fastswipe/core/router/app_routes.dart';
import 'package:fastswipe/features/auth/bloc/auth_bloc.dart';
import 'package:fastswipe/features/auth/presentation/login_screen.dart';
import 'package:fastswipe/features/basket/presentation/basket_app.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_app.dart';
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

// The "Basket" customer app (mounted at [AppRoutes.customerHome]) and the
// "Basket Admin" console (mounted at [AppRoutes.basketAdmin]) each manage
// their own internal screen state — self-contained demo flows with no real
// backend, so both are public and not gated behind [AuthBloc]. Only the
// restaurant/delivery dashboards need a real (mocked) login.
const _publicRoutes = {AppRoutes.login, AppRoutes.customerHome, AppRoutes.basketAdmin};

GoRouter buildAppRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.customerHome,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;
      final isPublicRoute = _publicRoutes.contains(location);

      if (authState is AuthAuthenticated) {
        return isPublicRoute && location != AppRoutes.customerHome
            ? AppRoutes.homeFor(authState.user.role)
            : null;
      }

      return isPublicRoute ? null : AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (context, state) => const BasketApp(),
      ),
      GoRoute(
        path: AppRoutes.basketAdmin,
        builder: (context, state) => const BasketAdminApp(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

    ],
  );
}
