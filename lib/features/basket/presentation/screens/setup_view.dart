import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
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
      backgroundColor: Color(0xFFFFFBF2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(BasketSpace.xl, BasketSpace.xs, BasketSpace.xl, BasketSpace.xl),
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
                    const SizedBox(height: BasketSpace.xl),
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
                                  border: Border.all(color: Color(0xFFFFFBF2), width: 2.5),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.camera_alt_rounded, size: 13, color: Color(0xFFFFFBF2)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: BasketSpace.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a photo',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: BasketColors.ink),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Optional',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.faint),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: BasketSpace.xl),
                    LabeledTextField(
                      label: 'Full name',
                      controller: _nameController,
                      onChanged: cubit.setName,
                      textCapitalization: TextCapitalization.words,
                      hintText: 'Enter your full name (First and last name)',
                    ),
                    const SizedBox(height: BasketSpace.md),
                    LabeledTextField(
                      label: 'Email (optional)',
                      controller: _emailController,
                      onChanged: cubit.setEmail,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Enter your email (example@gmail.com)',
                    ),
                    const SizedBox(height: BasketSpace.md),
                    Container(
                      padding: const EdgeInsets.all(BasketSpace.md),
                      decoration: BoxDecoration(color: BasketColors.primarySoft, borderRadius: BorderRadius.circular(BasketRadius.md)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(color: Color(0xFFFFFBF2), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Icon(Icons.card_giftcard_rounded, size: 18, color: BasketColors.primary),
                          ),
                          const SizedBox(width: BasketSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HAVE A REFERRAL CODE?',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: BasketColors.primary, letterSpacing: 0.6),
                                ),
                                const SizedBox(height: BasketSpace.xs),
                                TextField(
                                  controller: _referralController,
                                  onChanged: cubit.setReferralCodeInput,
                                  textCapitalization: TextCapitalization.characters,
                                  cursorColor: BasketColors.primary,
                                  style: basketInputText(),
                                  decoration: basketInputDecoration(hintText: 'Enter referral code (e.g. ABC123)', dense: true),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (authError != null) ...[
                      const SizedBox(height: BasketSpace.sm),
                      Text(
                        authError,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.error),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            BasketBottomBar(
              child: BasketButton(label: 'Start shopping', onPressed: cubit.finishSetup, loading: authLoading),
            ),
          ],
        ),
      ),
    );
  }
}
