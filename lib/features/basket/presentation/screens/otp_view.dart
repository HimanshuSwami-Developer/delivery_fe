import 'dart:async';

import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _otpLength = 4;
const _resendWaitSeconds = 30;

/// Matches the Claude Design "Aapno Bazar — Login with OTP" mockup: a navy
/// header, per-digit boxes (this app's real OTP length, with
/// auto-advance/backspace-back focus), a resend countdown, and a verify
/// button whose color/label track fill state. "Get a call instead" is
/// shown for visual fidelity but wired inert (`onTap: null`) — there's no
/// callback-OTP flow behind it, matching how this codebase already marks
/// not-yet-built affordances (e.g. the PDP's share button) rather than
/// faking one.
class OtpView extends StatefulWidget {
  const OtpView({super.key});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  final _controllers = List.generate(_otpLength, (_) => TextEditingController());
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());
  int _focused = -1;
  int _secs = _resendWaitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final seeded = context.read<BasketCubit>().state.otp;
    for (var i = 0; i < seeded.length && i < _otpLength; i++) {
      _controllers[i].text = seeded[i];
    }
    for (var i = 0; i < _otpLength; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) setState(() => _focused = i);
      });
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secs <= 1) {
        setState(() => _secs = 0);
        _timer?.cancel();
      } else {
        setState(() => _secs -= 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _joined => _controllers.map((c) => c.text).join();

  void _onDigit(BasketCubit cubit, int i, String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    _controllers[i].text = d.isEmpty ? '' : d.substring(d.length - 1);
    cubit.setOtp(_joined);
    if (d.isNotEmpty && i + 1 < _otpLength) {
      _focusNodes[i + 1].requestFocus();
    }
    setState(() {});
  }

  KeyEventResult _onKey(BasketCubit cubit, int i, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && _controllers[i].text.isEmpty && i > 0) {
      _controllers[i - 1].clear();
      cubit.setOtp(_joined);
      _focusNodes[i - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _resend(BasketCubit cubit) async {
    if (_secs > 0 || cubit.state.authLoading) return;
    await cubit.resendOtp();
    if (!mounted || cubit.state.authError != null) return;
    for (final c in _controllers) {
      c.clear();
    }
    cubit.setOtp('');
    _focusNodes.first.requestFocus();
    setState(() => _secs = _resendWaitSeconds);
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final authError = context.select((BasketCubit c) => c.state.authError);
    final authLoading = context.select((BasketCubit c) => c.state.authLoading);
    final phoneLabel = phone.isEmpty ? '98765 43210' : phone;
    final full = _joined.length == _otpLength;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(34)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, topInset + 14, 24, 26),
                decoration: const BoxDecoration(
                  gradient: RadialGradient(center: Alignment(-0.5, -1), radius: 1.4, colors: [AapnoBazar.navyGlow, AapnoBazar.navy], stops: [0, 0.72]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: cubit.back,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify your number',
                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.84),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.62)),
                        children: [
                          const TextSpan(text: 'We sent a 4-digit code to '),
                          TextSpan(
                            text: '+91 $phoneLabel',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AapnoBazar.gold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // No overlap with the header in the mockup — the card sits a
            // clean 32px below the header's rounded-bottom swoop (`top:268`
            // vs. the header's own `height:236`), unlike the login screen's
            // overlapping-card treatment elsewhere in this app.
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                for (var i = 0; i < _otpLength; i++) ...[
                                  if (i > 0) const SizedBox(width: 12),
                                  Expanded(child: _OtpBox(
                                    controller: _controllers[i],
                                    focusNode: _focusNodes[i],
                                    focused: _focused == i,
                                    onChanged: (v) => _onDigit(cubit, i, v),
                                    onKey: (e) => _onKey(cubit, i, e),
                                  )),
                                ],
                              ],
                            ),
                            const SizedBox(height: 22),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _secs > 0 ? 'Resend available in 0:${_secs.toString().padLeft(2, '0')}' : 'Didn’t get the code?',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: AapnoBazar.textFaint),
                                ),
                                GestureDetector(
                                  onTap: () => _resend(cubit),
                                  child: Text(
                                    'Resend code',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: _secs > 0 ? AapnoBazar.textDisabled : AapnoBazar.navy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (authError != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                                decoration: BoxDecoration(color: AapnoBazar.navy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                                child: Text(authError, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AapnoBazar.navy)),
                              ),
                            ],
                            const SizedBox(height: 22),
                            GestureDetector(
                              onTap: (full && !authLoading) ? cubit.verifyOtp : null,
                              child: Container(
                                height: 58,
                                decoration: BoxDecoration(
                                  color: full ? AapnoBazar.navy : AapnoBazar.heroPanelBg,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: full
                                      ? [BoxShadow(color: AapnoBazar.navy.withValues(alpha: 0.7), blurRadius: 28, spreadRadius: -12, offset: const Offset(0, 14))]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: authLoading
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                                    : Text(
                                        full ? 'Verify & continue' : 'Enter 4-digit code',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: full ? Colors.white : AapnoBazar.textDisabled),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                'By continuing you agree to Aapno Bazar’s Terms and Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, height: 1.6, fontWeight: FontWeight.w500, color: AapnoBazar.textSubtle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Outside the card, pinned near the bottom — matches the
                  // mockup's `margin-top:auto` placement (not part of the
                  // bordered/padded card the OTP cells and buttons live in).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 24),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: AapnoBazar.inputFill, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.support_agent_rounded, size: 18, color: AapnoBazar.navy),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.5, fontWeight: FontWeight.w500, color: AapnoBazar.textFaint),
                              children: [
                                const TextSpan(text: 'Trouble receiving the code? '),
                                TextSpan(text: 'Get a call instead', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AapnoBazar.navy)),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(KeyEvent) onKey;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.isNotEmpty;
    final borderColor = focused ? AapnoBazar.navy : (filled ? AapnoBazar.borderFilled : AapnoBazar.inputFill);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 74,
      decoration: BoxDecoration(
        color: AapnoBazar.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: focused ? [BoxShadow(color: AapnoBazar.navy.withValues(alpha: 0.1), blurRadius: 0, spreadRadius: 4)] : null,
      ),
      alignment: Alignment.center,
      child: Focus(
        onKeyEvent: (node, event) => onKey(event),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          maxLength: 1,
          textAlign: TextAlign.center,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: AapnoBazar.navy),
          cursorColor: AapnoBazar.navy,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
