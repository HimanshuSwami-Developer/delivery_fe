import 'package:fastswipe/core/basket_api/models/profile_models.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/cubit/basket_state.dart';

/// Pure derived-data functions computed from [BasketState] on read — kept
/// out of the state/cubit so nothing here can go stale, and so widgets can
/// select just the slice they need (e.g. `context.select((c) =>
/// cartTotals(c.state).itemCount)`) instead of rebuilding on any state
/// change.
///
/// Catalog/order/coupon data itself comes from the Django backend
/// (`BasketCubit.loadCatalog`/`loadOrders`/etc. populate `state.apiXxx`);
/// these functions convert that into the same `BasketProduct`/
/// `BasketCategory`/etc. shapes the screens were already built around, and
/// apply the same client-side filter/sort/derive logic the source design
/// used, just fed from live data instead of the static `BasketCatalog`.

/// Formats an integer with Indian-style digit grouping (e.g. 1240 -> "1,240"),
/// matching the source design's `toLocaleString('en-IN')` calls.
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

String moneyLabel(num n) => '₹${indianGroup(n.round())}';

/// Minutes remaining for each of the 4 tracking stages, matching the
/// source design's `[eta, max(1,eta-4), max(1,eta-8), 0][stage]`.
int etaLeftForStage(int stage, {int eta = 12}) {
  switch (stage) {
    case 0:
      return eta;
    case 1:
      return eta - 4 > 1 ? eta - 4 : 1;
    case 2:
      return eta - 8 > 1 ? eta - 8 : 1;
    default:
      return 0;
  }
}

// ── Catalog (from state.apiCategories / state.apiProducts) ─────────────

List<BasketCategory> categoriesOf(BasketState state) =>
    state.apiCategories.map(BasketCategory.fromApi).toList();

BasketCategory categoryByKey(BasketState state, String key) {
  final cats = categoriesOf(state);
  return cats.firstWhere((c) => c.key == key, orElse: () => cats.isNotEmpty ? cats.first : const BasketCategory(key: '', name: '', subs: [], count: 0));
}

/// The address the Home header's dropdown should show — the one matching
/// [BasketState.addressId], falling back to the first saved address, or
/// `null` before any address has been added yet.
ApiAddress? selectedAddress(BasketState state) {
  if (state.apiAddresses.isEmpty) return null;
  for (final a in state.apiAddresses) {
    if (a.id == state.addressId) return a;
  }
  return state.apiAddresses.first;
}

/// Full street-level address shown under the "Home" header line — GPS
/// (live device location) wins when available, falling back to the full
/// saved-address line, then to `null` (caller shows an "add an address"
/// prompt) when there's neither.
String? homeAddressSubtitle(BasketState state) {
  if ((state.gpsAddress ?? '').isNotEmpty) return state.gpsAddress;
  final address = selectedAddress(state);
  if (address == null) return null;
  return Address.fromApi(address).line;
}

List<BasketProduct> productsOf(BasketState state) => state.apiProducts.map(BasketProduct.fromApi).toList();

BasketProduct? productById(BasketState state, String id) {
  for (final p in state.apiProducts) {
    if (p.id.toString() == id) return BasketProduct.fromApi(p);
  }
  return null;
}

/// Resolves every product currently in [BasketState.cart] against the
/// loaded catalog — used by the cart/checkout screens instead of each one
/// re-deriving it.
List<BasketProduct> cartProducts(BasketState state) =>
    state.cart.keys.map((id) => productById(state, id)).whereType<BasketProduct>().toList();

/// The currently-selected delivery address, resolved from
/// [BasketState.apiAddresses] — falls back to a placeholder before
/// addresses have loaded (or if none are saved yet) rather than crashing
/// the checkout/success screens.
Address addressForState(BasketState state) {
  final match = state.apiAddresses.where((a) => a.id == state.addressId);
  if (match.isNotEmpty) return Address.fromApi(match.first);
  if (state.apiAddresses.isNotEmpty) return Address.fromApi(state.apiAddresses.first);
  return const Address(id: '', label: 'Address', tag: '', line: 'Add a delivery address', eta: 15);
}

class BasketTotals {
  const BasketTotals({
    required this.subtotal,
    required this.mrpTotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.itemCount,
    required this.freeDeliveryAbove,
  });

  final int subtotal;
  final int mrpTotal;
  final int discount;
  final int deliveryFee;
  final int total;
  final int itemCount;
  final int freeDeliveryAbove;

