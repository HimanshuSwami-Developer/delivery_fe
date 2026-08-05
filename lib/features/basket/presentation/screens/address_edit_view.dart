import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/map_grid_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _tags = ['Home', 'Work', 'Other'];

class AddressEditView extends StatelessWidget {
  const AddressEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final newTag = context.select((BasketCubit c) => c.state.newAddressTag);
    final phoneLabel = phone.isEmpty ? '98765 43210' : phone;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 250,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: MapGridPainter())),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(9)),
                      child: Text('Drag to set pin', style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                    Container(width: 2, height: 16, color: BasketColors.ink),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BasketColors.ink,
                        boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.16), blurRadius: 0, spreadRadius: 6)],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 14,
                child: InkWell(
                  onTap: cubit.back,
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text('◎ Use my location', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                children: [
                  Text('Add address details', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                  const SizedBox(height: 5),
                  Text('4th Block, Koramangala, Bengaluru 560034', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                  const SizedBox(height: 16),
                  const _FieldCard(label: 'Flat / House no.', value: '302, Sunrise Residency'),
                  const SizedBox(height: 10),
                  const _FieldCard(label: 'Landmark', value: 'Near Forum Mall', muted: true),
                  const SizedBox(height: 10),
                  _FieldCard(label: 'Receiver', value: 'Aarav · +91 $phoneLabel'),
                  const SizedBox(height: 18),
                  Text('Save as', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      for (final tag in _tags) ...[
                        _TagPill(label: tag, selected: newTag == tag, onTap: () => cubit.setNewAddressTag(tag)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: BasketColors.ink,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: cubit.saveAddress,
                      child: Text('Save address', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
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

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.label, required this.value, this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: BasketColors.faint, letterSpacing: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: muted ? FontWeight.w600 : FontWeight.w700,
              color: muted ? BasketColors.faint : BasketColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = pillStyle(selected);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: style.bg,
          border: Border.all(color: style.border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label, style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: style.fg)),
      ),
    );
  }
}
