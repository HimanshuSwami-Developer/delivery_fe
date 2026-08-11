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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 24, 24, 0),
              height: 300 + MediaQuery.paddingOf(context).top - 32,
              color: BasketColors.ink,
              child: Stack(
                children: [
                  Positioned(
                    top: -60,
                    right: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: BasketColors.primary.withValues(alpha: 0.16)),
                    ),
                  ),
                  Positioned(
                    bottom: -40,
                    left: -50,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: BasketColors.primary.withValues(alpha: 0.12)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(color: BasketColors.primary, borderRadius: BorderRadius.circular(9)),
                            alignment: Alignment.center,
                            child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 9),
                          Text('basket', style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 44),
                      Text(
                        'Order groceries\nin ${BasketCubit.etaMinutes} minutes.',
                        style: GoogleFonts.poppins(fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.9),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Log in with your mobile number',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ],
              ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(color: BasketColors.ink.withValues(alpha: 0.14), blurRadius: 40, offset: const Offset(0, 16)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Mobile number', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: BasketColors.muted)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: BasketColors.page,
                              border: Border.all(color: BasketColors.divider, width: 1.4),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Row(
                              children: [
                                Text('+91', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                                Container(
                                  height: 20,
                                  width: 1.4,
                                  margin: const EdgeInsets.symmetric(horizontal: 10),
                                  color: BasketColors.divider,
                                ),
                                Expanded(
                                  child: TextField(
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    onChanged: cubit.setPhone,
                                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 0.7, color: BasketColors.ink),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      counterText: '',
                                      // Unset `filled` inherits the app-wide
                                      // theme's near-white fill, painting an
                                      // extra box behind this already-boxed
                                      // field — force it off.
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
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
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.error),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: BasketColors.primary,
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
                                  : Text('Send OTP', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'By continuing you agree to our Terms of Use and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 11, height: 1.5, fontWeight: FontWeight.w500, color: BasketColors.faint),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Trouble logging in? Get help',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: BasketColors.faint),
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