  int get savings => mrpTotal - subtotal + discount;
  bool get freeDeliveryUnlocked => subtotal >= freeDeliveryAbove;

  /// Handling & GST shown at order-summary/checkout: a flat ₹9 handling
  /// charge plus 18% GST on the delivery fee, matching the source design's
  /// `gst = sub ? 9 + round(fee * 0.18) : 0`. This is a checkout-preview
  /// estimate only — the order actually placed computes real per-line
  /// CGST/SGST server-side from each product's GST slab.
  int get gst => subtotal > 0 ? 9 + (deliveryFee * 0.18).round() : 0;

  int get payable => total + gst;
}

BasketTotals cartTotals(BasketState state, {int freeDeliveryAbove = 199}) {
  var subtotal = 0, mrpTotal = 0, itemCount = 0;
  for (final entry in state.cart.entries) {
    final p = productById(state, entry.key);
    if (p == null) continue;
    subtotal += p.price * entry.value;
    mrpTotal += p.mrp * entry.value;
    itemCount += entry.value;
  }
  final coupon = state.appliedCoupon != null
      ? state.apiCoupons.where((c) => c.code == state.appliedCoupon).firstOrNull
      : null;
  var discount = 0;
  if (coupon != null && subtotal >= coupon.minOrderValue) {
    discount = coupon.percentDiscount != null
        ? (coupon.maxDiscount != null
            ? (subtotal * coupon.percentDiscount! / 100).round().clamp(0, coupon.maxDiscount!)
            : (subtotal * coupon.percentDiscount! / 100).round())
        : (coupon.flatDiscount ?? 0);
  }
  final fee = (subtotal >= freeDeliveryAbove || subtotal == 0) ? 0 : 29;
  final total = subtotal - discount + fee;
  return BasketTotals(
    subtotal: subtotal,
    mrpTotal: mrpTotal,
    discount: discount,
    deliveryFee: fee,
    total: total < 0 ? 0 : total,
    itemCount: itemCount,
    freeDeliveryAbove: freeDeliveryAbove,
  );
}

List<BasketProduct> visibleListProducts(BasketState state) {
  var out = productsOf(state).where((p) => p.cat == state.category && p.sub == state.subcategory).toList();
  if (out.isEmpty) {
    out = productsOf(state).where((p) => p.cat == state.category).toList();
  }
  switch (state.band) {
    case PriceBand.low:
      out = out.where((p) => p.price < 50).toList();
    case PriceBand.mid:
      out = out.where((p) => p.price >= 50 && p.price <= 200).toList();
    case PriceBand.high:
      out = out.where((p) => p.price > 200).toList();
    case PriceBand.all:
      break;
  }
  out = [...out];
  out.sort((a, b) {
    switch (state.sort) {
      case SortOption.priceAsc:
        return a.price.compareTo(b.price);
      case SortOption.priceDesc:
        return b.price.compareTo(a.price);
      case SortOption.discount:
        final da = (a.mrp - a.price) / a.mrp;
        final db = (b.mrp - b.price) / b.mrp;
        return db.compareTo(da);
      case SortOption.popularity:
        return b.ratingsCount.compareTo(a.ratingsCount);
    }
  });
  return out;
}

List<BasketProduct> searchResults(BasketState state) {
  final q = state.query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return productsOf(state).where((p) => '${p.name} ${p.brand} ${p.sub}'.toLowerCase().contains(q)).take(8).toList();
}

BasketProduct pdpProduct(BasketState state) =>
    (state.selectedProductId != null ? productById(state, state.selectedProductId!) : null) ??
    (state.apiProducts.isNotEmpty ? BasketProduct.fromApi(state.apiProducts.first) : const BasketProduct(
        id: '', name: '', pack: '', price: 0, mrp: 0, cat: '', sub: '', brand: '', rating: 0, ratingsCount: 0));

/// "Buy it again": the most frequently-ordered products across the
/// customer's real order history (best-effort — only orders whose detail
/// happens to already be cached in [BasketState.apiOrders]/[currentOrder]
/// contribute, since the list endpoint doesn't include line items).
List<BasketProduct> buyAgainProducts(BasketState state) {
  final current = state.currentOrder;
  if (current == null || current.items.isEmpty) return const [];
  final ids = current.items.map((i) => i.productId.toString()).toSet();
  return ids.map((id) => productById(state, id)).whereType<BasketProduct>().toList();
}

