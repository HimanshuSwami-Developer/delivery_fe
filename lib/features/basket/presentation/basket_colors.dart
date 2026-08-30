import 'package:flutter/material.dart';

/// Color tokens for the basket app's palette — "Aapno Bazar" brand navy
/// (`#0A1F3C`) and gold (`#F3B14A`), ported 1:1 from the Claude Design
/// splash/onboarding/OTP mockup and extended across the rest of the app.
/// A warm ivory (`#FFFBF2`) is the dominant surface everywhere (page,
/// cards, bottom nav, sheets) — swapped in for plain white so the app
/// reads as navy + gold + ivory rather than navy-on-white; navy is the
/// primary accent — CTAs, active/selected states, links, and (per the
/// design's own convention, where heading text and CTAs share the same
/// `#0A1F3C`) body/heading text and structural dark panels too — see
/// [ink]. [gold] is the secondary accent, used the same
/// way the design itself uses it: badge highlights (discount tags, rating
/// stars, active-tab dots), never as a base fill or a CTA color (that's
/// still navy's job — two competing "primary" colors would muddy the
/// selection/CTA signal). [accentTeal] covers coupon/savings callouts,
/// which the mockup never specifies, so it's kept as its own pre-existing
/// functional color. Single source of truth — screens reference the named
/// roles below, never raw hex. Scoped to the basket feature only — the
/// rest of the app (restaurant/delivery dashboards) keeps using
/// `core/theme/app_colors.dart`.
///
/// Semantic rule (keep this invariant whenever you touch UI here):
///  - [primary] (navy) — every primary action button (Send OTP, Add to
///    cart, Checkout, Place order, ...), navigation active state, links,
///    selection (radios/pills/tags). The only CTA/selection color.
///  - [ink] (navy) — body/heading text, borders, and the structural dark
///    hero panels (screen headers, dark cards). Equal to [primary] — the
///    design doesn't distinguish a separate "text navy" from "brand navy"
///    (its heading text and CTAs are the same `#0A1F3C`) — kept as a
///    separate named constant only so call sites don't need to change.
///  - [gold] — decorative highlight only: discount badges, rating stars,
///    badge-chip dots, an emphasized word/amount in a sentence. Never a
///    button fill or a selection state (that would compete with navy).
///  - [accentTeal] — coupon/savings callouts, standing apart from both
///    navy and gold.
///  - [error] (red) — strictly errors, out-of-stock, cancellations. Never
///    used elsewhere, so it keeps its urgency.
class BasketColors {
  BasketColors._();

  // ── Brand navy — "Aapno Bazar" ──────────────────────────────────────
  /// Primary navy — CTA buttons, nav active state, links, selection.
  static const primary = Color(0xFF0A1F3C);

  /// Lighter navy — gradient highlight (header glow), secondary tags,
  /// subtle accents on top of [ink] panels.
  static const primaryLight = Color(0xFF173C6E);

  /// Pale warm-ivory tint — soft badge/panel backgrounds where a solid
  /// fill would be too loud. Matches the design's hero-panel/input fill.
  static const primarySoft = Color(0xFFF6EFE0);

  /// Gold accent — badge dots, highlighted phrases on dark navy, the
  /// splash logo's sprout. The design's only non-navy brand color.
  static const gold = Color(0xFFF3B14A);

  /// Text/icon color on top of a [primary] or [primaryLight] fill.
  static const onPrimary = Color(0xFFFFFBF2);

  /// Radial navy gradient for screen hero headers — ported from the
  /// splash/OTP/login mockups (`radial-gradient(...#173C6E 0%, #0A1F3C
  /// 62-72%)`) rather than a flat fill or the old diagonal linear one.
  static const headerGradient = RadialGradient(
    center: Alignment(-0.5, -1),
    radius: 1.4,
    colors: [primaryLight, primary],
    stops: [0, 0.72],
  );

  // ── Other accents — coupon/discount, kept distinct from navy ───────
  /// Coupon banners and savings-related callouts.
  static const accentTeal = Color(0xFF00796B);

  /// Pale teal tint — soft backgrounds for coupon/savings badges.
  static const accentTealSoft = Color(0xFFE0F2F1);

  /// "Add to cart" / positive-action green — the product card's add button
  /// specifically. Kept apart from [primary] navy (that's for the *page's*
  /// CTAs — Send OTP, Checkout, Place order) so a tiny per-tile add button
  /// doesn't compete with navy for attention against dozens of tiles.
  static const success = Color(0xFF108910);

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
  static const page = Color(0xFFFAF3E7);

  /// Card/section surface a shade darker than [page] (filter bars, image
  /// placeholders).
  static const surface = Color(0xFFF4ECDD);

  /// Body/heading text, borders, and structural dark hero panels (screen
  /// headers, dark cards) — same navy as [primary] (see class doc).
  static const ink = primary;

  /// Secondary text, placeholders.
  static const muted = Color(0xFF75777C);

  /// Lighter still — the faintest hint text.
  static const faint = Color(0xFF9AA0A6);

  /// Borders/dividers — a touch more defined than before, for a bit more
  /// structural clarity on cards/inputs.
  static const divider = Color(0xFFDDD5C4);

  /// Pending/inactive step markers (order tracking).
  static const pending = Color(0xFFBDBDBD);

  static const slot = Color(0xFFF4ECDD);
  static const slotAlt = Color(0xFFEFE6D3);

  /// Warm ivory — the app's replacement for plain white. Named `white`
  /// still so call sites (bottom nav, cards, sheets, …) don't need to
  /// change, but the value itself is `#FFFBF2`, not pure white.
  static const white = Color(0xFFFFFBF2);
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
        bg: Color(0xFFFFFBF2).withValues(alpha: 0.7),
        fg: BasketColors.ink,
      );
