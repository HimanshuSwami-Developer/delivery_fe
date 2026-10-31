import 'dart:math' as math;

import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_state.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:fastswipe/features/basket/presentation/widgets/bazar_mark.dart';
import 'package:fastswipe/features/basket/presentation/widgets/onboarding_illustrations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _ivory = Color(0xFFFFFBF2);

/// Matches the Claude Design "Aapno Bazar onboarding" canvas, recoloured
/// into the app's navy + gold + ivory palette: logo + Skip on top, a
/// swipeable page per slide (animated illustration, title, body) on a
/// per-slide tinted background, and dots + a progress-ring Next button
/// that turn into "Get started" / "I already have an account" on the last
/// slide. [BasketState.onboardSlide] stays the source of truth — swiping
/// writes it, dots/Next read it back into the [PageView].
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  late final PageController _pages = PageController(initialPage: context.read<BasketCubit>().state.onboardSlide);

  /// Set while a dot/Next tap is animating the pager, so the pages it
  /// sweeps past on the way don't each get written back to the cubit and
  /// interrupt the animation.
  bool _driving = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _showSlide(int index) async {
    if (!_pages.hasClients || (_pages.page?.round() ?? index) == index) return;
    _driving = true;
    await _pages.animateToPage(index, duration: const Duration(milliseconds: 480), curve: Curves.easeOutCubic);
    _driving = false;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final index = context.select((BasketCubit c) => c.state.onboardSlide);
    final slides = BasketCatalog.onboarding;
    final last = index == slides.length - 1;

    return BlocListener<BasketCubit, BasketState>(
      listenWhen: (a, b) => a.onboardSlide != b.onboardSlide,
      listener: (_, state) => _showSlide(state.onboardSlide),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        color: slides[index].tint,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      children: [
                        const BazarMark(size: 32),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aapno Bazar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: AapnoBazar.navy),
                          ),
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: last ? 0 : 1,
                          child: IgnorePointer(
                            ignoring: last,
                            child: TextButton(
                              onPressed: cubit.skipOnboarding,
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(horizontal: 18),
                                backgroundColor: _ivory.withValues(alpha: 0.75),
                                shape: const StadiumBorder(),
                              ),
                              child: Text('Skip', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AapnoBazar.navy)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: slides.length,
                    onPageChanged: (i) {
                      if (!_driving) cubit.setOnboardSlide(i);
                    },
                    itemBuilder: (_, i) => _OnboardPage(index: i, slide: slides[i], active: i == index),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(sizeFactor: anim, alignment: Alignment.bottomCenter, child: child),
                    ),
                    child: last
                        ? Column(
                            key: const ValueKey('last'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(child: _Dots(count: slides.length, index: index, onPick: cubit.setOnboardSlide)),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: cubit.nextOnboardSlide,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AapnoBazar.navy,
                                  foregroundColor: _ivory,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Get started', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextButton(
                                onPressed: cubit.skipOnboarding,
                                style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                                child: Text(
                                  'I already have an account',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AapnoBazar.navy),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            key: const ValueKey('step'),
                            height: 80,
                            child: Row(
                              children: [
                                _Dots(count: slides.length, index: index, onPick: cubit.setOnboardSlide),
                                const Spacer(),
                                _NextRing(progress: (index + 1) / slides.length, onTap: cubit.nextOnboardSlide),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One slide: illustration on top, title + body rising in below it. Owns
/// the clocks the illustration painters run on, and only ticks while
/// [active] so off-screen neighbours in the [PageView] cost nothing.
class _OnboardPage extends StatefulWidget {
  const _OnboardPage({required this.index, required this.slide, required this.active});

  final int index;
  final OnboardSlide slide;
  final bool active;

  @override
  State<_OnboardPage> createState() => _OnboardPageState();
}

class _OnboardPageState extends State<_OnboardPage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _time = ValueNotifier<double>(0);
  final _intro = ValueNotifier<double>(0);
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync(restart: false);
  }

  @override
  void didUpdateWidget(covariant _OnboardPage old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync(restart: true);
  }

  /// Starts the clocks fresh when the slide becomes active (so the
  /// entrance replays every visit), stops them when it leaves.
  void _sync({required bool restart}) {
    if (_reduceMotion) {
      _ticker.stop();
      _time.value = 0;
      _intro.value = onboardIntroSeconds;
      return;
    }
    if (widget.active) {
      if (restart || !_ticker.isActive) {
        _ticker.stop();
        _time.value = 0;
        _intro.value = 0;
        _ticker.start();
      }
    } else {
      _ticker.stop();
    }
  }

  void _tick(Duration elapsed) {
    final s = elapsed.inMicroseconds / 1e6;
    _time.value = s;
    _intro.value = math.min(s, onboardIntroSeconds);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _intro.dispose();
    super.dispose();
  }

  CustomPainter get _painter => switch (widget.index) {
        0 => ScooterClockPainter(time: _time, intro: _intro),
        1 => ProduceBasketPainter(time: _time, intro: _intro),
        2 => CouponDealsPainter(time: _time, intro: _intro, background: widget.slide.tint),
        _ => LiveMapPainter(time: _time, intro: _intro),
      };

  @override
  Widget build(BuildContext context) {
    final semantics = const [
      'Delivery scooter racing past a ticking clock',
      'Fresh produce dropping into a basket',
      'Discount coupon with a swinging price tag and coins',
      'Map showing a delivery moving from the store to your home',
    ][widget.index];
    // The basket slide animates its own parts in; the rest pop in whole.
    final popWhole = widget.index != 1;
    final isMap = widget.index == 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final side = math.max(0.0, math.min(320.0, math.min(box.maxWidth, box.maxHeight)));
              Widget art = Semantics(
                label: semantics,
                image: true,
                child: CustomPaint(size: Size.square(side), painter: _painter),
              );
              if (popWhole) {
                art = ValueListenableBuilder<double>(
                  valueListenable: _intro,
                  child: art,
                  builder: (_, t, child) {
                    final p = const Cubic(0.3, 1.5, 0.5, 1).transform((t / 0.7).clamp(0.0, 1.0));
                    return Opacity(
                      opacity: (t / 0.35).clamp(0.0, 1.0),
                      child: Transform.scale(scale: 0.6 + 0.4 * p, child: child),
                    );
                  },
                );
              }
              return Center(child: art);
            }),
          ),
          if (isMap) ...[
            const SizedBox(height: 8),
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _Rise(intro: _intro, delay: 0.1, child: const _PayChip(icon: Icons.qr_code_2_rounded, label: 'UPI')),
                  _Rise(intro: _intro, delay: 0.2, child: const _PayChip(icon: Icons.payments_outlined, label: 'Cash on delivery')),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          _Rise(
            intro: _intro,
            delay: 0.2,
            child: Text(
              widget.slide.title,
              style: GoogleFonts.plusJakartaSans(fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AapnoBazar.navy),
            ),
          ),
          const SizedBox(height: 12),
          _Rise(
            intro: _intro,
            delay: 0.3,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                widget.slide.body,
                style: GoogleFonts.plusJakartaSans(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500, color: AapnoBazar.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Fades [child] in while sliding it up 18px, [delay]s into the entrance.
class _Rise extends StatelessWidget {
  const _Rise({required this.intro, required this.delay, required this.child});

  final ValueNotifier<double> intro;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: intro,
      child: child,
      builder: (_, t, child) {
        final p = Curves.easeOutCubic.transform(((t - delay) / 0.6).clamp(0.0, 1.0));
        return Opacity(
          opacity: p,
          child: Transform.translate(offset: Offset(0, 18 * (1 - p)), child: child),
        );
      },
    );
  }
}

class _PayChip extends StatelessWidget {
  const _PayChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: _ivory, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AapnoBazar.navy),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AapnoBazar.navy)),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index, required this.onPick});

  final int count;
  final int index;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            label: 'Go to screen ${i + 1} of $count',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onPick(i),
              child: SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOut,
                      width: i == index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == index ? AapnoBazar.navy : AapnoBazar.navy.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Round navy Next button wrapped in a gold ring that fills a quarter per
/// slide.
class _NextRing extends StatelessWidget {
  const _NextRing({required this.progress, required this.onTap});

  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Next',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, value, child) => CustomPaint(painter: _RingPainter(value), child: child),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AapnoBazar.navy,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AapnoBazar.navy.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: _ivory, size: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 3);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawOval(rect, paint..color = AapnoBazar.navy.withValues(alpha: 0.12))
      ..drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint..color = AapnoBazar.gold);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
