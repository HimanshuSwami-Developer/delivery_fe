import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// The basket app's component standard — one spacing scale, one radius
/// scale, one card, one button, one input — modelled on quick-commerce
/// apps (Blinkit/Zepto): crisp white cards with a 1px hairline border
/// instead of floaty shadows, 12px corners, 48–52px tap-height buttons,
/// outlined inputs that turn navy on focus. Screens should build from
/// these rather than hand-rolling `Container`+`GestureDetector` buttons
/// or one-off radii, so the whole app moves together when this changes.
///
/// Brand colors still come from [BasketColors] (navy primary, gold
/// highlight) — this file only fixes *shape*, *spacing* and *borders*.

/// 4-pt spacing scale. [gutter] is the page's horizontal padding.
abstract final class BasketSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Left/right page padding on every screen.
  static const double gutter = 16;

  /// Vertical gap between stacked cards/sections.
  static const double section = 12;
}

/// Corner radius scale — chips/tags [sm], cards/buttons/inputs [md],
/// sheets/hero panels [lg], fully round [pill].
abstract final class BasketRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;

  static const BorderRadius card = BorderRadius.all(Radius.circular(md));
  static const BorderRadius button = BorderRadius.all(Radius.circular(md));
  static const BorderRadius input = BorderRadius.all(Radius.circular(md));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(xl));
}

/// Surfaces/borders for the component standard.
abstract final class BasketSurface {
  /// Card and input fill — true white, so cards lift off the ivory page
  /// by contrast alone (no shadow needed).
  static const card = Color(0xFFFFFFFF);

  /// The 1px hairline around cards, inputs and secondary buttons.
  static const border = Color(0xFFE9E2D3);

  /// Inside-card dividers and idle input borders that need a touch more
  /// definition than [border].
  static const borderStrong = Color(0xFFD9D0BE);

  /// Disabled button fill / text.
  static const disabledBg = Color(0xFFE6E1D6);
  static const disabledFg = Color(0xFF9A978F);
}

/// The standard card: white, 1px hairline, 12px corners, no shadow.
/// [selected] swaps the hairline for a 1.5px navy ring (radio-style
/// pickers: address, slot, payment). [elevated] adds a single soft
/// shadow — only for things that float (sticky bars, popovers).
BoxDecoration basketCard({
  double radius = BasketRadius.md,
  Color color = BasketSurface.card,
  bool selected = false,
  bool border = true,
  bool elevated = false,
}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: selected
        ? Border.all(color: BasketColors.primary, width: 1.5)
        : border
            ? Border.all(color: BasketSurface.border)
            : null,
    boxShadow: elevated
        ? [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))]
        : null,
  );
}

/// Section heading used above groups of cards ("Bill details",
/// "Delivery address", …).
class BasketSectionTitle extends StatelessWidget {
  const BasketSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BasketSpace.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: BasketColors.ink)),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

enum BasketButtonVariant {
  /// Navy fill — the one main action on a screen/bar.
  primary,

  /// White fill, navy text, hairline border — the alternative action.
  secondary,

  /// Soft ivory fill, navy text — low-emphasis actions inside cards.
  tonal,

  /// Text only — "Skip", "Change", "View all".
  text,

  /// Red text + red hairline — cancel order, delete address, log out.
  danger,
}

enum BasketButtonSize {
  /// 52px — sticky bottom CTAs (Proceed to pay, Place order, Send OTP).
  large,

  /// 44px — in-page actions.
  medium,

  /// 34px — inside cards and list rows.
  small,
}

