import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:fastswipe/features/basket/presentation/widgets/bazar_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Not part of the Claude Design mockup (which only covers splash,
/// onboarding, and the OTP-verify screen) — this phone-number entry step
/// sits between onboarding and [OtpView] in the real flow, so it's reskinned
/// to match that same navy/gold "Aapno Bazar" language (palette, Plus
/// Jakarta Sans, header shape, button/shadow treatment) rather than left in
/// the app's old indigo theme.
class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final authLoading = context.select((BasketCubit c) => c.state.authLoading);
    final authError = context.select((BasketCubit c) => c.state.authError);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Color(0xFFFFFBF2),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 30),
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
                          decoration: BoxDecoration(color: Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: const BazarMark(size: 19),
                        ),
                        const SizedBox(width: 10),
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
                    const SizedBox(height: 10),
                    Text(
                      'Log in with your mobile number',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.62)),
                    ),
                  ],
                ),
              ),
            ),
            // Clean gap below the header, no overlap — matches the
            // OTP-verify screen's card placement (see `OtpView`).
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                        decoration: BoxDecoration(color: Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(26)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mobile number', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AapnoBazar.textFaint)),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: AapnoBazar.inputFill,
                                border: Border.all(color: AapnoBazar.borderIdle, width: 1.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Text('+91', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: AapnoBazar.navy)),
                                  Container(height: 20, width: 1.4, margin: const EdgeInsets.symmetric(horizontal: 10), color: AapnoBazar.borderFilled),
                                  Expanded(
                                    child: TextField(
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: cubit.setPhone,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: AapnoBazar.navy),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        counterText: '',
                                        filled: false,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        hintText: 'Enter mobile number (10 digits)',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (authError != null) ...[
                              const SizedBox(height: 10),
                              Text(authError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AapnoBazar.navy)),
                            ],
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: authLoading ? null : cubit.sendOtp,
                              child: Container(
                                height: 58,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AapnoBazar.navy,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: AapnoBazar.navy.withValues(alpha: 0.7), blurRadius: 28, spreadRadius: -12, offset: const Offset(0, 14))],
                                ),
                                alignment: Alignment.center,
                                child: authLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFFFBF2))))
                                    : Text('Send OTP', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'By continuing you agree to our Terms of Use and Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: AapnoBazar.textSubtle),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
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
