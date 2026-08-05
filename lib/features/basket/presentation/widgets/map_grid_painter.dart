import 'package:flutter/material.dart';

/// Decorative map placeholder — a grid pattern with a couple of "road"
/// bands, matching the source design's `repeating-linear-gradient` map
/// background (there's no real map SDK wired in). Shared by the
/// address-edit pin-drop screen and the live order-tracking screen.
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFE6E6EA));
    final roadPaint = Paint()..color = const Color(0xFFDCDCE2);
    for (double y = 30; y < size.height; y += 32) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), roadPaint);
    }
    for (double x = 44; x < size.width; x += 46) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), roadPaint);
    }
    final avenuePaint = Paint()..color = Colors.white.withValues(alpha: 0.75);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.42, size.width, 14), avenuePaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.28, 0, 16, size.height), avenuePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
