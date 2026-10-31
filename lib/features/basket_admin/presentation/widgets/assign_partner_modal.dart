import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kDistances = [0.4, 0.9, 1.2, 1.8, 2.4, 3.1];

/// The "Assign delivery partner" sheet opened from order detail: a
/// scrollable list of on-duty partners to pick from, then Cancel/Confirm.
/// Ported from the source design's `modalAssign` overlay.
class AssignPartnerModal extends StatelessWidget {
  const AssignPartnerModal({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final orderNumber = context.select((BasketAdminCubit c) => c.state.currentOrder?.orderNumber ?? c.state.sel);
    final assign = context.select((BasketAdminCubit c) => c.state.assign);
    final available = context.select((BasketAdminCubit c) => c.state.apiPartners.where((p) => p.status != 'off_duty').toList());

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: cubit.closeModal,
            child: ColoredBox(color: AdminColors.ink.withValues(alpha: 0.42)),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              margin: const EdgeInsets.all(AdminSpace.lg),
              padding: const EdgeInsets.all(AdminSpace.xl),
              decoration: adminCard(radius: AdminRadius.lg, border: false, elevated: true),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Assign delivery partner', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                            const SizedBox(height: AdminSpace.xxs),
                            Text(
                              '$orderNumber · pickup bay 3',
                              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted),
                            ),
                          ],
                        ),
                      ),
                      AdminIconActionButton(icon: Icons.close, onTap: cubit.closeModal, size: 32),
                    ],
                  ),
                  const SizedBox(height: AdminSpace.lg),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (var i = 0; i < available.length; i++) ...[
                            if (i > 0) const SizedBox(height: AdminSpace.xs),
                            _PartnerRow(
                              name: available[i].name,
                              meta: '${available[i].partnerCode} · ★ ${available[i].rating}',
                              distance: '${_kDistances[i % _kDistances.length]} km',
                              load: available[i].status == 'on_trip' ? '1 active trip' : 'Free now',
                              selected: assign?.id == available[i].id,
                              onTap: () => cubit.pickAssign(available[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AdminSpace.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AdminButton.secondary(
                          label: 'Cancel',
                          size: AdminButtonSize.large,
                          expand: true,
                          onPressed: cubit.closeModal,
                        ),
                      ),
                      const SizedBox(width: AdminSpace.sm),
                      Expanded(
                        flex: 2,
                        child: AdminButton(
                          label: assign != null ? 'Assign ${assign.name}' : 'Select a partner',
                          size: AdminButtonSize.large,
                          expand: true,
                          onPressed: assign != null ? cubit.confirmAssign : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({
    required this.name,
    required this.meta,
    required this.distance,
    required this.load,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String meta;
  final String distance;
  final String load;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AdminSpace.sm),
        decoration: adminCard(selected: selected),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AdminColors.ink : Colors.transparent,
                border: Border.all(color: AdminColors.ink, width: 1.5),
              ),
            ),
            const SizedBox(width: AdminSpace.sm),
            const SizedBox(
              width: 38,
              height: 38,
              child: ImageSlot(shape: ImageSlotShape.circle, mini: true),
            ),
            const SizedBox(width: AdminSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(meta, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(distance, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(load, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.faint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
