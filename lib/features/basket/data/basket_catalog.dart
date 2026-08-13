import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:flutter/material.dart';

/// Catalog data ported from `Basket App - Parts 1-2.dc.html`'s `<script>`
/// block (`CATS`, `P`, `COUPONS`, `OB`, `ACCT`, `ADDRS`, `DAYS`, `SLOTS`,
/// `PAYS`, `TL`, `HIST`, `NOTIFS`, `FAQS`, `CARDS`, `REASONS`) so filtering,
/// search, coupons, checkout, and order history behave identically to the
/// source design, not just look like it.
class BasketCatalog {
  BasketCatalog._();

  static const categories = <BasketCategory>[
    BasketCategory(
      key: 'fruits',
      name: 'Fruits & Veg',
      subs: ['Fresh Fruits', 'Exotic', 'Vegetables', 'Herbs', 'Cut & Peeled'],
      count: 312,
    ),
    BasketCategory(
      key: 'dairy',
      name: 'Dairy & Eggs',
      subs: ['Milk', 'Curd & Yogurt', 'Cheese & Butter', 'Paneer', 'Eggs'],
      count: 148,
    ),
    BasketCategory(
      key: 'staples',
      name: 'Atta, Rice & Dal',
      subs: ['Atta & Flours', 'Rice', 'Dals & Pulses', 'Oils', 'Salt & Sugar'],
      count: 205,
    ),
    BasketCategory(
      key: 'snacks',
      name: 'Snacks & Biscuits',
      subs: ['Namkeen', 'Biscuits', 'Chips', 'Instant Food'],
      count: 418,
    ),
    BasketCategory(
      key: 'bev',
      name: 'Tea, Coffee & More',
      subs: ['Tea', 'Coffee', 'Juices', 'Water'],
      count: 176,
    ),
    BasketCategory(
      key: 'home',
      name: 'Home & Cleaning',
      subs: ['Detergents', 'Cleaners', 'Tissue'],
      count: 264,
    ),
  ];

  static BasketCategory categoryByKey(String key) =>
      categories.firstWhere((c) => c.key == key, orElse: () => categories.first);

