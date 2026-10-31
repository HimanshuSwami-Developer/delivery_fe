import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Form row used across profile setup and address entry: a small label
/// above a standard outlined input ([BasketTextField]). Kept as its own
/// name so existing call sites don't change.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return BasketTextField(
      label: label,
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textAlign: textAlign,
    );
  }
}

/// Same row shape as [LabeledTextField] for a value that's shown, not
/// typed into here (e.g. "Receiver" mirroring the account phone number):
/// label above, then a read-only box with the input's size and border.
class LabeledStaticField extends StatelessWidget {
  const LabeledStaticField({super.key, required this.label, required this.value, this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        BasketFieldLabel(label),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: BasketSpace.md, vertical: 15),
          decoration: BoxDecoration(
            color: BasketColors.primarySoft.withValues(alpha: 0.6),
            borderRadius: BasketRadius.input,
            border: Border.all(color: BasketSurface.border),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: muted ? BasketColors.faint : BasketColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
