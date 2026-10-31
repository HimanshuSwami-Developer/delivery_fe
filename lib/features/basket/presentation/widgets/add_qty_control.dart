import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Blinkit-style "ADD" button / qty-stepper toggle used on product
/// tiles across home, category list, and search — swaps to a −/qty/+ stepper once the
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
        height: _height,
        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.xs),
        decoration: BoxDecoration(
          color: BasketSurface.card,
          border: Border.all(color: BasketSurface.borderStrong),
          borderRadius: BasketRadius.chip,
        ),
        alignment: Alignment.center,
        child: Text(
          'SOON',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: BasketColors.faint),
        ),
      );
    }
    // Same 64×32 box in both states so the tile never jumps when the ADD
    // flips to a stepper. Green (not brand navy) so it reads as its own
    // small action rather than competing with navy across dozens of tiles.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(anim), child: child)),
      child: qty == 0
          ? Material(
              key: const ValueKey('add'),
              color: BasketSurface.card,
              shape: RoundedRectangleBorder(
                borderRadius: BasketRadius.chip,
                side: const BorderSide(color: BasketColors.success),
              ),
              elevation: 1,
              shadowColor: BasketColors.ink.withValues(alpha: 0.25),
              child: InkWell(
                onTap: () => cubit.bump(product.id, 1),
                borderRadius: BasketRadius.chip,
                child: SizedBox(
                  width: _width,
                  height: _height,
                  child: Center(
                    child: Text(
                      'ADD',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4, color: BasketColors.success),
                    ),
                  ),
                ),
              ),
            )
          : Material(
              key: const ValueKey('stepper'),
              color: BasketColors.success,
              borderRadius: BasketRadius.chip,
              elevation: 1,
              shadowColor: BasketColors.ink.withValues(alpha: 0.25),
              child: SizedBox(
                width: _width,
                height: _height,
                child: Row(
                  children: [
                    _StepButton(icon: Icons.remove_rounded, onTap: () => cubit.bump(product.id, -1)),
                    Expanded(
                      child: Text(
                        '$qty',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    _StepButton(icon: Icons.add_rounded, onTap: () => cubit.bump(product.id, 1)),
                  ],
                ),
              ),
            ),
    );
  }

  static const double _width = 64;
  static const double _height = 32;
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BasketRadius.chip,
      child: SizedBox(
        width: 22,
        height: double.infinity,
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
