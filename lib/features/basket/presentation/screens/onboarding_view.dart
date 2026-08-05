import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
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
                  Text('basket', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.15)),
                  TextButton(
                    onPressed: () => cubit.go(BasketScreen.login),
                    child: Text('Skip', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8A8A92))),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: BasketColors.slot,
                            border: Border.all(color: BasketColors.ink.withValues(alpha: 0.06)),
                          ),
                          child: ImageSlot(caption: slide.slotLabel),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      slide.title,
                      style: GoogleFonts.manrope(fontSize: 27, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      slide.body,
                      style: GoogleFonts.manrope(fontSize: 14, height: 1.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
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
                          if (i > 0) const SizedBox(width: 5),
                          Container(
                            width: 22,
                            height: 4,
                            decoration: BoxDecoration(
                              color: BasketColors.ink.withValues(alpha: i == slideIndex ? 1 : 0.18),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BasketColors.ink,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                      minimumSize: Size.zero,
                    ),
                    onPressed: cubit.nextOnboardSlide,
                    child: Text(
                      slideIndex == slides.length - 1 ? 'Get started' : 'Next',
                      style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
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
