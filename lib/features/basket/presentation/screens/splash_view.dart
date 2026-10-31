import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches the Claude Design "Aapno Bazar — Splash" mockup: navy
/// radial-gradient backdrop, the [BazarMark] logo on a pulsing gold glow,
/// the Hindi wordmark, and a sweeping progress bar (the mockup's fake
/// status bar / home-indicator device chrome is real on an actual phone,
/// so it isn't reproduced here).
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  // The mockup's `ab-pulse` keyframes already go 1→1.18→1 (and .35→.12→.35)
  // *within* a single 3.4s iteration, so this must be a one-directional
  // `repeat()` — `repeat(reverse: true)` would replay that shape forward
  // then backward, doubling the real period to 6.8s.
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _glow.dispose();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AapnoBazar.navy,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.82),
              radius: 1.15,
              colors: [AapnoBazar.navyGlow, AapnoBazar.navy],
              stops: [0, 0.62],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                top: -90,
                left: -70,
                child: _RingDecoration(diameter: 300, opacity: 0.1),
              ),
              const Positioned(
                bottom: -140,
                right: -110,
                child: _RingDecoration(diameter: 380, opacity: 0.08),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glow,
                          builder: (context, _) {
                            final wave = _glow.value < 0.5
                                ? _glow.value * 2
                                : (1 - _glow.value) * 2;
                            final t = Curves.easeInOut.transform(wave);
                            return Transform.scale(
                              scale: 1 + 0.18 * t,
                              child: Opacity(
                                opacity: 0.35 - 0.23 * t,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    color: AapnoBazar.gold,
                                    borderRadius: BorderRadius.circular(140),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: -12,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: ClipOval(
                            child: Image.asset(
                              'assets/splash_screen_bg.png',
                              width: 240,
                              height: 240,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Aapno Bazar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFFBF2),
                      letterSpacing: -1.2,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'अपनो बाज़ार',
                      style: GoogleFonts.tiroDevanagariHindi(
                        fontSize: 19,
                        color: AapnoBazar.gold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'FRESH · DAILY · YOURS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFFBF2).withValues(alpha: 0.55),
                        letterSpacing: 2.86,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 46,
                child: Column(
                  children: [
                    ClipRect(
                      child: SizedBox(
                        width: 150,
                        height: 3,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFFFFFBF2,
                                  ).withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _sweep,
                              builder: (context, _) {
                                // Mirrors the mockup's `translateX(-60%)
                                // -> translateX(260%)` on a bar 40% of
                                // the track's width (60px of 150px): the
                                // percentages are relative to the bar's
                                // own width, i.e. -36px to +156px.
                                final dx =
                                    -36 +
                                    192 *
                                        Curves.easeInOut.transform(
                                          _sweep.value,
                                        );
                                return Transform.translate(
                                  offset: Offset(dx, 0),
                                  child: Container(
                                    width: 60,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Color(0xFFFFFBF2),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Groceries in ${BasketCubit.etaMinutes} minutes',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFFBF2).withValues(alpha: 0.45),
                        letterSpacing: 0.48,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingDecoration extends StatelessWidget {
  const _RingDecoration({required this.diameter, required this.opacity});

  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: opacity)),
      ),
    );
  }
}
