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
      backgroundColor: BasketColors.primary,
      // `SizedBox.expand` forces a tight full-screen constraint on the
      // Stack below — without it, Scaffold.body's loose constraints let
      // the Stack shrink-wrap to its content, so `alignment: center` only
      // centers within that tiny box instead of the actual screen.
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft decorative depth — a plain green fill reads flat at
            // full-bleed size, so a few oversized translucent circles
            // (clipped to the screen) give it some dimension without
            // needing any image assets.
            Positioned(
              top: -90,
              right: -70,
              child: _GlowCircle(diameter: 260, opacity: 0.10),
            ),
            Positioned(
              bottom: -120,
              left: -90,
              child: _GlowCircle(diameter: 320, opacity: 0.08),
            ),
            Positioned(
              bottom: 140,
              right: -40,
              child: _GlowCircle(diameter: 140, opacity: 0.07),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, 14)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shopping_basket_rounded, color: BasketColors.primary, size: 42),
                ),
                const SizedBox(height: 22),
                Text(
                  'Aapno Bazar',
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.6, height: 1),
                ),
                const SizedBox(height: 10),
                Text(
                  'GROCERIES IN MINUTES',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.72),
                    letterSpacing: 2.2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 36),
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 7),
                          Opacity(
                            opacity: _dotOpacity(i),
                            child: Container(
                              width: 7,
                              height: 7,
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
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.55)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _dotOpacity(int index) {
    final phase = (_pulse.value + index * 0.18) % 1.0;
    final t = (phase < 0.5 ? phase : 1 - phase) * 2;
    return 0.4 + 0.6 * t;
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.diameter, required this.opacity});

  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: opacity)),
    );
  }
}
