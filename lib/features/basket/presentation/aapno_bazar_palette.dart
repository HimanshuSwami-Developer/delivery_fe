import 'package:flutter/material.dart';

/// Brand palette for the splash/onboarding/OTP-verify flow — ported 1:1
/// from the Claude Design "Aapno Bazar — Splash, Onboarding, OTP Login"
/// mockup (navy & white, gold accent), with the white family since swapped
/// for a warm ivory so the palette reads as navy + gold + ivory rather
/// than navy-on-white. Scoped to just those three screens rather than
/// folded into [BasketColors]: the rest of the app (home, cart, PDP, admin
/// console, …) keeps its existing green/indigo palette, which the mockup
/// doesn't touch.
class AapnoBazar {
  AapnoBazar._();

  static const navy = Color(0xFF0A1F3C);
  static const navyGlow = Color(0xFF173C6E);
  static const gold = Color(0xFFF3B14A);

  static const textMuted = Color(0xFF607089);
  static const textFaint = Color(0xFF8494AC);
  static const textFainter = Color(0xFF6C7C95);
  static const textDisabled = Color(0xFFA6B2C5);
  static const textSubtle = Color(0xFF94A0B4);

  static const heroPanelBg = Color(0xFFF6EFE0);
  static const inputFill = Color(0xFFF8F1E4);
  static const borderIdle = Color(0xFFE8DFCC);
  static const borderSoft = Color(0xFFEAE1CE);
  static const borderFilled = Color(0xFFD0C2A3);
  static const dotIdle = Color(0xFFDCD2BC);
}
