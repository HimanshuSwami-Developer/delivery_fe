import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single full-bleed promo banner (`Banner.placement == 'home_carousel'`)
/// — the real photo fills the card, a bottom navy scrim keeps the title
/// legible over any image, and a small gold "chip" dot echoes the splash/
/// onboarding badge-chip motif so the banner reads as part of the same
/// design system rather than a bare marketing image. Tapping it opens the
/// linked category, if the banner has one (see `BasketCubit.openBanner`).
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, required this.banner, this.height = 132});

  final ApiBanner banner;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<BasketCubit>().openBanner(banner),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(decoration: const BoxDecoration(color: BasketColors.primarySoft)),
              if (banner.imageUrl.isNotEmpty)
                Image.network(
                  banner.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [BasketColors.primary.withValues(alpha: 0.82), BasketColors.primary.withValues(alpha: 0)],
                    stops: const [0, 0.75],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: BasketColors.gold, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        banner.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, height: 1.25, fontWeight: FontWeight.w800, color: Colors.white),
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

/// Two banners shown side-by-side (the home page's final "two more
/// banners" slot) — half-width instead of stacked full-bleed, so this
/// section reads visually distinct from the single-banner slots above it.
class PromoBannerRow extends StatelessWidget {
  const PromoBannerRow({super.key, required this.banners});

  final List<ApiBanner> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();
    if (banners.length == 1) return PromoBanner(banner: banners.first);
    return Row(
      children: [
        Expanded(child: PromoBanner(banner: banners[0], height: 150)),
        const SizedBox(width: 10),
        Expanded(child: PromoBanner(banner: banners[1], height: 150)),
      ],
    );
  }
}
