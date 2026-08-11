import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';

/// The translucent "glass" card look used throughout the design
/// (`rgba(255,255,255,.66-.9)` + faint border + soft shadow). Approximated
/// with a semi-opaque fill instead of `BackdropFilter` blur for perf.
BoxDecoration glassCard({double radius = 16, double opacity = 0.68}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: opacity),
    border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
    borderRadius: BorderRadius.circular(radius),
    // Tighter, tonal shadow (per `stitch_instazepto_grocery_mart`'s
    // "minimal use of shadows" elevation spec) instead of a heavy floaty
    // blur — reads as grounded/corporate rather than glossy.
    boxShadow: [
      BoxShadow(
        color: BasketColors.ink.withValues(alpha: 0.08),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

/// Dark rounded-bottom header used at the top of the shopping screens.
BoxDecoration darkHeaderDecoration() => const BoxDecoration(
      gradient: BasketColors.headerGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
    );

/// Product card look: solid white (not translucent, unlike [glassCard] —
/// these sit on the plain page background, not over photos/gradients),
/// elevated with shadow alone rather than a hard border line, which is what
/// reads as "considered" instead of "boxed-in" at this card size.
BoxDecoration productCardDecoration({double radius = 14}) => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: BasketColors.ink.withValues(alpha: 0.06),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: BasketColors.ink.withValues(alpha: 0.07),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ],
    );
