import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';

/// Legacy name for the standard card — now [basketCard] (white, 1px
/// hairline, 12px corners, no shadow). The old translucent "glass" fill +
/// drop shadow read as soft/floaty next to quick-commerce conventions, so
/// every existing call site picks up the crisp look without changing.
/// [opacity] is ignored and radii above 16 are capped at the card scale.
BoxDecoration glassCard({double radius = BasketRadius.md, double opacity = 0.68}) =>
    basketCard(radius: radius > BasketRadius.lg ? BasketRadius.lg : radius);

/// Dark rounded-bottom header used at the top of the shopping screens.
BoxDecoration darkHeaderDecoration() => const BoxDecoration(
      gradient: BasketColors.headerGradient,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl)),
    );

/// Product tile: white, 1px hairline, 12px corners — no shadow, so a grid
/// of dozens of tiles reads clean rather than busy.
BoxDecoration productCardDecoration({double radius = BasketRadius.md}) => basketCard(radius: radius);