  static const products = <BasketProduct>[
    BasketProduct(id: 'd1', name: 'Nandini Toned Milk Pouch', pack: '500 ml', price: 34, mrp: 40, cat: 'dairy', sub: 'Milk', brand: 'Nandini', rating: 4.4, ratingsCount: 1208),
    BasketProduct(id: 'd2', name: 'Amul Taaza Toned Milk', pack: '1 L', price: 66, mrp: 72, cat: 'dairy', sub: 'Milk', brand: 'Amul', rating: 4.3, ratingsCount: 842),
    BasketProduct(id: 'd3', name: 'Heritage Full Cream Milk', pack: '500 ml', price: 38, mrp: 42, cat: 'dairy', sub: 'Milk', brand: 'Heritage', rating: 4.1, ratingsCount: 318, oos: true),
    BasketProduct(id: 'd4', name: 'Milky Mist Curd Cup', pack: '400 g', price: 52, mrp: 60, cat: 'dairy', sub: 'Curd & Yogurt', brand: 'Milky Mist', rating: 4.5, ratingsCount: 2104),
    BasketProduct(id: 'd5', name: 'Epigamia Greek Yogurt Blueberry', pack: '90 g', price: 60, mrp: 65, cat: 'dairy', sub: 'Curd & Yogurt', brand: 'Epigamia', rating: 4.2, ratingsCount: 986),
    BasketProduct(id: 'd6', name: 'Amul Butter Pasteurised', pack: '500 g', price: 285, mrp: 295, cat: 'dairy', sub: 'Cheese & Butter', brand: 'Amul', rating: 4.7, ratingsCount: 5321),
    BasketProduct(id: 'd7', name: 'Amul Cheese Slices', pack: '200 g', price: 135, mrp: 145, cat: 'dairy', sub: 'Cheese & Butter', brand: 'Amul', rating: 4.4, ratingsCount: 1877),
    BasketProduct(id: 'd8', name: 'Milky Mist Fresh Paneer', pack: '200 g', price: 99, mrp: 110, cat: 'dairy', sub: 'Paneer', brand: 'Milky Mist', rating: 4.6, ratingsCount: 2650),
    BasketProduct(id: 'd9', name: 'Farm Fresh Brown Eggs', pack: '6 pcs', price: 72, mrp: 84, cat: 'dairy', sub: 'Eggs', brand: 'Farm Fresh', rating: 4.3, ratingsCount: 1440),
    BasketProduct(id: 'f1', name: 'Alphonso Mango', pack: '1 kg', price: 240, mrp: 299, cat: 'fruits', sub: 'Fresh Fruits', brand: 'Farm', rating: 4.6, ratingsCount: 1902),
    BasketProduct(id: 'f2', name: 'Banana Robusta', pack: '500 g', price: 28, mrp: 34, cat: 'fruits', sub: 'Fresh Fruits', brand: 'Farm', rating: 4.2, ratingsCount: 3210),
    BasketProduct(id: 'f3', name: 'Pomegranate Bhagwa', pack: '2 pcs', price: 96, mrp: 120, cat: 'fruits', sub: 'Fresh Fruits', brand: 'Farm', rating: 4.4, ratingsCount: 760),
    BasketProduct(id: 'f4', name: 'Tomato Hybrid', pack: '500 g', price: 22, mrp: 28, cat: 'fruits', sub: 'Vegetables', brand: 'Farm', rating: 4.0, ratingsCount: 2870),
    BasketProduct(id: 'f5', name: 'Onion Nashik', pack: '1 kg', price: 38, mrp: 45, cat: 'fruits', sub: 'Vegetables', brand: 'Farm', rating: 4.1, ratingsCount: 3990),
    BasketProduct(id: 'f6', name: 'Baby Spinach', pack: '250 g', price: 35, mrp: 42, cat: 'fruits', sub: 'Vegetables', brand: 'Farm', rating: 4.3, ratingsCount: 540),
    BasketProduct(id: 'f7', name: 'Coriander Bunch', pack: '100 g', price: 12, mrp: 16, cat: 'fruits', sub: 'Herbs', brand: 'Farm', rating: 4.2, ratingsCount: 1180),
    BasketProduct(id: 'f8', name: 'Avocado Imported', pack: '2 pcs', price: 210, mrp: 260, cat: 'fruits', sub: 'Exotic', brand: 'Import', rating: 4.1, ratingsCount: 320, oos: true),
    BasketProduct(id: 's1', name: 'Aashirvaad Shudh Chakki Atta', pack: '5 kg', price: 289, mrp: 320, cat: 'staples', sub: 'Atta & Flours', brand: 'Aashirvaad', rating: 4.6, ratingsCount: 8210),
    BasketProduct(id: 's2', name: 'India Gate Basmati Rice', pack: '1 kg', price: 135, mrp: 150, cat: 'staples', sub: 'Rice', brand: 'India Gate', rating: 4.5, ratingsCount: 3120),
    BasketProduct(id: 's3', name: 'Tata Sampann Toor Dal', pack: '1 kg', price: 142, mrp: 165, cat: 'staples', sub: 'Dals & Pulses', brand: 'Tata Sampann', rating: 4.4, ratingsCount: 2640),
    BasketProduct(id: 's4', name: 'Fortune Sunflower Oil', pack: '1 L', price: 149, mrp: 165, cat: 'staples', sub: 'Oils', brand: 'Fortune', rating: 4.3, ratingsCount: 4120),
    BasketProduct(id: 's5', name: 'Tata Salt Iodised', pack: '1 kg', price: 28, mrp: 30, cat: 'staples', sub: 'Salt & Sugar', brand: 'Tata', rating: 4.7, ratingsCount: 9800),
    BasketProduct(id: 'n1', name: 'Haldiram Aloo Bhujia', pack: '400 g', price: 110, mrp: 125, cat: 'snacks', sub: 'Namkeen', brand: 'Haldiram', rating: 4.5, ratingsCount: 4210),
    BasketProduct(id: 'n2', name: 'Parle-G Gold Biscuits', pack: '1 kg', price: 185, mrp: 200, cat: 'snacks', sub: 'Biscuits', brand: 'Parle', rating: 4.6, ratingsCount: 6720),
    BasketProduct(id: 'n3', name: 'Britannia Good Day Cashew', pack: '600 g', price: 145, mrp: 160, cat: 'snacks', sub: 'Biscuits', brand: 'Britannia', rating: 4.4, ratingsCount: 2310),
    BasketProduct(id: 'n4', name: 'Maggi 2-Minute Noodles', pack: '12 pack', price: 168, mrp: 180, cat: 'snacks', sub: 'Instant Food', brand: 'Maggi', rating: 4.5, ratingsCount: 7420),
    BasketProduct(id: 'b1', name: 'Tata Tea Gold', pack: '500 g', price: 275, mrp: 300, cat: 'bev', sub: 'Tea', brand: 'Tata Tea', rating: 4.5, ratingsCount: 3410),
    BasketProduct(id: 'b2', name: 'Nescafe Classic Coffee', pack: '100 g', price: 340, mrp: 365, cat: 'bev', sub: 'Coffee', brand: 'Nescafe', rating: 4.4, ratingsCount: 2870),
    BasketProduct(id: 'b3', name: 'Real Mixed Fruit Juice', pack: '1 L', price: 110, mrp: 125, cat: 'bev', sub: 'Juices', brand: 'Real', rating: 4.2, ratingsCount: 1620),
    BasketProduct(id: 'b4', name: 'Bisleri Water Can', pack: '5 L', price: 75, mrp: 85, cat: 'bev', sub: 'Water', brand: 'Bisleri', rating: 4.1, ratingsCount: 980),
  ];

