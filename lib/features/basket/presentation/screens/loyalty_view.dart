import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Points balance, earn/redeem history, and the redeem-for-a-coupon form —
/// reached from `AccountView`'s "Loyalty points" row. Data comes from
/// `GET /auth/profile/loyalty/` ([BasketCubit.loadLoyalty]); points are
/// earned automatically when an order is delivered (server-side), this
/// screen only spends them.
class LoyaltyView extends StatefulWidget {
  const LoyaltyView({super.key});

  @override
  State<LoyaltyView> createState() => _LoyaltyViewState();
}

class _LoyaltyViewState extends State<LoyaltyView> {
  final _pointsController = TextEditingController();

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final summary = context.select((BasketCubit c) => c.state.apiLoyaltySummary);
    final submitting = context.select((BasketCubit c) => c.state.redeemSubmitting);
    final message = context.select((BasketCubit c) => c.state.redeemMessage);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: BasketSpace.xs),
              Text('Loyalty points', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
            ],
          ),
        ),
        Expanded(
          child: summary == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(BasketSpace.md),
                      decoration: BoxDecoration(color: BasketColors.primaryLight, borderRadius: BorderRadius.circular(BasketRadius.lg)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR BALANCE',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2).withValues(alpha: 0.6), letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('${summary.points}', style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                              const SizedBox(width: 6),
                              Text('points', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2).withValues(alpha: 0.6))),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Earn 1 point per ₹${LoyaltyRates.pointsPerRupees} spent, delivered automatically after each order. '
                            '${summary.pointsToRupee} point = ${moneyLabel(summary.pointsToRupee)} off.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
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
                          Text('Redeem for a coupon', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            'Minimum ${summary.minRedeemPoints} points at a time.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint),
                          ),
                          const SizedBox(height: BasketSpace.sm),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _pointsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  cursorColor: BasketColors.primary,
                                  style: basketInputText(),
                                  decoration: basketInputDecoration(hintText: 'Points to redeem', dense: true),
                                ),
                              ),
                              const SizedBox(width: BasketSpace.xs),
                              BasketButton(
                                label: 'Redeem',
                                size: BasketButtonSize.medium,
                                expand: false,
                                onPressed: () => _redeem(cubit),
                                loading: submitting,
                              ),
                            ],
                          ),
                          if (message != null) ...[
                            const SizedBox(height: BasketSpace.xs),
                            Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.muted)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: BasketSpace.xl),
                    Text('History', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: BasketSpace.sm),
                    if (summary.transactions.isEmpty)
                      Text(
                        'No activity yet — points show up here after your first delivered order.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                      )
                    else
                      for (final t in summary.transactions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: BasketSpace.xs),
                          child: Container(
                            padding: const EdgeInsets.all(BasketSpace.sm),
                            decoration: basketCard(),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.reason == 'order_reward' ? 'Order reward' : 'Redeemed',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                                      ),
                                      if (t.note.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(t.note, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  t.points > 0 ? '+${t.points}' : '${t.points}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: t.points > 0 ? BasketColors.primary : BasketColors.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
        ),
      ],
    );
  }

  void _redeem(BasketCubit cubit) {
    final points = int.tryParse(_pointsController.text) ?? 0;
    if (points <= 0) return;
    cubit.redeemLoyaltyPoints(points);
  }
}

/// Kept in sync with `LoyaltyTransaction.POINTS_PER_RUPEES` server-side —
/// display-only copy, the actual earn rate is always computed server-side.
class LoyaltyRates {
  static const pointsPerRupees = 20;
}
