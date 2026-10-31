import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:flutter/material.dart';

/// 3-segment progress bar shown across the address/slot/summary checkout
/// steps — the first [step] segments are filled white, the rest dim.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: BasketSpace.xxs),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Color(0xFFFFFBF2).withValues(alpha: i < step ? 1 : 0.22),
                borderRadius: BorderRadius.circular(BasketRadius.sm),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
