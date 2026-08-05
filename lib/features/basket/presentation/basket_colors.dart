import 'package:flutter/material.dart';

/// Color tokens lifted directly from `Basket App - Part 1.dc.html`. Scoped
/// to the basket feature only — the rest of the app (restaurant/delivery
/// dashboards) keeps using `core/theme/app_colors.dart`.
class BasketColors {
  BasketColors._();

  static const ink = Color(0xFF0B0B0C);
  static const page = Color(0xFFEDEDEF);
  static const muted = Color(0xFF6F6F78);
  static const faint = Color(0xFF9A9AA2);
  static const slot = Color(0xFFEDEDEF);
  static const slotAlt = Color(0xFFE4E4E8);

  static const white = Colors.white;
}

/// Border/background/foreground for the many two-state "pill" controls
/// throughout the app (filters, day/slot/payment/address pickers, cancel
/// reasons) — matches the source design's `pill(on)` helper.
class PillStyle {
  const PillStyle({required this.border, required this.bg, required this.fg});

  final Color border;
  final Color bg;
  final Color fg;
}

PillStyle pillStyle(bool selected) => selected
    ? const PillStyle(border: BasketColors.ink, bg: BasketColors.ink, fg: Colors.white)
    : PillStyle(
        border: BasketColors.ink.withValues(alpha: 0.14),
        bg: Colors.white.withValues(alpha: 0.7),
        fg: BasketColors.ink,
      );
