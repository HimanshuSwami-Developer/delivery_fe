import 'package:fastswipe/features/auth/data/models/user.dart';

class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const customerHome = '/customer';
  static const restaurantDashboard = '/restaurant';
  static const deliveryDashboard = '/delivery';
  static const basketAdmin = '/basket-admin';

  /// Landing route for a freshly-authenticated user of [role].
  static String homeFor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return customerHome;
      case UserRole.restaurant:
        return restaurantDashboard;
      case UserRole.delivery:
        return deliveryDashboard;
    }
  }
}
