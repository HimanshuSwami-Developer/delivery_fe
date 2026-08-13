import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';

/// Design tokens and small style helpers for the Basket Admin console,
/// ported from `Basket Admin.dc.html`. [card]/[muted]/[faint] are reused
/// from [BasketColors] (identical neutrals in both). [ink] is its own
/// constant, not [BasketColors.ink] — the customer app's `ink` was
/// repointed to the "Aapno Bazar" brand navy for the splash/onboarding/
/// login/OTP reskin, but that reskin is scoped to the customer app only for
/// now, so the admin console keeps its original near-black ink here.
class AdminColors {
  AdminColors._();

  /// Page backdrop behind the console card (`#DEDEE2`, radial-gradiented in
  /// the source; approximated with a flat fill here).
  static const backdrop = Color(0xFFDEDEE2);

  static const ink = Color(0xFF20222C);
  static const card = BasketColors.page;
  static const muted = BasketColors.muted;
  static const faint = BasketColors.faint;
}

/// Border/background/foreground for the pill-shaped filter buttons (status
/// tabs, category tabs, chart ranges, GST month/slab pickers). Matches the
/// source design's `pill(on)` helper — the admin console's unselected pill
/// is solid white rather than the customer app's translucent white, so this
/// is a distinct helper from `basket`'s `pillStyle`.
class AdminPillStyle {
  const AdminPillStyle({required this.border, required this.bg, required this.fg});
  final Color border;
  final Color bg;
  final Color fg;
}

AdminPillStyle adminPillStyle(bool selected) => selected
    ? const AdminPillStyle(border: AdminColors.ink, bg: AdminColors.ink, fg: Colors.white)
    : AdminPillStyle(border: AdminColors.ink.withValues(alpha: 0.14), bg: Colors.white, fg: AdminColors.ink);

/// Background/foreground/border for the small status/state chips (order
/// status, product stock state, customer tier, partner status, category &
/// banner live/paused). Matches the source design's `chip(kind)` helper —
/// the three buckets are shared by every kind of chip in the console.
class AdminChipStyle {
  const AdminChipStyle({required this.bg, required this.fg, required this.border});
  final Color bg;
  final Color fg;
  final Color border;
}

const _darkChipKinds = {'New', 'Out for delivery', 'On trip', 'Platinum', 'Live'};
const _ghostChipKinds = {'Cancelled', 'Off duty', 'Paused', 'Out of stock'};

AdminChipStyle adminChipStyle(String kind) {
  if (_darkChipKinds.contains(kind)) {
    return const AdminChipStyle(bg: AdminColors.ink, fg: Colors.white, border: AdminColors.ink);
  }
  if (_ghostChipKinds.contains(kind)) {
    return AdminChipStyle(bg: Colors.transparent, fg: AdminColors.faint, border: AdminColors.ink.withValues(alpha: 0.16));
  }
  return AdminChipStyle(bg: AdminColors.ink.withValues(alpha: 0.06), fg: AdminColors.ink, border: AdminColors.ink.withValues(alpha: 0.12));
}

/// The translucent "glass" card look used for most panels in the console
/// (`rgba(255,255,255,.72)` + faint border + soft shadow) — a bit lighter
/// than the customer app's `glassCard()` (`.68` opacity, smaller radius),
/// matching the admin design's slightly airier cards.
BoxDecoration adminGlassCard({double radius = 18}) {
  return BoxDecoration(
    color: Colors.white.withValues(alpha: 0.72),
    border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(color: AdminColors.ink.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 10)),
    ],
  );
}

/// The solid dark ink panel used for a few emphasized cards (low-stock
/// alerts, notification composer, delivery-partner panel).
BoxDecoration adminDarkCard({double radius = 18}) {
  return BoxDecoration(color: AdminColors.ink, borderRadius: BorderRadius.circular(radius));
}
