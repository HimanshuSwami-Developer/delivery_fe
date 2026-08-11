import 'package:flutter/material.dart';

/// Color tokens for the basket app's palette: White is the dominant
/// surface everywhere (page, cards, bottom nav, sheets); navy is the one
/// *accent* — used sparingly for CTAs, active/selected states, and links,
/// never as a base fill. Structural dark panels (screen headers, hero
/// cards) use a separate neutral [ink], not navy and not flat black/
/// charcoal, so navy doesn't end up painted over the whole app. A couple
/// of extra accent hues cover promo/status elements that shouldn't read as
/// "just another navy thing" (coupon banners, discount badges). Single
/// source of truth — screens reference the named roles below, never raw
/// hex. Scoped to the basket feature only — the rest of the app
/// (restaurant/delivery dashboards) keeps using `core/theme/app_colors.dart`.
///
/// Semantic rule (keep this invariant whenever you touch UI here):
///  - [primary] (navy) — the one accent: every primary action button (Send
///    OTP, Add to cart, Checkout, Place order, ...), navigation active
///    state, links, selection (radios/pills/tags). Used for emphasis, not
///    as a background fill for large panels. Never used for a destructive
///    action.
///  - [ink] (neutral dark) — body/heading text, borders, and the
///    structural dark hero panels (screen headers, dark cards). Distinct
///    from [primary] on purpose — if every dark surface were navy, navy
///    would stop reading as an accent.
///  - [accentTeal] / [accentOrange] — promo/status accents (coupon
///    banners, discount badges) that need to stand apart from both the
///    brand navy and plain ink.
///  - [error] (red) — strictly errors, out-of-stock, cancellations. Never
///    used elsewhere, so it keeps its urgency.
class BasketColors {
  BasketColors._();

  // ── Brand navy — the one accent, used sparingly ─────────────────────
  /// Primary navy — CTA buttons, nav active state, links, selection.
  static const primary = Color(0xFF1A237E);

  /// Lighter navy-blue — secondary tags, subtle accents on top of [ink]
  /// panels.
  static const primaryLight = Color(0xFF4C56AF);

  /// Pale navy tint — soft badge backgrounds where a solid fill would be
  /// too loud.
  static const primarySoft = Color(0xFFE8EAF6);

  /// Text/icon color on top of a [primary] or [primaryLight] fill.
  static const onPrimary = Colors.white;

  /// Two-navy-shade gradient for the login and home screen hero headers —
  /// deeper [primary] at the top-left fading to [primaryLight] at the
  /// bottom-right, instead of a flat fill.
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // ── Other accents — coupon/discount, kept distinct from navy ───────
  /// Coupon banners and savings-related callouts.
  static const accentTeal = Color(0xFF00796B);

  /// Pale teal tint — soft backgrounds for coupon/savings badges.
  static const accentTealSoft = Color(0xFFE0F2F1);

  /// Discount/"% OFF" tags — deliberately not navy or [error] red, so a
  /// deal reads as a deal, not as a warning or a brand element.
  static const accentOrange = Color(0xFFE65100);

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
  /// Page/app background — the dominant surface everywhere, including
  /// chrome like the bottom nav.
  static const page = Color(0xFFF9F9F9);

  /// Card/section surface a shade darker than [page] (filter bars, image
  /// placeholders).
  static const surface = Color(0xFFF3F3F3);

  /// Body/heading text, borders, and structural dark hero panels (screen
  /// headers, dark cards) — a neutral near-black with a faint cool cast.
  /// Deliberately not [primary] navy (so navy stays a sparingly-used
  /// accent) and not a flat charcoal/black.
  static const ink = Color(0xFF20222C);

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
/// a brand-navy role, not a CTA — see [BasketColors] doc.
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
