import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/coupon_strip.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:fastswipe/features/basket/presentation/widgets/free_delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  late final TextEditingController _coupon = TextEditingController(
    text: context.read<BasketCubit>().state.couponInput,
  );

  @override
  void initState() {
    super.initState();
    // Pick up any delivery-fee change made in the admin console since launch.
    context.read<BasketCubit>().loadDeliverySettings();
  }

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final t = context.select((BasketCubit c) => cartTotals(c.state));
    final cartMap = context.select((BasketCubit c) => c.state.cart);
    final couponInput = context.select((BasketCubit c) => c.state.couponInput);
    final items = context.select((BasketCubit c) => cartProducts(c.state));

    if (_coupon.text != couponInput) {
      _coupon.value = TextEditingValue(
        text: couponInput,
        selection: TextSelection.collapsed(offset: couponInput.length),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            BasketSpace.gutter,
            MediaQuery.paddingOf(context).top + BasketSpace.sm,
            BasketSpace.gutter,
            BasketSpace.md,
          ),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.goHome,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(
                      color: Color(0xFFFFFBF2).withValues(alpha: 0.14),
                    ),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFFFFFBF2),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: BasketSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your basket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFFBF2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.itemCount} ${t.itemCount == 1 ? 'item' : 'items'} · arrives in ${BasketCubit.etaMinutes} min',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFFFBF2).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: t.itemCount == 0
              ? const _EmptyState()
              : _FullCart(
                  couponController: _coupon,
                  items: items,
                  cartMap: cartMap,
                  t: t,
                ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BasketSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
                border: Border.all(
                  color: BasketColors.ink.withValues(alpha: 0.07),
                ),
                borderRadius: BorderRadius.circular(BasketRadius.xl),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.shopping_basket_outlined,
                size: 30,
                color: BasketColors.ink,
              ),
            ),
            const SizedBox(height: BasketSpace.sm),
            Text(
              'Your basket is empty',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: BasketSpace.xs),
            Text(
              "Add a few staples and we'll get them to you in ${BasketCubit.etaMinutes} minutes.",
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: BasketColors.muted,
              ),
            ),
            const SizedBox(height: BasketSpace.md),
            BasketButton(
              label: 'Start shopping',
              size: BasketButtonSize.medium,
              expand: false,
              onPressed: context.read<BasketCubit>().goHome,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullCart extends StatelessWidget {
  const _FullCart({
    required this.couponController,
    required this.items,
    required this.cartMap,
    required this.t,
  });

  final TextEditingController couponController;
  final List<BasketProduct> items;
  final Map<String, int> cartMap;
  final BasketTotals t;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final couponMessage = context.select(
      (BasketCubit c) => c.state.couponMessage,
    );
    final appliedCoupon = context.select(
      (BasketCubit c) => c.state.appliedCoupon,
    );
    final coupons = usableCouponsFirst(context.select((BasketCubit c) => c.state.apiCoupons));
    final cartSubtotal = context.select((BasketCubit c) => cartTotals(c.state).subtotal);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              BasketSpace.gutter,
              BasketSpace.md,
              BasketSpace.gutter,
              BasketSpace.lg,
            ),
            children: [
              for (final p in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: BasketSpace.xs),
                  child: _CartItemRow(product: p, qty: cartMap[p.id] ?? 0),
                ),
              const SizedBox(height: BasketSpace.xxs),
              FreeDeliveryProgressCard(t: t),
              const SizedBox(height: BasketSpace.section),
              Container(
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: basketCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coupon',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (coupons.isNotEmpty) ...[
                      const SizedBox(height: BasketSpace.xs),
                      CouponStrip(
                        coupons: coupons,
                        appliedCoupon: appliedCoupon,
                        onApply: cubit.applyCouponCode,
                        onRemove: cubit.removeCoupon,
                        onViewAll: cubit.goToCoupons,
                        cartSubtotal: cartSubtotal,
                      ),
                    ],
                    const SizedBox(height: BasketSpace.xs),
                    if (appliedCoupon != null)
                      AppliedCouponBanner(
                        code: appliedCoupon,
                        savings: t.discount > 0 ? moneyLabel(t.discount) : '',
                        onRemove: cubit.removeCoupon,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: couponController,
                              onChanged: cubit.setCouponInput,
                              textCapitalization: TextCapitalization.characters,
                              cursorColor: BasketColors.primary,
                              style: basketInputText(),
                              decoration: basketInputDecoration(
                                hintText: 'Enter coupon code (e.g. FIRST50)',
                                dense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: BasketSpace.xs),
                          BasketButton(
                            label: 'Apply',
                            size: BasketButtonSize.medium,
                            expand: false,
                            onPressed: cubit.applyCoupon,
                          ),
                        ],
                      ),
                    if (couponMessage.isNotEmpty) ...[
                      const SizedBox(height: BasketSpace.xs),
                      Text(
                        couponMessage,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: BasketColors.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: BasketSpace.section),
              Container(
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: basketCard(),
                child: Column(
                  children: [
                    _TotalRow(
                      label: 'Item total',
                      value: moneyLabel(t.subtotal),
                    ),
                    const SizedBox(height: 8),
                    _TotalRow(
                      label: 'Coupon discount',
                      value: t.discount > 0
                          ? '− ${moneyLabel(t.discount)}'
                          : '—',
                    ),
                    const SizedBox(height: 8),
                    DeliveryFeeBillRow(t: t),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: BasketSpace.sm),
                      child: Divider(height: 1, color: BasketSurface.border),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'To pay',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          moneyLabel(t.total),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        BasketBottomBar(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      moneyLabel(t.total),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      t.savings > 0
                          ? 'You save ${moneyLabel(t.savings)}'
                          : 'Inclusive of all taxes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: BasketColors.faint,
                      ),
                    ),
                  ],
                ),
              ),
              BasketButton(
                label: 'Checkout →',
                expand: false,
                onPressed: cubit.goCheckout,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.product, required this.qty});

  final BasketProduct product;
  final int qty;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    return Container(
      padding: const EdgeInsets.all(BasketSpace.sm),
      decoration: basketCard(),
      child: Row(
        children: [
          ProductImageMini(size: 56, imageUrl: product.imageUrl),
          const SizedBox(width: BasketSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  product.pack,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: BasketColors.faint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  moneyLabel(product.price * qty),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: BasketColors.ink,
              borderRadius: BorderRadius.circular(BasketRadius.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => cubit.bump(product.id, -1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BasketSpace.xs,
                      vertical: BasketSpace.xs,
                    ),
                    child: Text(
                      '−',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFFBF2),
                      ),
                    ),
                  ),
                ),
                Text(
                  '$qty',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFFBF2),
                  ),
                ),
                InkWell(
                  onTap: () => cubit.bump(product.id, 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: BasketSpace.xs,
                      vertical: BasketSpace.xs,
                    ),
                    child: Text(
                      '+',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFFFBF2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A52),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4A52),
          ),
        ),
      ],
    );
  }
}
