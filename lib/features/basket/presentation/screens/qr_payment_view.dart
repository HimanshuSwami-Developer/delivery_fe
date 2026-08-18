import 'dart:typed_data';

import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows a UPI QR (a plain `upi://pay` deep link, built client-side — no
/// backend call needed to display it) for the cart's payable total, then
/// lets the customer attach a screenshot of the completed payment. Tapping
/// "Place order" is what actually places it — [BasketCubit.placeQrOrder]
/// uploads the screenshot as proof and leaves `payment_status` pending for
/// an admin to verify by hand; there's no gateway callback to trust here.
class QrPaymentView extends StatefulWidget {
  const QrPaymentView({super.key});

  @override
  State<QrPaymentView> createState() => _QrPaymentViewState();
}

class _QrPaymentViewState extends State<QrPaymentView> {
  // TODO: replace with the real merchant UPI VPA before going live — until
  // then the QR renders but isn't payable.
  static const String _merchantVpa = '9718751020@ptyes';
  static const String _merchantName = 'Aapno Bazar';

  Uint8List? _screenshotBytes;
  String? _screenshotFilename;

  Future<void> _pickScreenshot() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _screenshotBytes = bytes;
      _screenshotFilename = file.name;
    });
  }

  Future<void> _placeOrder(BasketCubit cubit) async {
    final bytes = _screenshotBytes;
    if (bytes == null) return;
    await cubit.placeQrOrder(bytes, _screenshotFilename ?? 'screenshot.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final payable = context.select((BasketCubit c) => cartTotals(c.state).payable);
    final upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': _merchantVpa,
        'pn': _merchantName,
        'am': payable.toString(),
        'cu': 'INR',
        'tn': 'Aapno Bazar order',
      },
    ).toString();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(26))),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scan & pay', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Paying ${moneyLabel(payable)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: QrImageView(data: upiUri, size: 220, gapless: false),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Scan this code with any UPI app to pay ${moneyLabel(payable)}, then upload a screenshot of the successful payment below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.68),
                    border: Border.all(color: _screenshotBytes == null ? BasketColors.divider : BasketColors.ink, width: 1.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      if (_screenshotBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(_screenshotBytes!, width: 44, height: 44, fit: BoxFit.cover),
                        )
                      else
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: BasketColors.surface, borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.upload_outlined, color: BasketColors.muted, size: 20),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _screenshotBytes == null ? 'Upload payment screenshot' : 'Screenshot attached — tap to change',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: BasketColors.ink.withValues(alpha: 0.07))),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BasketColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _screenshotBytes == null ? null : () => _placeOrder(cubit),
                child: Text("I've paid — place order", style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
