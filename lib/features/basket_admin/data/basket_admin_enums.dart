/// Which of the two top-level screens the admin console is on — mirrors the
/// source design's `isLogin` / `isApp` `sc-if` split.
enum AdminScreen { login, app }

/// Every page the sidebar can route to, plus the two pages reached only by
/// drilling in (`orderDet`, `productNew`) — one flat enum mirrors the source
/// design's single-component `page` field.
enum AdminPage {
  dash,
  orders,
  orderDet,
  products,
  productNew,
  categories,
  inventory,
  customers,
  partners,
  coupons,
  banners,
  notifs,
  sales,
  gst,
  zones,
}

/// The one modal the console has: the delivery-partner assignment sheet
/// opened from order detail (or from a partner row on the Partners page).
enum AdminModal { none, assign }
