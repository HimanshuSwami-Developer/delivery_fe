import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/step_progress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class DeliverySlotView extends StatelessWidget {
  const DeliverySlotView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final day = context.select((BasketCubit c) => c.state.deliveryDay);
    final selectedSlot = context.select((BasketCubit c) => c.state.deliverySlotId);

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
                  const SizedBox(width: BasketSpace.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Delivery slot', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                      const SizedBox(height: 2),
                      Text('Step 2 of 3', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: BasketSpace.md),
              const StepProgress(step: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              Row(
                children: [
                  for (var i = 0; i < BasketCatalog.deliveryDays.length; i++) ...[
                    if (i > 0) const SizedBox(width: BasketSpace.xs),
                    Expanded(child: _DayPill(day: BasketCatalog.deliveryDays[i], selected: i == day, onTap: () => cubit.selectDeliveryDay(i))),
                  ],
                ],
              ),
              const SizedBox(height: BasketSpace.md),
              for (final s in BasketCatalog.deliverySlots)
                Padding(
                  padding: const EdgeInsets.only(bottom: BasketSpace.xs),
                  child: _SlotCard(
                    slot: s,
                    selected: s.id == selectedSlot,
                    dim: day > 0 && s.id == 'exp',
                    onTap: () => cubit.selectDeliverySlot(s.id),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(BasketSpace.sm),
                decoration: basketCard(),
                child: Text(
                  'Express slots are dispatched from your nearest store. Scheduled slots arrive within a 2-hour window.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                ),
              ),
            ],
          ),
        ),
        BasketBottomBar(
          child: BasketButton(label: 'Continue to payment →', onPressed: cubit.goToSummary),
        ),
      ],
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day, required this.selected, required this.onTap});

  final DeliveryDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = pillStyle(selected);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: BasketSpace.sm, horizontal: BasketSpace.xs),
        decoration: BoxDecoration(
          color: style.bg,
          border: Border.all(color: style.border, width: 1.5),
          borderRadius: BorderRadius.circular(BasketRadius.md),
        ),
        child: Column(
          children: [
            Text(day.label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: style.fg)),
            const SizedBox(height: 3),
            Opacity(
              opacity: 0.7,
              child: Text(day.date, style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w500, color: style.fg)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.selected, required this.dim, required this.onTap});

  final DeliverySlot slot;
  final bool selected;
  final bool dim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = slot.id == 'exp' ? 'Express · ${BasketCubit.etaMinutes} minutes' : slot.label;
    return Opacity(
      opacity: dim ? 0.4 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(BasketSpace.sm),
          decoration: basketCard(selected: selected),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? BasketColors.ink : Colors.transparent,
                  border: Border.all(color: BasketColors.ink, width: 1.5),
                ),
              ),
              const SizedBox(width: BasketSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(slot.sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                  ],
                ),
              ),
              Text(slot.fee, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}
