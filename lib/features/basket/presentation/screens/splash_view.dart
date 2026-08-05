import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BasketColors.ink,
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  'b',
                  style: GoogleFonts.manrope(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'basket',
                style: GoogleFonts.manrope(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1),
              ),
              const SizedBox(height: 18),
              Text(
                'GROCERIES IN MINUTES',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 1.68,
                  height: 1,
                ),
              ),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Opacity(
                          opacity: _dotOpacity(i),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
          Positioned(
            bottom: 34,
            child: TextButton(
              onPressed: context.read<BasketCubit>().skipSplash,
              child: Text(
                'tap to continue',
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.45)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _dotOpacity(int index) {
    final phase = (_pulse.value + index * 0.18) % 1.0;
    final t = (phase < 0.5 ? phase : 1 - phase) * 2;
    return 0.35 + 0.65 * t;
  }
}
