import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared "LABEL above a value" bordered card — the one input shape reused
/// across every form in the app (profile setup, address entry). Two
/// flavours: [LabeledTextField] for anything the user can actually type
/// into, [LabeledStaticField] for values shown but not editable here
/// (no backing field, or edited elsewhere). Previously each screen had its
/// own near-identical private `_FieldCard`/`_NameFieldCard` widget; this
/// replaces all of them.
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.faint, letterSpacing: 0.6),
            ),
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: textCapitalization,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            textAlign: textAlign,
            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: hintText,
              hintStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: BasketColors.faint),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same card shape as [LabeledTextField], but for a value that's shown,
/// not typed into here (e.g. "Email — Optional" with no backing field, or
/// "Receiver" mirroring the phone number from account setup).
class LabeledStaticField extends StatelessWidget {
  const LabeledStaticField({super.key, required this.label, required this.value, this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.faint, letterSpacing: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: muted ? FontWeight.w600 : FontWeight.w700,
              color: muted ? BasketColors.faint : BasketColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