/// "Recommended for you": simply the highest-rated products in the loaded
/// catalog (no real recommendation engine exists server-side).
List<BasketProduct> recommendedProducts(BasketState state, {int take = 6}) {
  final all = [...productsOf(state)]..sort((a, b) => b.rating.compareTo(a.rating));
  return all.take(take).toList();
}

// ── Orders (from state.apiOrders / state.currentOrder) ──────────────────

const _liveStatuses = {'new', 'packed', 'out_for_delivery'};

bool isLiveOrderStatus(String status) => _liveStatuses.contains(status);

String orderStatusLabel(String status) => switch (status) {
      'new' => 'Confirmed',
      'packed' => 'Packed',
      'out_for_delivery' => 'On the way',
      'delivered' => 'Delivered',
      'cancelled' => 'Cancelled',
      _ => status,
    };

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String orderDateLabel(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final mm = local.minute.toString().padLeft(2, '0');
  final ap = local.hour >= 12 ? 'PM' : 'AM';
  final time = '$hh:$mm $ap';
  final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
  return isToday ? 'Today, $time' : '${local.day} ${_months[local.month - 1]}, $time';
}

class OrderListRow {
  const OrderListRow({
    required this.id,
    required this.orderNumber,
    required this.dateLabel,
    required this.statusLabel,
    required this.isLive,
    required this.itemCount,
    required this.totalLabel,
    required this.ctaLabel,
  });

  /// Backend numeric id — pass this to `openOrderDetail`/`fetchOrder`.
  final String id;

  /// Human-friendly code (e.g. "BSK-1234") for display.
  final String orderNumber;

  final String dateLabel;
  final String statusLabel;
  final bool isLive;
  final int itemCount;
  final String totalLabel;
  final String ctaLabel;
}

List<OrderListRow> orderListRows(BasketState state) {
  return state.apiOrders.map((o) {
    final live = isLiveOrderStatus(o.status);
    return OrderListRow(
      id: o.id.toString(),
      orderNumber: o.orderNumber,
      dateLabel: orderDateLabel(o.createdAt),
      statusLabel: orderStatusLabel(o.status),
      isLive: live,
      itemCount: o.itemCount,
      totalLabel: moneyLabel(o.total),
      ctaLabel: live ? 'Track order' : (o.status == 'cancelled' ? 'View details' : 'Reorder'),
    );
  }).toList();
}

/// Resolved view of the order-detail screen for [BasketState.currentOrder]
/// (fetched with full line items by `BasketCubit.openOrderDetail`).
class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.statusLabel,
    required this.date,
    required this.isLive,
    required this.isClosed,
    required this.returnable,
    required this.showInvoice,
    required this.items,
    required this.subtotalLabel,
    required this.discountLabel,
    required this.feeLabel,
    required this.totalLabel,
    required this.paidLabel,
  });

  final String id;
  final String statusLabel;
  final String date;
  final bool isLive;
  final bool isClosed;
  final bool returnable;
  final bool showInvoice;

  /// (name, pack, qty, rate) per line.
  final List<(String, String, int, int)> items;

  final String subtotalLabel;
  final String discountLabel;
  final String feeLabel;
  final String totalLabel;
  final String paidLabel;

  static const empty = OrderDetail(
    id: '—',
    statusLabel: '—',
    date: '—',
    isLive: false,
    isClosed: false,
    returnable: false,
    showInvoice: false,
    items: [],
    subtotalLabel: '₹0',
    discountLabel: '—',
    feeLabel: '₹0',
    totalLabel: '₹0',
    paidLabel: '—',
  );
}

OrderDetail resolveOrderDetail(BasketState state) {
  final o = state.currentOrder;
  if (o == null) return OrderDetail.empty;

  final live = isLiveOrderStatus(o.status);
  final cancelled = o.status == 'cancelled';

  return OrderDetail(
    id: o.orderNumber,
    statusLabel: orderStatusLabel(o.status),
    date: orderDateLabel(o.createdAt),
    isLive: live,
    isClosed: !live,
    returnable: o.status == 'delivered',
    showInvoice: !cancelled,
    items: o.items.map((i) => (i.productName, i.pack, i.qty, i.rate)).toList(),
    subtotalLabel: moneyLabel(o.subtotal),
    discountLabel: cancelled ? 'Refunded' : (o.discount > 0 ? '− ${moneyLabel(o.discount)}' : '—'),
    feeLabel: moneyLabel(o.deliveryFee + o.cgst + o.sgst),
    totalLabel: moneyLabel(o.total),
    paidLabel: cancelled ? 'Refunded' : 'Paid · ${o.paymentMode.toUpperCase()}',
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
