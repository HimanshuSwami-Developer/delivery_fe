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
          if (i > 0) const SizedBox(width: 5),
          Expanded(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: i < step ? 1 : 0.22),
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
