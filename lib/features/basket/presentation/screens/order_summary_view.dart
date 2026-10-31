import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/coupon_strip.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:fastswipe/features/basket/presentation/widgets/step_progress.dart';
import 'package:fastswipe/features/basket/presentation/widgets/free_delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderSummaryView extends StatefulWidget {
  const OrderSummaryView({super.key});

  @override
  State<OrderSummaryView> createState() => _OrderSummaryViewState();
}

class _OrderSummaryViewState extends State<OrderSummaryView> {
  late final TextEditingController _coupon = TextEditingController(
    text: context.read<BasketCubit>().state.couponInput,
  );

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
    final addr = context.select((BasketCubit c) => addressForState(c.state));
    final day = context.select((BasketCubit c) => c.state.deliveryDay);
    final slot = context.select(
      (BasketCubit c) => BasketCatalog.slotById(c.state.deliverySlotId),
    );
    final appliedCoupon = context.select(
      (BasketCubit c) => c.state.appliedCoupon,
    );
    final couponInput = context.select((BasketCubit c) => c.state.couponInput);
    final couponMessage = context.select((BasketCubit c) => c.state.couponMessage);
    final coupons = usableCouponsFirst(context.select((BasketCubit c) => c.state.apiCoupons));
    final cartSubtotal = context.select((BasketCubit c) => cartTotals(c.state).subtotal);

    if (_coupon.text != couponInput) {
      _coupon.value = TextEditingValue(
        text: couponInput,
        selection: TextSelection.collapsed(offset: couponInput.length),
      );
    }

    final items = context.select(
      (BasketCubit c) => cartMap.entries
          .map((e) {
            final p = productById(c.state, e.key);
            return p == null ? null : (p, e.value);
          })
          .whereType<(BasketProduct, int)>()
          .toList(),
    );

    final slotLabel = slot.id == 'exp'
        ? 'Express, ${BasketCubit.etaMinutes} min'
        : '${BasketCatalog.deliveryDays[day].label} ${slot.label}';
    final slotSub = '${slot.sub} · ${BasketCatalog.deliveryDays[day].date}';
    final appliedLabel = appliedCoupon != null ? '· $appliedCoupon' : '';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: cubit.back,
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
                        'Order summary',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFFBF2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step 3 of 3',
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
              const SizedBox(height: BasketSpace.md),
              const StepProgress(step: 3),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              _SummaryCard(
                title: 'Deliver to · ${addr.label}',
                sub: addr.line,
                onChange: cubit.goToAddress,
              ),
              const SizedBox(height: BasketSpace.section),
              _SummaryCard(
                title: 'Slot · $slotLabel',
                sub: slotSub,
                onChange: cubit.goToSlot,
              ),
              const SizedBox(height: BasketSpace.section),
              Container(
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: basketCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t.itemCount} ${t.itemCount == 1 ? 'item' : 'items'} in this order',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: BasketSpace.sm),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: BasketSpace.xs),
                        itemBuilder: (context, i) {
                          final (p, qty) = items[i];
                          return SizedBox(
                            width: 56,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(BasketRadius.md),
                                  child: ProductImageMini(
                                    size: 56,
                                    imageUrl: p.imageUrl,
                                  ),
                                ),
                                const SizedBox(height: BasketSpace.xxs),
                                Text(
                                  '×$qty',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: BasketSpace.section),
              Container(
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: basketCard(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coupon',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
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
                            controller: _coupon,
                            onChanged: cubit.setCouponInput,
                            textCapitalization: TextCapitalization.characters,
                            cursorColor: BasketColors.primary,
                            style: basketInputText(),
                            decoration: basketInputDecoration(hintText: 'Enter coupon code (e.g. FIRST50)', dense: true),
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.muted),
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
                      label: 'Coupon $appliedLabel',
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
                          moneyLabel(t.payable),
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
                      moneyLabel(t.payable),
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
                label: 'Place order',
                expand: false,
                onPressed: cubit.goToPaymentChoice,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.sub,
    required this.onChange,
  });

  final String title;
  final String sub;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BasketSpace.md),
      decoration: basketCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              BasketButton.text(
                label: 'Change',
                size: BasketButtonSize.small,
                onPressed: onChange,
              ),
            ],
          ),
          const SizedBox(height: BasketSpace.xxs),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: BasketColors.muted,
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
