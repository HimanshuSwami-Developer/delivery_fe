import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/labeled_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Profile-setup screen, shown once after a brand-new number verifies its
/// first OTP — the name entered here becomes the account's profile name
/// via `POST /api/auth/profile/`.
class SetupView extends StatefulWidget {
  const SetupView({super.key});

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final authLoading = context.select((BasketCubit c) => c.state.authLoading);
    final authError = context.select((BasketCubit c) => c.state.authError);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about you',
                style: GoogleFonts.plusJakartaSans(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: BasketColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'So we can personalise your basket',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: BasketColors.muted),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: BasketColors.primarySoft,
                          border: Border.all(color: BasketColors.primary.withValues(alpha: 0.3), width: 1.6),
                        ),
                        alignment: Alignment.center,
                        child: Icon(Icons.person_rounded, size: 34, color: BasketColors.primary.withValues(alpha: 0.6)),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: BasketColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add a photo', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                      const SizedBox(height: 3),
                      Text('Optional', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 26),
              LabeledTextField(
                label: 'Full name',
                controller: _nameController,
                onChanged: cubit.setName,
                textCapitalization: TextCapitalization.words,
                hintText: 'Aarav Sharma',
              ),
              const SizedBox(height: 12),
              LabeledTextField(
                label: 'Email',
                controller: _emailController,
                onChanged: cubit.setEmail,
                keyboardType: TextInputType.emailAddress,
                hintText: 'aarav@email.com (optional)',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BasketColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Icon(Icons.card_giftcard_rounded, size: 18, color: BasketColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HAVE A REFERRAL CODE?',
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: BasketColors.primary, letterSpacing: 0.6),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _referralController,
                            onChanged: cubit.setReferralCodeInput,
                            textCapitalization: TextCapitalization.characters,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: BasketColors.ink),
                            decoration: InputDecoration(
                              isDense: true,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: 'e.g. RAVI250 (optional)',
                              hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: BasketColors.faint),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (authError != null) ...[
                const SizedBox(height: 12),
                Text(authError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.error)),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BasketColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: authLoading ? null : cubit.finishSetup,
                  child: authLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text('Start shopping', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
