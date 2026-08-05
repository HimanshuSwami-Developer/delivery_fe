import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';

enum ImageSlotShape { rect, rounded, circle, pill }

/// Placeholder box mimicking the empty state of the design's `<image-slot>`
/// web component: a tinted panel with a centered image icon, and — on
/// larger, non-`mini` slots — a caption underneath. Part 1 ships with no
/// real photos wired in (the source `.dc.html` never sets a `src`), so this
/// placeholder is what every product/hero image renders as.
class ImageSlot extends StatelessWidget {
  const ImageSlot({
    super.key,
    this.shape = ImageSlotShape.rounded,
    this.radius = 12,
    this.mini = false,
    this.caption,
  });

  final ImageSlotShape shape;
  final double radius;
  final bool mini;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final borderRadius = switch (shape) {
      ImageSlotShape.rect => BorderRadius.zero,
      ImageSlotShape.rounded => BorderRadius.circular(radius),
      ImageSlotShape.circle => BorderRadius.circular(999),
      ImageSlotShape.pill => BorderRadius.circular(999),
    };

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0x14808080)),
        child: SizedBox.expand(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: mini ? 18 : 28,
                  color: BasketColors.faint,
                ),
                if (!mini && caption != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      caption!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: BasketColors.faint),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
