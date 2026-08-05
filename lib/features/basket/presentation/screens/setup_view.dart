import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
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
                style: GoogleFonts.manrope(fontSize: 26, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'So we can personalise your basket',
                style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w500, color: BasketColors.muted),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: BasketColors.ink.withValues(alpha: 0.08)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const ImageSlot(shape: ImageSlotShape.circle, mini: true),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add a photo', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('Optional', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _NameFieldCard(controller: _nameController, onChanged: cubit.setName),
              const SizedBox(height: 12),
              _FieldCard(label: 'Email', value: 'Optional', muted: true),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFERRAL CODE',
                      style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.faint, letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('RAVI250', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(99)),
                          child: Text(
                            '₹250 unlocked',
                            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (authError != null) ...[
                const SizedBox(height: 12),
                Text(authError, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: BasketColors.ink,
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
                      : Text('Start shopping', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameFieldCard extends StatelessWidget {
  const _NameFieldCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Text(
              'FULL NAME',
              style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.faint, letterSpacing: 0.6),
            ),
          ),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: 'Aarav Sharma',
              hintStyle: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: BasketColors.faint),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.label, required this.value, this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(color: BasketColors.ink.withValues(alpha: 0.09)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w600, color: BasketColors.faint, letterSpacing: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: muted ? FontWeight.w600 : FontWeight.w700,
              color: muted ? BasketColors.faint : BasketColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
