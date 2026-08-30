import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
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
                        border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                    ),
                  ),
                  const SizedBox(width: 10),
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
              const SizedBox(height: 14),
              const StepProgress(step: 1),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              for (final a in addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AddressCard(address: a, selected: a.id == selected, onTap: () => cubit.selectAddress(a.id)),
                ),
              GestureDetector(
                onTap: cubit.openAddressEdit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.25), style: BorderStyle.solid, width: 1.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+ Add a new address',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
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
            border: Border(top: BorderSide(color: BasketColors.ink.withValues(alpha: 0.07))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BasketColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: cubit.goToSlot,
                child: Text('Deliver here →', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
              ),
            ),
          ),
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
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Color(0xFFFFFBF2).withValues(alpha: 0.68),
          border: Border.all(color: selected ? BasketColors.primary : Color(0xFFFFFBF2).withValues(alpha: 0.85), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
        ),
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
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          border: Border.all(color: BasketColors.ink.withValues(alpha: 0.14)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(address.tag, style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(address.line, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                  const SizedBox(height: 6),
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
