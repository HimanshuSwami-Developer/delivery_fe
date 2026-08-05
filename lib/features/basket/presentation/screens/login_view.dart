import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final authLoading = context.select((BasketCubit c) => c.state.authLoading);
    final authError = context.select((BasketCubit c) => c.state.authError);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 24, 24, 0),
            height: 300 + MediaQuery.paddingOf(context).top - 32,
            decoration: const BoxDecoration(
              color: BasketColors.ink,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('basket', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 44),
                Text(
                  'Order groceries\nin ${BasketCubit.etaMinutes} minutes.',
                  style: GoogleFonts.manrope(fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.9),
                ),
                const SizedBox(height: 10),
                Text(
                  'Log in with your mobile number',
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: BasketColors.ink.withValues(alpha: 0.18), blurRadius: 40, offset: const Offset(0, 16)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mobile number', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.muted)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.only(bottom: 10),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: BasketColors.ink, width: 1.5)),
                            ),
                            child: Row(
                              children: [
                                Text('+91', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: cubit.setPhone,
                                    style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.7),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      counterText: '',
                                      border: InputBorder.none,
                                      hintText: '98765 43210',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (authError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              authError,
                              style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B)),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: BasketColors.ink,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: authLoading ? null : cubit.sendOtp,
                              child: authLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                    )
                                  : Text('Send OTP', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By continuing you agree to our Terms of Use and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(fontSize: 11, height: 1.5, fontWeight: FontWeight.w500, color: BasketColors.faint),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: Divider(color: BasketColors.ink.withValues(alpha: 0.1), height: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: BasketColors.faint)),
                      ),
                      Expanded(child: Divider(color: BasketColors.ink.withValues(alpha: 0.1), height: 1)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: BasketColors.ink, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: cubit.continueAsGuest,
                      child: Text('Continue as guest', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Trouble logging in? Get help',
                    style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: BasketColors.faint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
