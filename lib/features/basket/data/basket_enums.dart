/// Every screen the Basket app can be on. One flat enum mirrors the source
/// design's single-component screen switch — navigation is internal state
/// (a `history` stack the [BasketCubit] owns), not `go_router` routes.
enum BasketScreen {
  splash,
  onboard,
  login,
  otp,
  setup,
  home,
  cats,
  list,
  search,
  pdp,
  cart,
  account,
  wish,
  addr,
  addrEdit,
  slot,
  summary,
  payChoice,
  qrPayment,
  paying,
  success,
  failure,
  orders,
  orderDet,
  track,
  coupons,
  notifs,
  support,
}

/// The 5 pre-auth screens render as their own full-bleed `Scaffold` (own
/// background color, no shared chrome). Every other screen — including
/// PDP, cart, and all of checkout/orders/account — shares one page
/// background via the shopping shell; most add their own dark header, and
/// none of them get the bottom nav or floating cart bar unless they're
/// also in [kBottomNavScreens] / [kCartBarScreens] below.
const kPreShellScreens = {
  BasketScreen.splash,
  BasketScreen.onboard,
  BasketScreen.login,
  BasketScreen.otp,
  BasketScreen.setup,
};

/// Screens that show the bottom tab bar. Deliberately excludes `pdp` and
/// `cart` (each has its own sticky bottom bar instead) and every
/// checkout/orders/account sub-page (those are pushed full-screen flows) —
/// matching the source design's `shopping && screen !== 'cart'` exactly.
const kBottomNavScreens = {
  BasketScreen.home,
  BasketScreen.cats,
  BasketScreen.list,
  BasketScreen.search,
  BasketScreen.account,
};

const kCartBarScreens = {
  BasketScreen.home,
  BasketScreen.cats,
  BasketScreen.list,
  BasketScreen.search,
};

enum CatalogView { grid, rows }

enum PriceBand { all, low, mid, high }

enum SortOption { popularity, priceAsc, priceDesc, discount }

enum PdpTab { description, nutrition, reviews }

enum ActiveSheet { none, filter, cancelOrReturn }

enum CancelMode { cancel, returnItems }
