import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

/// Who signed up with my referral code, and what each one earned me — the
/// tracking/history view that `AccountView`'s "Refer & earn" card links
/// out to. Data comes from `GET /auth/profile/referrals/`
/// ([BasketCubit.loadReferrals]); null until that resolves.
class ReferralsView extends StatelessWidget {
  const ReferralsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final summary = context.select((BasketCubit c) => c.state.apiReferralSummary);

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
              Text('My referrals', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
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
                          Row(
                            children: [
                              Expanded(
                                child: _StatBlock(label: 'Friends joined', value: '${summary.totalReferrals}'),
                              ),
                              Container(width: 1, height: 34, color: Color(0xFFFFFBF2).withValues(alpha: 0.2)),
                              const SizedBox(width: BasketSpace.sm),
                              Expanded(
                                child: _StatBlock(label: 'Coupons earned', value: moneyLabel(summary.totalRewardsEarned)),
                              ),
                            ],
                          ),
                          const SizedBox(height: BasketSpace.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: BasketSpace.xs),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.3)),
                                    borderRadius: BorderRadius.circular(BasketRadius.sm),
                                  ),
                                  child: Text(
                                    summary.referralCode,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2), letterSpacing: 1.3),
                                  ),
                                ),
                              ),
                              const SizedBox(width: BasketSpace.xs),
                              BasketButton.secondary(
                                label: 'Share',
                                size: BasketButtonSize.small,
                                expand: false,
                                onPressed: () => SharePlus.instance.share(
                                  ShareParams(text: 'Use my code ${summary.referralCode} on Aapno Bazar and get a ₹100 coupon on your first order!'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BasketSpace.xl),
                    Text('Referral history', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: BasketSpace.sm),
                    if (summary.referrals.isEmpty)
                      Text(
                        'Nobody has used your code yet — share it to start earning.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                      )
                    else
                      for (final r in summary.referrals)
                        Padding(
                          padding: const EdgeInsets.only(bottom: BasketSpace.xs),
                          child: Container(
                            padding: const EdgeInsets.all(BasketSpace.sm),
                            decoration: basketCard(),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(color: BasketColors.primarySoft, shape: BoxShape.circle),
                                  alignment: Alignment.center,
                                  child: Icon(Icons.person_rounded, size: 18, color: BasketColors.primary),
                                ),
                                const SizedBox(width: BasketSpace.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Joined ${_dateLabel(r.joinedAt)}',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      r.rewardAmount > 0 ? '+${moneyLabel(r.rewardAmount)}' : '—',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: BasketColors.primary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.rewardRedeemed ? 'Redeemed' : 'Available',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.faint),
                                    ),
                                  ],
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

  static String _dateLabel(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.6))),
      ],
    );
  }
}