/// The one button. Fixed heights per [size], 12px corners (8px when
/// small), consistent typography, a built-in [loading] spinner and a real
/// disabled state when [onPressed] is null. [expand] stretches it to the
/// available width (the usual case for bottom CTAs).
class BasketButton extends StatelessWidget {
  const BasketButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BasketButtonVariant.primary,
    this.size = BasketButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.loading = false,
  });

  const BasketButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BasketButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.expand = true,
    this.loading = false,
  }) : variant = BasketButtonVariant.secondary;

  const BasketButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = BasketButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.loading = false,
  }) : variant = BasketButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final BasketButtonVariant variant;
  final BasketButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final bool loading;

  double get _height => switch (size) {
        BasketButtonSize.large => 52,
        BasketButtonSize.medium => 44,
        BasketButtonSize.small => 34,
      };

  double get _fontSize => switch (size) {
        BasketButtonSize.large => 16,
        BasketButtonSize.medium => 14.5,
        BasketButtonSize.small => 13,
      };

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, side) = switch (variant) {
      BasketButtonVariant.primary => (BasketColors.primary, BasketColors.onPrimary, BorderSide.none),
      BasketButtonVariant.secondary => (BasketSurface.card, BasketColors.primary, const BorderSide(color: BasketSurface.borderStrong)),
      BasketButtonVariant.tonal => (BasketColors.primarySoft, BasketColors.primary, BorderSide.none),
      BasketButtonVariant.text => (Colors.transparent, BasketColors.primary, BorderSide.none),
      BasketButtonVariant.danger => (BasketSurface.card, BasketColors.error, BorderSide(color: BasketColors.error.withValues(alpha: 0.5))),
    };
    final filled = variant == BasketButtonVariant.primary;
    final radius = size == BasketButtonSize.small ? BasketRadius.sm : BasketRadius.md;

    final child = loading
        ? SizedBox.square(
            dimension: _fontSize + 4,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: filled ? BasketColors.onPrimary : BasketColors.primary),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: _fontSize + 3), const SizedBox(width: BasketSpace.xs)],
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (trailingIcon != null) ...[const SizedBox(width: BasketSpace.xs), Icon(trailingIcon, size: _fontSize + 3)],
            ],
          );

    final button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, _height)),
        fixedSize: WidgetStatePropertyAll(Size.fromHeight(_height)),
        padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: size == BasketButtonSize.small ? 12 : 20)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
        side: WidgetStateProperty.resolveWith((s) {
          if (side == BorderSide.none) return null;
          return s.contains(WidgetState.disabled) && !loading ? side.copyWith(color: BasketSurface.border) : side;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled) && !loading && filled) return BasketSurface.disabledBg;
          return bg;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.disabled) && !loading) return BasketSurface.disabledFg;
          return fg;
        }),
        overlayColor: WidgetStatePropertyAll((filled ? BasketColors.onPrimary : BasketColors.primary).withValues(alpha: 0.08)),
        textStyle: WidgetStatePropertyAll(GoogleFonts.plusJakartaSans(fontSize: _fontSize, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
        elevation: const WidgetStatePropertyAll(0),
      ),
      child: child,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// A screen's sticky bottom action area — white, top hairline, safe-area
/// aware, standard padding. Put a [BasketButton] (or a Row of them) in it.
class BasketBottomBar extends StatelessWidget {
  const BasketBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BasketSurface.card,
        border: const Border(top: BorderSide(color: BasketSurface.border)),
        boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.sm, BasketSpace.gutter, BasketSpace.sm),
          child: child,
        ),
      ),
    );
  }
}

/// Standard outlined input: white fill, 1px border, 12px corners, navy
/// 1.5px ring on focus, red on error, 16/14 content padding (~50px tall).
InputDecoration basketInputDecoration({
  String? hintText,
  String? labelText,
  String? errorText,
  Widget? prefixIcon,
  Widget? prefix,
  Widget? suffixIcon,
  String? counterText = '',
  bool dense = false,
}) {
  OutlineInputBorder outline(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BasketRadius.input, borderSide: BorderSide(color: c, width: w));
  final textStyle = GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: BasketColors.faint);
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    errorText: errorText,
    prefixIcon: prefixIcon,
    prefix: prefix,
    suffixIcon: suffixIcon,
    counterText: counterText,
    isDense: true,
    filled: true,
    fillColor: BasketSurface.card,
    hintStyle: textStyle,
    labelStyle: textStyle,
    floatingLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: BasketColors.primary),
    errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.error),
    contentPadding: EdgeInsets.symmetric(horizontal: BasketSpace.md, vertical: dense ? 11 : 15),
    prefixIconColor: BasketColors.muted,
    suffixIconColor: BasketColors.muted,
    border: outline(BasketSurface.borderStrong),
    enabledBorder: outline(BasketSurface.borderStrong),
    focusedBorder: outline(BasketColors.primary, 1.5),
    errorBorder: outline(BasketColors.error),
    focusedErrorBorder: outline(BasketColors.error, 1.5),
    disabledBorder: outline(BasketSurface.border),
  );
}