  static BasketProduct? byId(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const coupons = <String, BasketCoupon>{
    'FIRST50': BasketCoupon(code: 'FIRST50', off: 50, min: 499, label: 'FIRST50 applied — ₹50 off'),
    'FRESH10': BasketCoupon(code: 'FRESH10', pct: 10, min: 199, label: 'FRESH10 applied — 10% off'),
  };

  static const onboarding = <OnboardSlide>[
    OnboardSlide(
      badge: 'Fresh from the mandi',
      title: 'Your neighbourhood bazar, now in your pocket',
      body: 'Handpicked fruits, vegetables and daily staples sourced every morning from local sellers you already trust.',
      slotLabel: 'Onboarding illustration 1',
      icon: Icons.eco_rounded,
    ),
    OnboardSlide(
      badge: '15-minute delivery',
      title: 'Delivered before the kettle boils',
      body: 'Riders from the store closest to you bring your order in 15 minutes flat — with live tracking from cart to doorstep.',
      slotLabel: 'Onboarding illustration 2',
      icon: Icons.bolt_rounded,
    ),
    OnboardSlide(
      badge: 'Everyday savings',
      title: 'Bazar prices, no bargaining needed',
      body: 'Weekly wholesale rates, family packs and a running total that never surprises you at checkout.',
      slotLabel: 'Onboarding illustration 3',
      icon: Icons.price_check_rounded,
    ),
  ];

  static const accountRows = <AccountRow>[
    AccountRow(icon: '⬒', title: 'My orders', sub: 'Track, reorder or return', target: BasketScreen.orders),
    AccountRow(icon: '◈', title: 'Saved addresses', sub: 'Home, Work + 1 more', target: BasketScreen.addr),
    AccountRow(icon: '✧', title: 'My coupons', sub: '2 available', target: BasketScreen.coupons),
    AccountRow(icon: '◑', title: 'Notifications', sub: 'Offers and order updates', target: BasketScreen.notifs),
    AccountRow(icon: '♡', title: 'Wishlist', sub: 'Saved for later', target: BasketScreen.wish),
    AccountRow(icon: '☏', title: 'Help & support', sub: 'Chat, call or WhatsApp', target: BasketScreen.support),
  ];

  static const buyAgainIds = ['d1', 'n4', 's5', 'f2', 'd6'];
  static const recommendedIds = ['s1', 'd8', 'b1', 'n1', 'f1', 's3'];
  static const repeatOrderCart = {'d1': 2, 's1': 1, 'f4': 1, 'n4': 1, 'd8': 1, 's5': 1};

  static const addresses = <Address>[
    Address(
      id: 'home',
      label: 'Home',
      tag: 'Default',
      line: '302, Sunrise Residency, 4th Block Koramangala, Bengaluru 560034',
      eta: 12,
    ),
    Address(
      id: 'work',
      label: 'Work',
      tag: 'Office',
      line: 'WeWork Galaxy, 43 Residency Road, Bengaluru 560025',
      eta: 18,
    ),
    Address(
      id: 'mom',
      label: "Mom's place",
      tag: 'Other',
      line: '12, 8th Cross, Malleshwaram, Bengaluru 560003',
      eta: 26,
    ),
  ];

  static Address addressById(String id) =>
      addresses.firstWhere((a) => a.id == id, orElse: () => addresses.first);

  static const deliveryDays = <DeliveryDay>[
    DeliveryDay('Today', '4 Aug'),
    DeliveryDay('Tomorrow', '5 Aug'),
    DeliveryDay('Wed', '6 Aug'),
  ];

  static const deliverySlots = <DeliverySlot>[
    DeliverySlot(id: 'exp', label: 'Express delivery', sub: 'Next available rider', fee: 'FREE'),
    DeliverySlot(id: 'am', label: '8:00 – 10:00 AM', sub: 'Morning window', fee: 'FREE'),
    DeliverySlot(id: 'noon', label: '12:00 – 2:00 PM', sub: 'Afternoon window', fee: 'FREE'),
    DeliverySlot(id: 'eve', label: '6:00 – 8:00 PM', sub: 'Evening window · high demand', fee: '₹19'),
  ];

  static DeliverySlot slotById(String id) =>
      deliverySlots.firstWhere((s) => s.id == id, orElse: () => deliverySlots.first);

  static const paymentMethods = <PaymentMethod>[
    PaymentMethod(id: 'upi', name: 'UPI', sub: 'GPay, PhonePe, Paytm & more', icon: '◈'),
    PaymentMethod(id: 'card', name: 'Credit / debit card', sub: 'Visa, Mastercard, RuPay', icon: '▭'),
    PaymentMethod(id: 'net', name: 'Net banking', sub: 'All major Indian banks', icon: '▤'),
    PaymentMethod(id: 'wallet', name: 'Basket wallet', sub: 'Balance ₹250', icon: '◐'),
    PaymentMethod(id: 'cod', name: 'Cash on delivery', sub: 'Pay the rider · no extra fee', icon: '₹'),
  ];

  static PaymentMethod paymentMethodById(String id) =>
      paymentMethods.firstWhere((m) => m.id == id, orElse: () => paymentMethods.first);

  static const trackingSteps = <TimelineStep>[
    TimelineStep('Order confirmed', 'Payment received'),
    TimelineStep('Packed at dark store', 'Items picked and sealed'),
    TimelineStep('Out for delivery', 'Rider heading to your address'),
    TimelineStep('Delivered', 'Handed over at your door'),
  ];

  static const orderHistory = <OrderHistoryEntry>[
    OrderHistoryEntry(
      id: 'BSK-4471',
      date: 'Today, 6:12 PM',
      status: 'On the way',
      live: true,
      productIds: ['s1', 'd6', 'f1', 'n1', 'b3', 'd1'],
    ),
    OrderHistoryEntry(
      id: 'BSK-4390',
      date: '2 Aug, 9:04 AM',
      status: 'Delivered',
      live: false,
      productIds: ['s1', 'd6', 'f1', 'n1', 'b1', 'd8'],
    ),
    OrderHistoryEntry(
      id: 'BSK-4288',
      date: '28 Jul, 7:41 PM',
      status: 'Delivered',
      live: false,
      productIds: ['d1', 'd4', 'f4', 'f5', 'n4', 's5'],
    ),
    OrderHistoryEntry(
      id: 'BSK-4175',
      date: '21 Jul, 11:20 AM',
      status: 'Cancelled',
      live: false,
      productIds: ['s3', 'f2', 'd9'],
    ),
  ];

  static OrderHistoryEntry get liveOrder => orderHistory.first;

  static OrderHistoryEntry? orderById(String id) {
    for (final o in orderHistory) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Sum of item prices for a past order (qty 1 each), matching the source
  /// design's `HSUB(o)` helper.
  static int historicalSubtotal(OrderHistoryEntry o) {
    return o.productIds.fold(0, (sum, id) {
      final p = byId(id);
      return sum + (p?.price ?? 0);
    });
  }

  /// Matches the source design's `HTOT(o)` helper: subtotal minus a ₹40
  /// promo discount (waived if the order was cancelled) plus a flat ₹19
  /// delivery fee.
  static int historicalTotal(OrderHistoryEntry o) {
    return historicalSubtotal(o) - (o.status == 'Cancelled' ? 0 : 40) + 19;
  }

  static const notifications = <NotificationItem>[
    NotificationItem('◍', 'Rider is 5 minutes away', 'Ravi is approaching Sunrise Residency with order BSK-4471.', '2 min ago'),
    NotificationItem('✧', 'FRESH10 is back', '10% off all fruit and veg until midnight. Min order ₹199.', '1 hr ago'),
    NotificationItem('⬒', 'Order BSK-4390 delivered', 'Rate your items and get 20 loyalty points.', '2 days ago'),
    NotificationItem('◐', '₹250 referral credit added', 'Your friend Meera placed her first order.', '3 days ago'),
  ];

  static const faqs = <String>[
    'An item is missing from my order',
    'How do returns and refunds work?',
    'Change my delivery slot',
    'Where is my GST invoice?',
    'Delete my account',
  ];

  static const couponCards = <CouponCard>[
    CouponCard(code: 'FIRST50', title: '₹50 off your first order', terms: 'Min order ₹499 · one use per account · valid till 31 Aug'),
    CouponCard(code: 'FRESH10', title: '10% off fruits & vegetables', terms: 'Min order ₹199 · max discount ₹120 · today only'),
  ];

  static const cancelReasons = <String>[
    'Ordered by mistake',
    'Delivery is taking too long',
    'Found a better price',
    'Changed my mind',
  ];

  static const returnReasons = <String>[
    'Item damaged or leaking',
    'Wrong item delivered',
    'Expired or near expiry',
    'Quality not as expected',
  ];

  static List<String> reasonsFor(CancelMode mode) =>
      mode == CancelMode.returnItems ? returnReasons : cancelReasons;
}
