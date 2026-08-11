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

    if (product.oos) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: BasketColors.errorSoft, borderRadius: BorderRadius.circular(99)),
        child: Text(
          'SOON',
          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: BasketColors.error),
        ),
      );
    }
    if (qty == 0) {
      // A round icon button, not a labeled pill — matches the reference
      // design's product-card "add" affordance, and green (not brand navy)
      // so it reads as its own small action rather than competing with
      // navy across dozens of tiles on one screen.
      return InkWell(
        onTap: () => cubit.bump(product.id, 1),
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: BasketColors.success,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: BasketColors.success.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add, size: 18, color: Colors.white),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(color: BasketColors.success, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove, onTap: () => cubit.bump(product.id, -1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '$qty',
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          _StepButton(icon: Icons.add, onTap: () => cubit.bump(product.id, 1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
