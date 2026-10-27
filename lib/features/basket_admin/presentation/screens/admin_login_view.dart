import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Split-screen sign-in: a dark brand panel with headline copy and 3 live
/// stats on the left, a two-step mobile number + master-OTP sign-in form
/// on the right, against `/api/auth/master-login/` (no SMS involved — see
/// `MasterOTPLoginView`). Only accounts with `role='admin'` get past
/// `verifyOtp` — see `BasketAdminCubit`.
class AdminLoginView extends StatelessWidget {
  const AdminLoginView({super.key});

  @override
  Widget build(BuildContext context) {
    // Below this the wide split-row would squeeze the brand panel into a
    // column too narrow for its headline/stats to lay out in one line —
    // stack instead of shrinking that content indefinitely.
    final isNarrow = MediaQuery.sizeOf(context).width < 900;
    final brandPanel = _BrandPanel(compact: isNarrow);
    final formPanel = const _SignInPanel();

    return ColoredBox(
      color: Color(0xFFFFFBF2),
      child: SafeArea(
        child: isNarrow
            ? SingleChildScrollView(
                child: Column(children: [brandPanel, formPanel]),
              )
            : Row(
                children: [
                  Expanded(flex: 115, child: brandPanel),
                  Expanded(flex: 100, child: Center(child: formPanel)),
                ],
              ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AdminColors.ink,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Compact (narrow, stacked-column) layout sizes to its content —
        // `Spacer` needs a bounded height, which this panel no longer has
        // once it's not pinned to a fixed SizedBox inside a scroll view.
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Text('Aapno Bazar', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Color(0xFFFFFBF2), borderRadius: BorderRadius.circular(99)),
                child: Text('ADMIN', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: AdminColors.ink, letterSpacing: 1.6)),
              ),
            ],
          ),
          SizedBox(height: compact ? 24 : 0),
          if (!compact) const Spacer(),
          Text(
            'Every store,\nevery order,\none console.',
            style: GoogleFonts.manrope(fontSize: compact ? 30 : 44, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFFFFFBF2), letterSpacing: -1.2),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'Live inventory, order routing, delivery partners, GST-ready reporting.',
              style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w500, height: 1.6, color: Color(0xFFFFFBF2).withValues(alpha: 0.5)),
            ),
          ),
          const SizedBox(height: 32),
          const Wrap(
            spacing: 34,
            runSpacing: 18,
            children: [
              _BrandStat(value: '24×7', label: 'Fast delivery'),
              _BrandStat(value: '5,142', label: 'SKUs'),
              _BrandStat(value: '98.2%', label: 'On-time'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrandStat extends StatelessWidget {
  const _BrandStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
        const SizedBox(height: 5),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2).withValues(alpha: 0.45), letterSpacing: 0.6),
        ),
      ],
    );
  }
}

class _SignInPanel extends StatefulWidget {
  const _SignInPanel();

  @override
  State<_SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends State<_SignInPanel> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final otpSent = context.select((BasketAdminCubit c) => c.state.otpSent);
    final loading = context.select((BasketAdminCubit c) => c.state.authLoading);
    final error = context.select((BasketAdminCubit c) => c.state.authError);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sign in', style: GoogleFonts.manrope(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AdminColors.ink)),
            const SizedBox(height: 8),
            Text(
              otpSent ? 'Enter your admin access code' : 'Use your Basket operations mobile number',
              style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
            ),
            const SizedBox(height: 28),
            if (!otpSent)
              _AdminTextField(
                label: 'Work mobile number',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                hint: 'Enter mobile number (+91XXXXXXXXXX)',
                enabled: !loading,
                onChanged: cubit.setMobileNumber,
                onSubmitted: (_) => cubit.sendOtp(),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AdminTextField(
                    label: 'Access code',
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    hint: 'Enter OTP (6 digits)',
                    enabled: !loading,
                    onChanged: cubit.setOtpCode,
                    onSubmitted: (_) => cubit.verifyOtp(),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: loading ? null : cubit.editMobileNumber,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Change number', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                  ),
                ],
              ),
            if (error != null) ...[
              const SizedBox(height: 14),
              Text(error, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: loading ? null : (otpSent ? cubit.verifyOtp : cubit.sendOtp),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                ),
                child: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFFFBF2))),
                      )
                    : Text(
                        otpSent ? 'Verify & sign in' : 'Continue',
                        style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Access is scoped by role — only accounts marked as admin get past the code.',
              style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.6, color: AdminColors.faint),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTextField extends StatelessWidget {
  const _AdminTextField({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    this.keyboardType,
    this.hint,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final TextInputType? keyboardType;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AdminColors.ink.withValues(alpha: 0.12)), borderRadius: BorderRadius.circular(13)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AdminColors.faint, letterSpacing: 0.6),
            ),
          ),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            autofocus: true,
            style: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w700, color: AdminColors.ink),
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              hintText: hint,
              hintStyle: GoogleFonts.manrope(fontSize: 14.5, fontWeight: FontWeight.w700, color: AdminColors.faint),
            ),
          ),
        ],
      ),
    );
  }
}