/// Text style for what the user types into a [basketInputDecoration] field.
TextStyle basketInputText() => GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: BasketColors.ink);

/// Small grey label shown above an input ("Full name", "House / flat no.").
class BasketFieldLabel extends StatelessWidget {
  const BasketFieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BasketSpace.xs),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (optional)
              TextSpan(text: '  (optional)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: BasketColors.faint)),
          ],
        ),
        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: BasketColors.muted),
      ),
    );
  }
}

/// Label-above + standard input in one — the usual form row.
class BasketTextField extends StatelessWidget {
  const BasketTextField({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.prefixIcon,
    this.prefix,
    this.suffixIcon,
    this.errorText,
    this.optional = false,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final TextAlign textAlign;
  final Widget? prefixIcon;
  final Widget? prefix;
  final Widget? suffixIcon;
  final String? errorText;
  final bool optional;
  final bool autofocus;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) BasketFieldLabel(label!, optional: optional),
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          textAlign: textAlign,
          autofocus: autofocus,
          enabled: enabled,
          cursorColor: BasketColors.primary,
          style: basketInputText(),
          decoration: basketInputDecoration(
            hintText: hintText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            prefix: prefix,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// Theme overrides scoped to the basket app so any stock Material widget
/// (TextField, buttons, chips, dialogs, sheets) lands on the same standard
/// even where a screen hasn't been moved to the components above.
ThemeData basketTheme(ThemeData base) {
  final input = basketInputDecoration();
  final buttonText = GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700);
  const shape = RoundedRectangleBorder(borderRadius: BasketRadius.button);
  return base.copyWith(
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: input.fillColor,
      isDense: true,
      hintStyle: input.hintStyle,
      labelStyle: input.labelStyle,
      floatingLabelStyle: input.floatingLabelStyle,
      errorStyle: input.errorStyle,
      contentPadding: input.contentPadding,
      border: input.border,
      enabledBorder: input.enabledBorder,
      focusedBorder: input.focusedBorder,
      errorBorder: input.errorBorder,
      focusedErrorBorder: input.focusedErrorBorder,
      disabledBorder: input.disabledBorder,
    ),
    textSelectionTheme: const TextSelectionThemeData(cursorColor: BasketColors.primary),
    // `minimumSize: Size.zero` (not the app-wide `Size.fromHeight(56)`):
    // that has an infinite width and throws inside a Row. Height comes
    // from padding instead — 14 vertical ≈ 48px with 15px text.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: Size.zero,
        backgroundColor: BasketColors.primary,
        foregroundColor: BasketColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: Size.zero,
        elevation: 0,
        backgroundColor: BasketColors.primary,
        foregroundColor: BasketColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: Size.zero,
        foregroundColor: BasketColors.primary,
        backgroundColor: BasketSurface.card,
        side: const BorderSide(color: BasketSurface.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BasketColors.primary,
        shape: shape,
        textStyle: buttonText,
      ),
    ),
    cardTheme: const CardThemeData(
      color: BasketSurface.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BasketRadius.card, side: BorderSide(color: BasketSurface.border)),
    ),
    dividerTheme: const DividerThemeData(color: BasketSurface.border, thickness: 1, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: BasketColors.page,
      shape: RoundedRectangleBorder(borderRadius: BasketRadius.sheet),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: BasketSurface.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BasketRadius.lg)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: BasketColors.ink,
      contentTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: BasketColors.onPrimary),
      shape: const RoundedRectangleBorder(borderRadius: BasketRadius.button),
    ),
  );
}
