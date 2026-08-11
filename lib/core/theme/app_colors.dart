import 'package:flutter/material.dart';

/// Color tokens for the "Aapno Bazar" white + navy design system
/// (matching `stitch_instazepto_grocery_mart`'s "Modern Navy" reference,
/// brand-navy `#1A237E`). White/near-white surfaces, navy as the one
/// accent, and a few extra semantic shades for status/feedback.
class AppColors {
  AppColors._();

  static const surface = Color(0xFFFAF9FC);
  static const surfaceDim = Color(0xFFDAD9DD);
  static const surfaceBright = Color(0xFFFAF9FC);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F3F7);
  static const surfaceContainer = Color(0xFFEEEDF1);
  static const surfaceContainerHigh = Color(0xFFE9E8EB);
  static const surfaceContainerHighest = Color(0xFFE3E2E6);
  static const onSurface = Color(0xFF1A1C1E);
  static const onSurfaceVariant = Color(0xFF444748);
  static const inverseSurface = Color(0xFF2F3033);
  static const inverseOnSurface = Color(0xFFF1F0F4);
  static const outline = Color(0xFF747878);
  static const outlineVariant = Color(0xFFC4C7C8);
  static const primary = Color(0xFF1A237E);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1A237E);
  static const onPrimaryContainer = Color(0xFFFFFFFF);
  static const inversePrimary = Color(0xFF959EFD);
  static const secondary = Color(0xFF4C56AF);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE0E0FF);
  static const onSecondaryContainer = Color(0xFF27308A);
  static const tertiary = Color(0xFF00796B);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFFE0F2F1);
  static const onTertiaryContainer = Color(0xFF003D29);
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const primaryFixed = Color(0xFFE0E0FF);
  static const primaryFixedDim = Color(0xFF959EFD);
  static const onPrimaryFixed = Color(0xFF000767);
  static const onPrimaryFixedVariant = Color(0xFF343D96);
  static const secondaryFixed = Color(0xFFE0E0FF);
  static const secondaryFixedDim = Color(0xFFBDC2FF);
  static const onSecondaryFixed = Color(0xFF000767);
  static const onSecondaryFixedVariant = Color(0xFF343D96);
  static const tertiaryFixed = Color(0xFFE0F2F1);
  static const tertiaryFixedDim = Color(0xFF4DB6AC);
  static const onTertiaryFixed = Color(0xFF00201B);
  static const onTertiaryFixedVariant = Color(0xFF003D29);
  static const background = Color(0xFFFAF9FC);
  static const onBackground = Color(0xFF1A1C1E);
  static const surfaceVariant = Color(0xFFE3E2E6);

  // ── Extra semantic shades — "multiple colors for different things" ────
  static const success = Color(0xFF108910);
  static const successSoft = Color(0xFFE8F5E9);
  static const warning = Color(0xFFF57C00);
  static const warningSoft = Color(0xFFFFF3E0);
  static const info = Color(0xFF2196F3);
  static const infoSoft = Color(0xFFE3F2FD);
}
