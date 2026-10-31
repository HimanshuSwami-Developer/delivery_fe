import 'dart:typed_data';

import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// Shows the merchant's static UPI QR code for the cart's payable total,
/// then lets the customer attach a screenshot of the completed payment.
/// Tapping "Place order" is what actually places it —
/// [BasketCubit.placeQrOrder] uploads the screenshot as proof and leaves
/// `payment_status` pending for an admin to verify by hand; there's no
/// gateway callback to trust here.
class QrPaymentView extends StatefulWidget {
  const QrPaymentView({super.key});

  @override
  State<QrPaymentView> createState() => _QrPaymentViewState();
}

class _QrPaymentViewState extends State<QrPaymentView> {
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

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.md),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl))),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: BasketSpace.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scan & pay', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: 2),
                  Text('Paying ${moneyLabel(payable)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.lg, BasketSpace.gutter, BasketSpace.lg),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(BasketSpace.lg),
                  decoration: basketCard(radius: BasketRadius.lg),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(BasketRadius.sm),
                    child: Image.asset('assets/scanner.jpeg', width: 220, height: 220, fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: BasketSpace.md),
              Text(
                'Scan this code with any UPI app to pay ${moneyLabel(payable)}, then upload a screenshot of the successful payment below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
              ),
              const SizedBox(height: BasketSpace.lg),
              GestureDetector(
                onTap: _pickScreenshot,
                child: Container(
                  padding: const EdgeInsets.all(BasketSpace.sm),
                  decoration: basketCard(selected: _screenshotBytes != null),
                  child: Row(
                    children: [
                      if (_screenshotBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(BasketRadius.sm),
                          child: Image.memory(_screenshotBytes!, width: 44, height: 44, fit: BoxFit.cover),
                        )
                      else
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: BasketColors.surface, borderRadius: BorderRadius.circular(BasketRadius.sm)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.upload_outlined, color: BasketColors.muted, size: 20),
                        ),
                      const SizedBox(width: BasketSpace.sm),
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
        BasketBottomBar(
          child: BasketButton(
            label: "I've paid — place order",
            onPressed: _screenshotBytes == null ? null : () => _placeOrder(cubit),
          ),
        ),
      ],
    );
  }
}
