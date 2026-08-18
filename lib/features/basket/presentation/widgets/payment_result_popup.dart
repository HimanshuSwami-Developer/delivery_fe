import 'package:fastswipe/features/basket/cubit/basket_state.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The one guaranteed popup every order/payment attempt ends with — see
/// [PaymentPopup]. A plain [AlertDialog] rather than a custom sheet so it
/// reliably shows on top of whatever screen [BasketCubit] has already
/// navigated to.
Future<void> showPaymentResultPopup(BuildContext context, PaymentPopup popup) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(popup.success ? Icons.check : Icons.priority_high, color: Colors.white, size: 26),
      ),
      title: Text(
        popup.title,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      ),
      content: Text(
        popup.message,
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: BasketColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}
