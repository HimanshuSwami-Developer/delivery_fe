import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Transient "processing payment" screen. Has no back button and no user
/// actions — [BasketCubit.payNow]/[BasketCubit.simulatePaymentFailure]/
/// [BasketCubit.payCashOnDelivery] land here and time out to success or
/// failure on their own.
class PayingView extends StatefulWidget {
  const PayingView({super.key});

  @override
  State<PayingView> createState() => _PayingViewState();
}

class _PayingViewState extends State<PayingView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final payable = context.select((BasketCubit c) => cartTotals(c.state).payable);
    final methodName = context.select((BasketCubit c) => BasketCatalog.paymentMethodById(c.state.paymentMethodId).name);

    return Container(
      color: BasketColors.ink,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Opacity(
                      opacity: _dotOpacity(i),
                      child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Processing ${moneyLabel(payable)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 230),
            child: Text(
              "Do not close the app. We're confirming with $methodName.",
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  double _dotOpacity(int index) {
    final phase = (_pulse.value + index * 0.16) % 1.0;
    final t = (phase < 0.5 ? phase : 1 - phase) * 2;
    return 0.35 + 0.65 * t;
  }
}
