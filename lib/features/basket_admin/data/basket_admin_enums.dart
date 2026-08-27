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
}

/// Every modal the console can show: the delivery-partner assignment sheet
/// (opened from order detail or a partner row on the Partners page), and
/// one simple add-form dialog per entity that only needs a couple of
/// fields (product has its own full page instead — see `AdminPage.productNew`).
enum AdminModal { none, assign, addCategory, partnerForm, addCoupon, addBanner }
