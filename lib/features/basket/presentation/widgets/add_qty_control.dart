import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// The "ADD" button / qty-stepper toggle used on product tiles across
/// home, category list, and search — swaps to a −/qty/+ stepper once the
/// item is in the cart, exactly like the source design's `p.noQty`/`p.hasQty`
/// branches. Selects only this product's quantity, so bumping one tile's
/// count never rebuilds its siblings.
class AddQtyControl extends StatelessWidget {
  const AddQtyControl({super.key, required this.product});

  final BasketProduct product;

  @override
  Widget build(BuildContext context) {
    final qty = context.select((BasketCubit c) => c.state.cart[product.id] ?? 0);
    final cubit = context.read<BasketCubit>();

    if (qty == 0) {
      final accent = product.oos ? BasketColors.error : BasketColors.primary;
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accent, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: product.oos ? null : () => cubit.bump(product.id, 1),
        child: Text(
          product.oos ? 'SOON' : 'ADD',
          style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w800, color: accent),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(color: BasketColors.primary, borderRadius: BorderRadius.circular(9)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(label: '−', onTap: () => cubit.bump(product.id, -1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$qty',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          _StepButton(label: '+', onTap: () => cubit.bump(product.id, 1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ),
    );
  }
}
