import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OtpView extends StatelessWidget {
  const OtpView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final authError = context.select((BasketCubit c) => c.state.authError);
    final authLoading = context.select((BasketCubit c) => c.state.authLoading);
    final phoneLabel = phone.isEmpty ? '98765 43210' : phone;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, size: 18, color: BasketColors.ink),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Verify your number',
                style: GoogleFonts.poppins(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '6-digit code sent to +91 $phoneLabel · ',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: BasketColors.muted),
                  ),
                  GestureDetector(
                    onTap: cubit.back,
                    child: Text(
                      'Change',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              TextField(
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: cubit.setOtp,
                style: GoogleFonts.poppins(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 8, color: BasketColors.ink),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '——————',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.6),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: BasketColors.ink.withValues(alpha: 0.12), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: BasketColors.ink.withValues(alpha: 0.12), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: BasketColors.primary, width: 1.8),
                  ),
                ),
              ),
              if (authError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  decoration: BoxDecoration(
                    color: BasketColors.ink.withValues(alpha: 0.05),
                    border: Border.all(color: BasketColors.ink.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authError,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Didn't get it?", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.faint)),
                  GestureDetector(
                    onTap: authLoading ? null : cubit.resendOtp,
                    child: Text('Resend code', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BasketColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: authLoading ? null : cubit.verifyOtp,
                  child: authLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text('Verify & continue', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
