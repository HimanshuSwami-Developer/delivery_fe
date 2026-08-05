import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kPlacementLabels = {'home_carousel': 'Home carousel', 'category_strip': 'Category strip', 'profile': 'Profile banner'};

/// Banner management: a grid of home-carousel/category-strip cards with a
/// live/paused chip and a pause-resume toggle, backed by the real API.
class AdminBannersView extends StatelessWidget {
  const AdminBannersView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final banners = context.select((BasketAdminCubit c) => c.state.apiBanners);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AdminSectionTitle('Home banners')),
              FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  disabledBackgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                ),
                child: Text('+ New banner', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (banners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text('No banners yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
            ),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth < 640 ? 1 : (constraints.maxWidth < 980 ? 2 : 3);
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.92,
              children: [
                for (final b in banners) _BannerCard(banner: b, onToggle: () => cubit.toggleBanner(b.id, !b.isActive)),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onToggle});

  final ApiBanner banner;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final on = banner.isActive;
    final state = on ? 'Live' : 'Paused';
    final placement = _kPlacementLabels[banner.placement] ?? banner.placement;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 118, width: double.infinity, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 13, caption: 'Banner ${banner.id}')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(banner.title, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800))),
              AdminChipBadge(state),
            ],
          ),
          const SizedBox(height: 6),
          Text('$placement · ${banner.impressions} impressions', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: AdminColors.muted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AdminColors.ink, width: 1.3),
                    disabledForegroundColor: AdminColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Edit', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onToggle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AdminColors.ink.withValues(alpha: 0.14)),
                    foregroundColor: AdminColors.muted,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(on ? 'Pause' : 'Resume', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.muted)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
