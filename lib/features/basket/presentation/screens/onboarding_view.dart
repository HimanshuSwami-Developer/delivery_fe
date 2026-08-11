import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingView extends StatelessWidget {
  const OnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final slideIndex = context.select((BasketCubit c) => c.state.onboardSlide);
    final slides = BasketCatalog.onboarding;
    final slide = slides[slideIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(color: BasketColors.primary, borderRadius: BorderRadius.circular(8)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.shopping_basket_rounded, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Text('Aapno Bazar', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.15, color: BasketColors.ink)),
                    ],
                  ),
                  TextButton(
                    onPressed: cubit.skipOnboarding,
                    child: Text('Skip', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: BasketColors.muted)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        // AnimatedSwitcher lays its child out in a Stack,
                        // which always gives non-positioned children loose
                        // constraints — without `SizedBox.expand` here the
                        // panel shrink-wraps to its center icon instead of
                        // filling the Expanded area.
                        child: SizedBox.expand(
                          key: ValueKey(slideIndex),
                          child: _IllustrationPanel(icon: slide.icon),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Column(
                        key: ValueKey('text-$slideIndex'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title,
                            style: GoogleFonts.poppins(fontSize: 27, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: BasketColors.ink),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.body,
                            style: GoogleFonts.poppins(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 40),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < slides.length; i++) ...[
                          if (i > 0) const SizedBox(width: 6),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: i == slideIndex ? 24 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == slideIndex ? BasketColors.primary : BasketColors.ink.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BasketColors.primary,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      minimumSize: Size.zero,
                    ),
                    onPressed: cubit.nextOnboardSlide,
                    child: Text(
                      slideIndex == slides.length - 1 ? 'Get started' : 'Next',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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

/// Onboarding has no real illustration asset pipeline — a themed icon on a
/// soft green-tinted panel (with a couple of translucent decorative
/// circles behind it) reads as designed instead of a generic gray
/// placeholder box.
class _IllustrationPanel extends StatelessWidget {
  const _IllustrationPanel({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: BasketColors.primarySoft),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: -30,
              left: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(shape: BoxShape.circle, color: BasketColors.primary.withValues(alpha: 0.08)),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(shape: BoxShape.circle, color: BasketColors.primary.withValues(alpha: 0.08)),
              ),
            ),
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: BasketColors.primary.withValues(alpha: 0.16), blurRadius: 28, offset: const Offset(0, 12))],
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 48, color: BasketColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
