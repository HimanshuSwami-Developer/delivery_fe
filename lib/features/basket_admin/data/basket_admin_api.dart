import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/basket_api/repositories/basket_auth_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/catalog_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/delivery_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/orders_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/promotions_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/reports_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/zones_repository.dart';

/// Every repository the admin console needs, bundled behind one object so
/// [BasketAdminCubit] takes a single constructor param instead of eight.
/// Owns its own [ApiClient] (`tokenScope: 'admin'`) so signing into the
/// console never clobbers the customer app's session in the same process.
class BasketAdminApi {
  BasketAdminApi({ApiClient? client}) : client = client ?? ApiClient(tokenScope: 'admin') {
    auth = BasketAuthRepository(this.client);
    catalog = CatalogRepository(this.client);
    zones = ZonesRepository(this.client);
    delivery = DeliveryRepository(this.client);
    orders = OrdersRepository(this.client);
    promotions = PromotionsRepository(this.client);
    reports = ReportsRepository(this.client);
  }

  final ApiClient client;
  late final BasketAuthRepository auth;
  late final CatalogRepository catalog;
  late final ZonesRepository zones;
  late final DeliveryRepository delivery;
  late final OrdersRepository orders;
  late final PromotionsRepository promotions;
  late final ReportsRepository reports;
}
