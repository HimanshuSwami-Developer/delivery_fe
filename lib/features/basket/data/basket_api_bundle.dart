import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/basket_api/repositories/basket_auth_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/cart_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/catalog_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/orders_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/promotions_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/support_repository.dart';
import 'package:fastswipe/core/basket_api/repositories/zones_repository.dart';

/// Every repository the customer app needs, bundled behind one object so
/// [BasketCubit] takes a single constructor param. Owns its own [ApiClient]
/// (`tokenScope: 'customer'`) so this app's session is independent of the
/// admin console's, even though both run in the same Flutter process here.
class BasketApiBundle {
  BasketApiBundle({ApiClient? client}) : client = client ?? ApiClient(tokenScope: 'customer') {
    auth = BasketAuthRepository(this.client);
    catalog = CatalogRepository(this.client);
    cart = CartRepository(this.client);
    orders = OrdersRepository(this.client);
    promotions = PromotionsRepository(this.client);
    zones = ZonesRepository(this.client);
    support = SupportRepository(this.client);
  }

  final ApiClient client;
  late final BasketAuthRepository auth;
  late final CatalogRepository catalog;
  late final CartRepository cart;
  late final OrdersRepository orders;
  late final PromotionsRepository promotions;
  late final ZonesRepository zones;
  late final SupportRepository support;
}
