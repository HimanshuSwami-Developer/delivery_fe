import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:flutter/material.dart';

/// The "Aapno Bazar" logo mark — a basket outline with two feet and a
/// sprouting stem, traced 1:1 from the mockup's inline SVG (`viewBox
/// "0 0 48 48"`) via [CustomPainter] rather than approximated with a stock
/// Material icon, so the splash screen matches the design exactly.
class BazarMark extends StatelessWidget {
  const BazarMark({super.key, this.size = 58});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _BazarMarkPainter());
  }
}

class _BazarMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);

    final basketPaint = Paint()
      ..color = AapnoBazar.navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final basketPath = Path()
      ..moveTo(6, 13)
      ..lineTo(11, 13)
      ..lineTo(15.6, 33.2)
      ..arcToPoint(const Offset(18.5, 35), radius: const Radius.circular(3), clockwise: false)
      ..lineTo(35.7, 35)
      ..arcToPoint(const Offset(38.6, 32.8), radius: const Radius.circular(3), clockwise: false)
      ..lineTo(42, 19)
      ..lineTo(13, 19);
    canvas.drawPath(basketPath, basketPaint);

    final feetPaint = Paint()..color = AapnoBazar.navy;
    canvas.drawCircle(const Offset(20, 41), 2.6, feetPaint);
    canvas.drawCircle(const Offset(35, 41), 2.6, feetPaint);

    final sproutPaint = Paint()
      ..color = AapnoBazar.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final sproutPath = Path()
      ..moveTo(27, 5)
      ..lineTo(27, 14)
      ..moveTo(27, 14)
      ..cubicTo(23, 14, 21, 11.6, 21, 9)
      ..cubicTo(21, 6.4, 23, 5, 25, 5);
    canvas.drawPath(sproutPath, sproutPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
