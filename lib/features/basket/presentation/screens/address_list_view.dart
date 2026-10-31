import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/step_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressListView extends StatelessWidget {
  const AddressListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final selected = context.select((BasketCubit c) => c.state.addressId);
    final addresses = context.select((BasketCubit c) => c.state.apiAddresses.map(Address.fromApi).toList());

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
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
                        border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                    ),
                  ),
                  const SizedBox(width: BasketSpace.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery address', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                      const SizedBox(height: 2),
                      Text('Step 1 of 3', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: BasketSpace.sm),
              const StepProgress(step: 1),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              for (final a in addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: BasketSpace.section),
                  child: _AddressCard(address: a, selected: a.id == selected, onTap: () => cubit.selectAddress(a.id)),
                ),
              BasketButton.secondary(
                label: '+ Add a new address',
                size: BasketButtonSize.medium,
                onPressed: cubit.openAddressEdit,
              ),
            ],
          ),
        ),
        BasketBottomBar(
          child: BasketButton(label: 'Deliver here →', onPressed: cubit.goToSlot),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.selected, required this.onTap});

  final Address address;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(BasketSpace.md),
        decoration: basketCard(selected: selected),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? BasketColors.primary : Colors.transparent,
                border: Border.all(color: selected ? BasketColors.primary : BasketColors.ink, width: 1.5),
              ),
            ),
            const SizedBox(width: BasketSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(width: BasketSpace.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.xs, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: BasketSurface.borderStrong),
                          borderRadius: BorderRadius.circular(BasketRadius.pill),
                        ),
                        child: Text(address.tag, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: BasketSpace.xxs),
                  Text(address.line, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                  const SizedBox(height: BasketSpace.xs),
                  Text('Delivers in ${address.eta} min', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
