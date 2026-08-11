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
  static const error = Color(0xFFD32F2F);

  /// Pale red tint — "cancelled"/error badge backgrounds.
  static const errorSoft = Color(0xFFFFEBEE);

  // ── Neutrals ─────────────────────────────────────────────────────────
  /// Page/app background.
  static const page = Color(0xFFFAFAFA);

  /// Card/section surface a shade darker than [page] (filter bars, image
  /// placeholders).
  static const surface = Color(0xFFF5F5F5);

  /// Charcoal — body/heading text, and the structural dark surfaces
  /// (splash background, screen headers, bottom nav). Not pure black, so
  /// text stays easy on the eyes at length.
  static const ink = Color(0xFF212121);

  /// Secondary text, placeholders.
  static const muted = Color(0xFF757575);

  /// Lighter still — the faintest hint text.
  static const faint = Color(0xFF9E9E9E);

  /// Borders/dividers.
  static const divider = Color(0xFFE0E0E0);

  /// Pending/inactive step markers (order tracking).
  static const pending = Color(0xFFBDBDBD);

  static const slot = Color(0xFFF5F5F5);
  static const slotAlt = Color(0xFFEDEDEE);

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
