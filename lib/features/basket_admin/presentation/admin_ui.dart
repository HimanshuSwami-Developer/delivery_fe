import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The admin console's component standard — same rules as the customer
/// app's `basket_ui.dart` (crisp white cards with a 1px hairline instead of
/// shadows, one radius scale, fixed-height buttons, outlined inputs, a
/// 4-pt spacing scale), tuned for a desktop/web console: denser button
/// heights and the console's own near-black [AdminColors.ink] + Manrope.
/// Screens should build from these instead of hand-rolling
/// `Container`+`InkWell` buttons or one-off radii.

/// 4-pt spacing scale.
abstract final class AdminSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Gap between cards/sections on a page.
  static const double section = 16;

  /// Inner padding of a standard card.
  static const double card = 20;
}

/// Corner radius scale — chips/icon buttons [sm], cards/buttons/inputs
/// [md], modals [lg], fully round [pill].
abstract final class AdminRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Surfaces/borders for the admin standard.
abstract final class AdminSurface {
  /// Card, input and modal fill — true white so it lifts off the ivory
  /// backdrop by contrast alone.
  static const card = Color(0xFFFFFFFF);

  /// Hairline around cards and table blocks.
  static const border = Color(0xFFE6E1D6);

  /// Idle input / secondary-button border — a touch more defined.
  static const borderStrong = Color(0xFFD3CCBC);

  /// Zebra/hover/subtle fills inside cards (table header, tonal button).
  static const subtle = Color(0xFFF6F3EC);

  static const disabledBg = Color(0xFFE8E4DB);
  static const disabledFg = Color(0xFF9C988F);

  static const error = Color(0xFFB42318);
  static const success = Color(0xFF16A34A);
}

/// The standard admin card: white, 1px hairline, 12px corners, no shadow.
/// [selected] swaps the hairline for a 1.5px ink ring. [elevated] adds one
/// soft shadow — only for floating things (modals, popovers, dropdowns).
BoxDecoration adminCard({
  double radius = AdminRadius.md,
  Color color = AdminSurface.card,
  bool selected = false,
  bool border = true,
  bool elevated = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: selected
        ? Border.all(color: AdminColors.ink, width: 1.5)
        : border
            ? Border.all(color: AdminSurface.border)
            : null,
    boxShadow: elevated
        ? [BoxShadow(color: AdminColors.ink.withValues(alpha: 0.14), blurRadius: 32, offset: const Offset(0, 12))]
        : null,
  );
}

enum AdminButtonVariant {
  /// Ink fill — the one main action in a card/page/modal.
  primary,

  /// White fill, ink text, hairline border — Cancel, Export, secondary actions.
  secondary,

  /// Subtle fill, ink text — low-emphasis actions inside tables/cards.
  tonal,

  /// Text only — "View all", inline links.
  text,

  /// Red text + red hairline — delete, cancel order, revoke.
  danger,
}

enum AdminButtonSize {
  /// 44px — modal footers and page-level primary actions.
  large,

  /// 38px — toolbar/card-header actions (Export, Add product…).
  medium,

  /// 32px — inside table rows and compact cards.
  small,
}

/// The one admin button: fixed heights per [size], 12px corners (8px when
/// small), Manrope 700, built-in [loading] spinner and a real disabled
/// state when [onPressed] is null. [expand] stretches it to the width.
class AdminButton extends StatelessWidget {
  const AdminButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AdminButtonVariant.primary,
    this.size = AdminButtonSize.medium,
    this.icon,
    this.expand = false,
    this.loading = false,
  });

  const AdminButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = AdminButtonSize.medium,
    this.icon,
    this.expand = false,
    this.loading = false,
  }) : variant = AdminButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final AdminButtonVariant variant;
  final AdminButtonSize size;
  final IconData? icon;
  final bool expand;
  final bool loading;

  double get _height => switch (size) {
        AdminButtonSize.large => 44,
        AdminButtonSize.medium => 38,
        AdminButtonSize.small => 32,
      };

  double get _fontSize => switch (size) {
        AdminButtonSize.large => 14,
        AdminButtonSize.medium => 13,
        AdminButtonSize.small => 12,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    const ivory = Color(0xFFFFFBF2);
    final (bg, fg, side) = switch (variant) {
      AdminButtonVariant.primary => (AdminColors.ink, ivory, BorderSide.none),
      AdminButtonVariant.secondary => (AdminSurface.card, AdminColors.ink, const BorderSide(color: AdminSurface.borderStrong)),
      AdminButtonVariant.tonal => (AdminSurface.subtle, AdminColors.ink, BorderSide.none),
      AdminButtonVariant.text => (Colors.transparent, AdminColors.ink, BorderSide.none),
      AdminButtonVariant.danger => (AdminSurface.card, AdminSurface.error, BorderSide(color: AdminSurface.error.withValues(alpha: 0.45))),
    };
    final filled = variant == AdminButtonVariant.primary;
    final radius = size == AdminButtonSize.small ? AdminRadius.sm : AdminRadius.md;

    final child = loading
        ? SizedBox.square(
            dimension: _fontSize + 3,
            child: CircularProgressIndicator(strokeWidth: 2, color: filled ? ivory : AdminColors.ink),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: _fontSize + 3), const SizedBox(width: 6)],
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          );

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, _height)),
        fixedSize: WidgetStatePropertyAll(Size.fromHeight(_height)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: size == AdminButtonSize.small ? 12 : 16)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
        side: WidgetStateProperty.resolveWith((s) {
          if (side == BorderSide.none) return null;
          return s.contains(WidgetState.disabled) && !loading ? side.copyWith(color: AdminSurface.border) : side;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled) && !loading && filled) return AdminSurface.disabledBg;
          return bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled) && !loading) return AdminSurface.disabledFg;
          return fg;
        }),
        overlayColor: WidgetStatePropertyAll((filled ? ivory : AdminColors.ink).withValues(alpha: 0.08)),
        textStyle: WidgetStatePropertyAll(GoogleFonts.manrope(fontSize: _fontSize, fontWeight: FontWeight.w700)),
        elevation: const WidgetStatePropertyAll(0),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Standard outlined admin input: white fill, 1px border, 12px corners, ink
