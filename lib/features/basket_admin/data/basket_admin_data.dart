import 'package:fastswipe/features/basket_admin/data/basket_admin_enums.dart';

/// The screens' status chips/tabs/pills all use these exact Title Case
/// labels (matching the source design's `chip()`/pill styling, which keys
/// off them) — the backend uses lowercase snake_case codes instead, so
/// every order-status read/write crosses this mapping at the API boundary,
/// keeping every screen's status-handling code unchanged.
const kOrderStatusToCode = {
  'New': 'new',
  'Packed': 'packed',
  'Out for delivery': 'out_for_delivery',
  'Delivered': 'delivered',
  'Cancelled': 'cancelled',
};

const kOrderStatusFromCode = {
  'new': 'New',
  'packed': 'Packed',
  'out_for_delivery': 'Out for delivery',
  'delivered': 'Delivered',
  'cancelled': 'Cancelled',
};

/// Same mapping idea for delivery-partner status chips.
const kPartnerStatusFromCode = {'available': 'Available', 'on_trip': 'On trip', 'off_duty': 'Off duty'};

/// Static content for the Basket Admin console, ported from
/// `Basket Admin.dc.html`'s `NAV`/`TITLES` top-level consts and its
/// `toLocaleString`-style money formatting helpers. The screens' own
/// per-domain data (orders/products/customers/partners/etc.) now
/// comes from the live API — see [BasketAdminCubit] — so only the
/// still-static navigation/title scaffolding and formatting helpers
/// remain here.

/// One navigation entry: either a section heading or a routable link.
class AdminNavEntry {
  const AdminNavEntry.heading(this.label)
      : page = null,
        icon = '',
        badge = null;

  const AdminNavEntry.link(this.label, this.icon, this.page, {this.badge});

  final String label;
  final String icon;
  final AdminPage? page;
  final String? badge;

  bool get isHeading => page == null;
}

const List<AdminNavEntry> kAdminNav = [
  AdminNavEntry.heading('Overview'),
  AdminNavEntry.link('Dashboard', '▤', AdminPage.dash),
  AdminNavEntry.heading('Commerce'),
  AdminNavEntry.link('Orders', '⬒', AdminPage.orders, badge: '18'),
  AdminNavEntry.link('Products', '▦', AdminPage.products),
  AdminNavEntry.link('Categories', '◈', AdminPage.categories),
  AdminNavEntry.link('Inventory', '◧', AdminPage.inventory, badge: '7'),
  AdminNavEntry.heading('People'),
  AdminNavEntry.link('Customers', '◔', AdminPage.customers),
  AdminNavEntry.link('Delivery partners', '◍', AdminPage.partners),
  AdminNavEntry.heading('Growth'),
  AdminNavEntry.link('Coupons', '✧', AdminPage.coupons),
  AdminNavEntry.link('Banners', '▭', AdminPage.banners),
  AdminNavEntry.link('Notifications', '◑', AdminPage.notifs),
  AdminNavEntry.heading('Reports'),
  AdminNavEntry.link('Sales reports', '◐', AdminPage.sales),
  AdminNavEntry.link('GST reports', '₹', AdminPage.gst),
];

/// The nav entry (if any) that should show as "active" for [page] — folds
/// `orderDet` into `orders` and `productNew` into `products`, matching the
/// source design's highlight rule.
AdminPage navHighlightFor(AdminPage page) => switch (page) {
      AdminPage.orderDet => AdminPage.orders,
      AdminPage.productNew => AdminPage.products,
      _ => page,
    };

class AdminTitle {
  const AdminTitle(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

const Map<AdminPage, AdminTitle> kAdminTitles = {
  AdminPage.dash: AdminTitle('Dashboard', 'Live operations overview'),
  AdminPage.orders: AdminTitle('Order management', 'Route, assign and track every order'),
  AdminPage.orderDet: AdminTitle('Order detail', 'Assign a partner, update status, issue the invoice'),
  AdminPage.products: AdminTitle('Products', '5,142 SKUs across 6 categories'),
  AdminPage.productNew: AdminTitle('Add product', 'New SKU · draft'),
  AdminPage.categories: AdminTitle('Category management', 'Structure, order and visibility'),
  AdminPage.inventory: AdminTitle('Inventory & stock', 'On-hand, reserved and reorder levels'),
  AdminPage.customers: AdminTitle('Customers', '12,480 registered accounts'),
  AdminPage.partners: AdminTitle('Delivery partners', '48 partners on the roster'),
  AdminPage.coupons: AdminTitle('Coupon management', 'Campaigns, limits and redemption'),
  AdminPage.banners: AdminTitle('Banner management', 'Home carousel and category strips'),
  AdminPage.notifs: AdminTitle('Notification management', 'Push campaigns and audiences'),
  AdminPage.sales: AdminTitle('Sales reports', 'Revenue, orders and category mix'),
  AdminPage.gst: AdminTitle('GST reports', 'Slab-wise tax liability and filings'),
};

/// Formats an integer with Indian-style digit grouping, e.g. `1240` ->
/// `"1,240"`, matching the source design's `toLocaleString('en-IN')` calls.
String indianGroup(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  String result;
  if (s.length <= 3) {
    result = s;
  } else {
    var head = s.substring(0, s.length - 3);
    final tail = s.substring(s.length - 3);
    final groups = <String>[];
    while (head.length > 2) {
      groups.insert(0, head.substring(head.length - 2));
      head = head.substring(0, head.length - 2);
    }
    if (head.isNotEmpty) groups.insert(0, head);
    result = '${groups.join(',')},$tail';
  }
  return neg ? '-$result' : result;
}

String adminMoney(num n) => '₹${indianGroup(n.round())}';
