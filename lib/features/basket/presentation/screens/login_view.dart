import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/bazar_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Not part of the Claude Design mockup (which only covers splash,
/// onboarding, and the OTP-verify screen) — this phone-number entry step
/// sits between onboarding and [OtpView] in the real flow, so it's reskinned
/// to match that same navy/gold "Aapno Bazar" language (palette, Plus
/// Jakarta Sans, header shape) rather than left in the app's old indigo
/// theme. The form itself follows the shared [BasketButton] /
/// outlined-input standard (Blinkit-style): one 52px phone field with a
/// fixed "+91" prefix, then a full-width large CTA.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final authLoading = context.select((BasketCubit c) => c.state.authLoading);
    final authError = context.select((BasketCubit c) => c.state.authError);
    final phoneComplete = context.select((BasketCubit c) => c.state.phone.length == 10);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Color(0xFFFFFBF2),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(BasketSpace.xl, topInset + BasketSpace.lg, BasketSpace.xl, BasketSpace.xxl),
                decoration: const BoxDecoration(
                  gradient: RadialGradient(center: Alignment(-0.5, -1), radius: 1.4, colors: [AapnoBazar.navyGlow, AapnoBazar.navy], stops: [0, 0.72]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(BasketRadius.md)),
                          alignment: Alignment.center,
                          child: const BazarMark(size: 19),
                        ),
                        const SizedBox(width: BasketSpace.xs),
                        Text('Aapno Bazar', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 29, height: 1.2, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2), letterSpacing: -0.87),
                        children: [
                          const TextSpan(text: 'Order groceries\nin '),
                          TextSpan(text: '${BasketCubit.etaMinutes} minutes', style: const TextStyle(color: AapnoBazar.gold)),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: BasketSpace.xs),
                    Text(
                      'Log in with your mobile number',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.62)),
                    ),
                  ],
                ),
              ),
            ),
            // Clean gap below the header, no overlap — matches the
            // OTP-verify screen's form placement (see `OtpView`).
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(BasketSpace.xl, BasketSpace.xxl, BasketSpace.xl, BasketSpace.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BasketFieldLabel('Mobile number'),
                          TextField(
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            onChanged: cubit.setPhone,
                            cursorColor: AapnoBazar.navy,
                            style: basketInputText().copyWith(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.7),
                            decoration: basketInputDecoration(
                              hintText: 'Enter mobile number (10 digits)',
                              // Fixed "+91" country code, split from the
                              // digits by a thin divider.
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: BasketSpace.md, right: BasketSpace.sm),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('+91', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AapnoBazar.navy)),
                                    const SizedBox(width: BasketSpace.sm),
                                    Container(height: 20, width: 1, color: BasketSurface.borderStrong),
                                  ],
                                ),
                              ),
                            ).copyWith(
                              constraints: const BoxConstraints(minHeight: 52),
                              contentPadding: const EdgeInsets.symmetric(horizontal: BasketSpace.md, vertical: BasketSpace.sm),
                            ),
                          ),
                          if (authError != null) ...[
                            const SizedBox(height: BasketSpace.xs),
                            Text(authError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AapnoBazar.navy)),
                          ],
                          const SizedBox(height: BasketSpace.lg),
                          BasketButton(
                            label: 'Send OTP',
                            // Disabled until a full 10-digit number is in.
                            onPressed: phoneComplete ? cubit.sendOtp : null,
                            loading: authLoading,
                          ),
                          const SizedBox(height: BasketSpace.md),
                          SizedBox(
                            width: double.infinity,
                            child: Text(
                              'By continuing you agree to our Terms of Use and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: AapnoBazar.textSubtle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: BasketSpace.xl),
                    child: Text(
                      'Trouble logging in? Get help',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AapnoBazar.textFaint),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
