import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final phoneLabel = phone.isEmpty ? '98765 43210' : phone;
    final name = context.select((BasketCubit c) => c.state.name);
    final nameLabel = name.isEmpty ? 'Your account' : name;
    final referralCode = context.select((BasketCubit c) => c.state.myReferralCode);
    final loyaltyPoints = context.select((BasketCubit c) => c.state.loyaltyPoints);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 22),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(width: 52, height: 52, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameLabel, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: 3),
                  Text(
                    '+91 $phoneLabel',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: BasketColors.primaryLight, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
                        children: const [TextSpan(text: 'Refer & earn '), TextSpan(text: '₹250', style: TextStyle(color: BasketColors.gold))],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Your friend gets a ₹100 coupon on their first order, you get a ₹250 coupon.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              referralCode ?? '···',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2), letterSpacing: 1.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: referralCode == null
                              ? null
                              : () => SharePlus.instance.share(
                                    ShareParams(
                                      text: 'Use my code $referralCode on Aapno Bazar and get ₹100 off your first order!',
                                    ),
                                  ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(11)),
                            child: Text('Share', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: BasketColors.ink)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: cubit.goToReferrals,
                      child: Text(
                        'View referral history ›',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2).withValues(alpha: 0.8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: cubit.goToLoyalty,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: glassCard(radius: 15),
                  child: Row(
                    children: [
                      const Text('★', style: TextStyle(fontSize: 15, color: BasketColors.gold)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Loyalty points', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '$loyaltyPoints pts · earn on every order, redeem for coupons',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint),
                            ),
                          ],
                        ),
                      ),
                      Text('›', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final row in BasketCatalog.accountRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => cubit.go(row.target),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: glassCard(radius: 15),
                      child: Row(
                        children: [
                          Text(row.icon, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(row.sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                              ],
                            ),
                          ),
                          Text('›', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _confirmLogout(context, cubit),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: glassCard(radius: 15),
                  child: Row(
                    children: [
                      const Text('⎋', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 12),
                      Text('Log out', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.muted)),
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

  Future<void> _confirmLogout(BuildContext context, BasketCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Log out?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        content: Text(
          'You\'ll need to verify your mobile number again to sign back in.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: BasketColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Log out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: BasketColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.signOut();
    }
  }
}
