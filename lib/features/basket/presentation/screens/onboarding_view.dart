import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/models.dart';
import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches the Claude Design "Aapno Bazar — Onboarding" mockup: a hero
/// panel with a badge chip, title/body below it, then a dots row (tappable
/// — see `BasketCubit.setOnboardSlide`) and a Skip + Next/CTA row. There's
/// no top logo/skip bar in the design (unlike the old version of this
/// screen) — Skip lives next to the primary button instead.
class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final slideIndex = context.select((BasketCubit c) => c.state.onboardSlide);
    final slides = BasketCatalog.onboarding;
    final slide = slides[slideIndex];
    final last = slideIndex == slides.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  // The hero's own horizontal inset is narrower (20) than
                  // the text/controls below it (32) — matches the mockup's
                  // `margin:8px 20px 0` on the hero vs `padding:...32px...`
                  // on the text and button rows, so the hero reads as
                  // slightly wider/full-bleed relative to the copy.
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    // AnimatedSwitcher lays its child out in a Stack, which
                    // always gives non-positioned children loose constraints
                    // — without `SizedBox.expand` here the panel shrink-wraps
                    // to its center icon instead of filling the Expanded area.
                    child: SizedBox.expand(
                      key: ValueKey(slideIndex),
                      child: _HeroPanel(slide: slide),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 34, 32, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey('text-$slideIndex'),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        slide.title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 31, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.93, color: AapnoBazar.navy),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        slide.body,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.6, fontWeight: FontWeight.w500, color: AapnoBazar.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var i = 0; i < slides.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => cubit.setOnboardSlide(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              width: i == slideIndex ? 30 : 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: i == slideIndex ? AapnoBazar.navy : AapnoBazar.dotIdle,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: cubit.skipOnboarding,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                            child: Text('Skip', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AapnoBazar.textFaint)),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: GestureDetector(
                            onTap: cubit.nextOnboardSlide,
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: AapnoBazar.navy,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(color: AapnoBazar.navy.withValues(alpha: 0.7), blurRadius: 28, spreadRadius: -12, offset: const Offset(0, 14)),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    last ? 'Start shopping' : 'Next',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward_rounded, size: 17, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// Stand-in for the mockup's `<image-slot>` hero photo — this app has no
/// real image pipeline for onboarding art, so a tinted panel with the
/// slide's icon plays that role instead, keeping the badge chip and
/// gradient treatment from the design.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.slide});

  final OnboardSlide slide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AapnoBazar.heroPanelBg),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AapnoBazar.navy.withValues(alpha: 0.06)),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AapnoBazar.navy.withValues(alpha: 0.06)),
              ),
            ),
            Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AapnoBazar.navy.withValues(alpha: 0.16), blurRadius: 28, offset: const Offset(0, 12))],
                ),
                alignment: Alignment.center,
                child: Icon(slide.icon, size: 48, color: AapnoBazar.navy),
              ),
            ),
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(100)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: AapnoBazar.gold, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(slide.badge, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AapnoBazar.navy)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
