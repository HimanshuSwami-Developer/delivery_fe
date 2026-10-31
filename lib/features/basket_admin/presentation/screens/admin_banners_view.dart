import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
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
              AdminButton(label: '+ New banner', onPressed: () => cubit.openAddBanner()),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          if (banners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AdminSpace.xxl),
              child: Text('No banners yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
            ),
          AdminResponsiveGrid(
            minTileWidth: 300,
            children: [
              for (final b in banners)
                _BannerCard(
                  banner: b,
                  onToggle: () => cubit.toggleBanner(b.id, !b.isActive),
                  onEdit: () => cubit.openAddBanner(banner: b),
                  onDelete: () => _confirmDelete(context, cubit, b),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner, required this.onToggle, required this.onEdit, required this.onDelete});

  final ApiBanner banner;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final on = banner.isActive;
    final state = on ? 'Live' : 'Paused';
    final placement = _kPlacementLabels[banner.placement] ?? banner.placement;
    return Container(
      padding: const EdgeInsets.all(AdminSpace.md),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 118, width: double.infinity, child: ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.md, caption: 'Banner ${banner.id}')),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              Expanded(child: Text(banner.title, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800))),
              AdminChipBadge(state),
            ],
          ),
          const SizedBox(height: AdminSpace.xxs),
          Text('$placement · ${banner.impressions} impressions', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: AdminColors.muted)),
          const SizedBox(height: AdminSpace.sm),
          Row(
            children: [
              Expanded(
                child: AdminButton.secondary(label: 'Edit', size: AdminButtonSize.small, expand: true, onPressed: onEdit),
              ),
              const SizedBox(width: AdminSpace.xs),
              Expanded(
                child: AdminButton(
                  label: on ? 'Pause' : 'Resume',
                  variant: AdminButtonVariant.tonal,
                  size: AdminButtonSize.small,
                  expand: true,
                  onPressed: onToggle,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpace.xs),
          AdminButton(
            label: 'Delete',
            variant: AdminButtonVariant.danger,
            size: AdminButtonSize.small,
            expand: true,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, BasketAdminCubit cubit, ApiBanner banner) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Delete "${banner.title}"?', style: GoogleFonts.manrope(fontWeight: FontWeight.w800)),
      content: Text('This can\'t be undone.', style: GoogleFonts.manrope(fontSize: 13)),
      actions: [
        AdminButton.secondary(label: 'Cancel', onPressed: () => Navigator.of(dialogContext).pop(false)),
        AdminButton(label: 'Delete', variant: AdminButtonVariant.danger, onPressed: () => Navigator.of(dialogContext).pop(true)),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await cubit.deleteBanner(banner.id);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}