/// 1.5px ring on focus, red on error (~44px tall single-line).
InputDecoration adminInputDecoration({
  String? hintText,
  String? errorText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? prefixText,
  bool enabled = true,
}) {
  OutlineInputBorder outline(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(AdminRadius.md), borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    prefixText: prefixText,
    prefixStyle: adminInputText().copyWith(color: AdminColors.muted),
    isDense: true,
    filled: true,
    fillColor: enabled ? AdminSurface.card : AdminSurface.subtle,
    hintStyle: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w500, color: AdminColors.faint),
    errorStyle: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminSurface.error),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    prefixIconColor: AdminColors.muted,
    suffixIconColor: AdminColors.muted,
    border: outline(AdminSurface.borderStrong),
    enabledBorder: outline(AdminSurface.borderStrong),
    focusedBorder: outline(AdminColors.ink, 1.5),
    errorBorder: outline(AdminSurface.error),
    focusedErrorBorder: outline(AdminSurface.error, 1.5),
    disabledBorder: outline(AdminSurface.border),
  );
}

/// What the admin types into an [adminInputDecoration] field.
TextStyle adminInputText() => GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w600, color: AdminColors.ink);

/// Small label above an input ("Product name", "MRP (₹)").
class AdminFieldLabel extends StatelessWidget {
  const AdminFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpace.xs),
      child: Text(text, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.muted)),
    );
  }
}

/// Theme overrides scoped to the admin console so stock Material widgets
/// (TextField, buttons, dialogs, snackbars, dropdown menus) follow the
/// standard even where a screen hasn't been moved to the components above.
ThemeData adminTheme(ThemeData base) {
  final input = adminInputDecoration();
  final text = GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md));
  const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  return base.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: input.fillColor,
      isDense: true,
      hintStyle: input.hintStyle,
      errorStyle: input.errorStyle,
      contentPadding: input.contentPadding,
      border: input.border,
      enabledBorder: input.enabledBorder,
      focusedBorder: input.focusedBorder,
      errorBorder: input.errorBorder,
      focusedErrorBorder: input.focusedErrorBorder,
      disabledBorder: input.disabledBorder,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: AdminColors.ink),
    // `minimumSize: Size.zero` (not the app-wide `Size.fromHeight(56)`,
    // whose infinite width throws inside a Row).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        backgroundColor: AdminColors.ink,
        foregroundColor: const Color(0xFFFFFBF2),
        padding: padding,
        shape: shape,
        textStyle: text,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        foregroundColor: AdminColors.ink,
        backgroundColor: AdminSurface.card,
        side: const BorderSide(color: AdminSurface.borderStrong),
        padding: padding,
        shape: shape,
        textStyle: text,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size.zero,
        elevation: 0,
        backgroundColor: AdminColors.ink,
        foregroundColor: const Color(0xFFFFFBF2),
        padding: padding,
        shape: shape,
        textStyle: text,
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AdminColors.ink, shape: shape, textStyle: text)),
    dividerTheme: const DividerThemeData(color: AdminSurface.border, thickness: 1, space: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: AdminSurface.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.lg)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AdminSurface.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md), side: const BorderSide(color: AdminSurface.border)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AdminColors.ink,
      contentTextStyle: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFFFBF2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRadius.md)),
    ),
  );
}
