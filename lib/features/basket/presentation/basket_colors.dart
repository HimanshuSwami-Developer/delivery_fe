import 'package:flutter/material.dart';

/// Color tokens for the basket app's palette: Green + White + Charcoal.
/// Single source of truth — screens reference the named roles below,
/// never raw hex. Scoped to the basket feature only — the rest of the app
/// (restaurant/delivery dashboards) keeps using `core/theme/app_colors.dart`.
///
/// Semantic rule (keep this invariant whenever you touch UI here):
///  - [primary] (green) — the one accent: brand identity, every primary
///    action button (Send OTP, Add to cart, Checkout, Place order, ...),
///    navigation active states, links, selection (radios/pills/tags),
///    live/success status, promo cards. Never used for a destructive
///    action.
///  - [error] (red) — strictly errors, out-of-stock, cancellations. Never
///    used elsewhere, so it keeps its urgency.
class BasketColors {
  BasketColors._();

  // ── Brand green ──────────────────────────────────────────────────────
  /// Primary green — brand identity, every CTA button, nav active state,
  /// links, selection, live status.
  static const primary = Color(0xFF2E7D32);

  /// Lighter green — promo/reward cards, secondary tags, success accents.
  static const primaryLight = Color(0xFF66BB6A);

  /// Pale green tint — soft badge backgrounds (nutritional tags, "in
  /// stock", delivered status) where a solid fill would be too loud.
  static const primarySoft = Color(0xFFE8F5E9);

  /// Text/icon color on top of a [primary] or [primaryLight] fill.
  static const onPrimary = Colors.white;

  // ── Error / destructive (red) ────────────────────────────────────────
  // Aligned to the same error red `core/theme/app_colors.dart` and the
  // `stitch_instazepto_grocery_mart` reference use — one less-alarm-bright
  // red instead of two slightly different ones across the app.
  static const error = Color(0xFFBA1A1A);

  /// Pale red tint — "cancelled"/error badge backgrounds.
  static const errorSoft = Color(0xFFFFDAD6);

  // ── Neutrals ─────────────────────────────────────────────────────────
  // Tones nudged toward `stitch_instazepto_grocery_mart/mercantile_core`'s
  // cooler, slightly-more-defined neutral scale — same tier structure
  // (page < surface < divider, ink > muted > faint), just recalibrated.
  /// Page/app background.
  static const page = Color(0xFFF9F9F9);

  /// Card/section surface a shade darker than [page] (filter bars, image
  /// placeholders).
  static const surface = Color(0xFFF3F3F3);

  /// Charcoal — body/heading text, and the structural dark surfaces
  /// (splash background, screen headers, bottom nav). Not pure black, so
  /// text stays easy on the eyes at length.
  static const ink = Color(0xFF1A1C1C);

  /// Secondary text, placeholders.
  static const muted = Color(0xFF75777C);

  /// Lighter still — the faintest hint text.
  static const faint = Color(0xFF9AA0A6);

  /// Borders/dividers — a touch more defined than before, for a bit more
  /// structural clarity on cards/inputs.
  static const divider = Color(0xFFD8DADC);

  /// Pending/inactive step markers (order tracking).
  static const pending = Color(0xFFBDBDBD);

  static const slot = Color(0xFFF3F3F3);
  static const slotAlt = Color(0xFFEEEEEE);

  static const white = Colors.white;
}

/// Border/background/foreground for the many two-state "pill" controls
/// throughout the app (filters, day/slot/payment/address pickers, cancel
/// reasons) — matches the source design's `pill(on)` helper. Selection is
/// a brand-green role, not a CTA — see [BasketColors] doc.
class PillStyle {
  const PillStyle({required this.border, required this.bg, required this.fg});

  final Color border;
  final Color bg;
  final Color fg;
}

PillStyle pillStyle(bool selected) => selected
    ? const PillStyle(border: BasketColors.primary, bg: BasketColors.primary, fg: BasketColors.onPrimary)
    : PillStyle(
        border: BasketColors.ink.withValues(alpha: 0.14),
        bg: Colors.white.withValues(alpha: 0.7),
        fg: BasketColors.ink,
      );
