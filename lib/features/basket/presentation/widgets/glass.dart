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
      color: BasketColors.ink,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
    );
