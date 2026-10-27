import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/coupon_strip.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:fastswipe/features/basket/presentation/widgets/step_progress.dart';
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
    final coupons = context.select((BasketCubit c) => c.state.apiCoupons);

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
            18,
            MediaQuery.paddingOf(context).top + 12,
            18,
            16,
          ),
          decoration: darkHeaderDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: cubit.back,
                    borderRadius: BorderRadius.circular(99),
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
                  const SizedBox(width: 10),
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
              const SizedBox(height: 14),
              const StepProgress(step: 3),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              _SummaryCard(
                title: 'Deliver to · ${addr.label}',
                sub: addr.line,
                onChange: cubit.goToAddress,
              ),
              const SizedBox(height: 11),
              _SummaryCard(
                title: 'Slot · $slotLabel',
                sub: slotSub,
                onChange: cubit.goToSlot,
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: glassCard(radius: 16),
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
                    const SizedBox(height: 11),
                    SizedBox(
                      height: 76,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final (p, qty) = items[i];
                          return SizedBox(
                            width: 56,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: ProductImageMini(
                                    size: 56,
                                    imageUrl: p.imageUrl,
                                  ),
                                ),
                                const SizedBox(height: 5),
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
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: glassCard(radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coupon',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    if (coupons.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      CouponStrip(
                        coupons: coupons,
                        appliedCoupon: appliedCoupon,
                        onApply: cubit.applyCouponCode,
                        onRemove: cubit.removeCoupon,
                        onViewAll: cubit.goToCoupons,
                      ),
                    ],
                    const SizedBox(height: 9),
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
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.ink),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'Enter coupon code (e.g. FIRST50)',
                              filled: true,
                              fillColor: Color(0xFFFFFBF2),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide(color: BasketColors.ink.withValues(alpha: 0.12)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: BorderSide(color: BasketColors.ink.withValues(alpha: 0.12)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(11),
                                borderSide: const BorderSide(color: BasketColors.primary, width: 1.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BasketColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.applyCoupon,
                          child: Text(
                            'Apply',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2)),
                          ),
                        ),
                      ],
                    ),
                    if (couponMessage.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        couponMessage,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.muted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: glassCard(radius: 16),
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
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      height: 1,
                      color: BasketColors.ink.withValues(alpha: 0.09),
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: Color(0xFFFFFBF2).withValues(alpha: 0.9),
            border: Border(
              top: BorderSide(color: BasketColors.ink.withValues(alpha: 0.07)),
            ),
          ),
          child: SafeArea(
            top: false,
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
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BasketColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                  ),
                  onPressed: cubit.goToPaymentChoice,
                  child: Text(
                    'Place order',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFFBF2),
                    ),
                  ),
                ),
              ],
            ),
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
      padding: const EdgeInsets.all(13),
      decoration: glassCard(radius: 16),
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
              GestureDetector(
                onTap: onChange,
                child: Text(
                  'Change',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: BasketColors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
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
