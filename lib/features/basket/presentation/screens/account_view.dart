import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
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
    final name = context.select((BasketCubit c) => c.state.name);
    final nameLabel = name.isEmpty ? 'Your account' : name;
    final referralCode = context.select((BasketCubit c) => c.state.myReferralCode);
    final loyaltyPoints = context.select((BasketCubit c) => c.state.loyaltyPoints);
    // Live counts for the rows whose subtitle is real data, not copy.
    final couponCount = context.select((BasketCubit c) => c.state.apiCoupons.where((x) => x.usableByMe).length);
    // Joined to a String so `select` compares by value (a new List each
    // time would rebuild on every state change).
    final addressTypes = context.select((BasketCubit c) => c.state.apiAddresses.map((a) => a.addressType).join('\n'));
    final wishlistCount = context.select((BasketCubit c) => c.state.wishlist.length);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.xl),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: const SizedBox(width: 52, height: 52, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
              ),
              const SizedBox(width: BasketSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameLabel, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: 3),
                  Text(
                    '+91 $phone',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(BasketSpace.md),
                decoration: BoxDecoration(color: BasketColors.primaryLight, borderRadius: BorderRadius.circular(BasketRadius.lg)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
                        children: const [TextSpan(text: 'Refer & earn '), TextSpan(text: '₹250', style: TextStyle(color: BasketColors.gold))],
                      ),
                    ),
                    const SizedBox(height: BasketSpace.xxs),
                    Text(
                      'Your friend gets a ₹100 coupon on their first order, you get a ₹250 coupon.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 12),
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
                              referralCode ?? '···',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2), letterSpacing: 1.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: BasketSpace.xs),
                        BasketButton.secondary(
                          label: 'Share',
                          size: BasketButtonSize.small,
                          expand: false,
                          onPressed: referralCode == null
                              ? null
                              : () => SharePlus.instance.share(
                                    ShareParams(
                                      text: 'Use my code $referralCode on Aapno Bazar and get ₹100 off your first order!',
                                    ),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BasketSpace.sm),
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
              const SizedBox(height: BasketSpace.section),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: basketCard(),
                child: Column(
                  children: [
                    _AccountRow(
                      leading: const Text('★', style: TextStyle(fontSize: 15, color: BasketColors.gold)),
                      title: 'Loyalty points',
                      sub: '$loyaltyPoints pts · earn on every order, redeem for coupons',
                      onTap: cubit.goToLoyalty,
                    ),
                    for (final row in BasketCatalog.accountRows) ...[
                      const Divider(height: 1, color: BasketSurface.border),
                      _AccountRow(
                        leading: Text(row.icon, style: const TextStyle(fontSize: 15)),
                        title: row.title,
                        sub: switch (row.target) {
                          BasketScreen.coupons => _couponsSub(couponCount),
                          BasketScreen.addr => _addressesSub(addressTypes.isEmpty ? const [] : addressTypes.split('\n')),
                          BasketScreen.wish => _wishlistSub(wishlistCount),
                          _ => row.sub,
                        },
                        onTap: () => cubit.go(row.target),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: BasketSpace.xl),
              BasketButton(
                label: 'Log out',
                variant: BasketButtonVariant.danger,
                size: BasketButtonSize.medium,
                onPressed: () => _confirmLogout(context, cubit),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _couponsSub(int n) => switch (n) {
        0 => 'No coupons right now',
        1 => '1 available',
        _ => '$n available',
      };

  /// "Home, Work + 1 more" from the saved addresses' types.
  static String _addressesSub(List<String> types) {
    if (types.isEmpty) return 'Add a delivery address';
    String label(String t) => t.isEmpty ? 'Other' : '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
    final shown = types.take(2).map(label).join(', ');
    return types.length > 2 ? '$shown + ${types.length - 2} more' : shown;
  }

  static String _wishlistSub(int n) => n == 0 ? 'Saved for later' : '$n saved for later';

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

/// One row of the account menu card — leading glyph, title + subtitle,
/// chevron; at least 52px tall.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.leading, required this.title, required this.sub, required this.onTap});

  final Widget leading;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: BasketSpace.md, vertical: BasketSpace.sm),
          child: Row(
            children: [
              leading,
              const SizedBox(width: BasketSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                  ],
                ),
              ),
              Text('›', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
            ],
          ),
        ),
      ),
    );
  }
}
