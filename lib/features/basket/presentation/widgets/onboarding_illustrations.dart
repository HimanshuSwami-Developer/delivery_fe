import 'dart:math' as math;

import 'package:fastswipe/features/basket/presentation/aapno_bazar_palette.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Animated onboarding art, one painter per slide — traced from the
/// Claude Design "Aapno Bazar onboarding" canvas (300×300 viewBox) and
/// recoloured into the app's navy + gold + ivory palette.
///
/// Every painter takes two clocks:
///  - [time] — seconds since the slide became active; drives the endless
///    loops (spinning clock hand, wheels, bobbing scooter, rider on the map).
///  - [intro] — seconds since the slide became active, clamped to the
///    entrance length; drives the one-shot entrances (produce dropping into
///    the basket, the route drawing itself).
///
/// They're separate so reduced-motion can freeze the loops at 0 while
/// still showing the finished entrance (intro pinned to its end).

const _ink = AapnoBazar.navy;
const _inkSoft = AapnoBazar.navyGlow;
const _gold = AapnoBazar.gold;
const _ivory = Color(0xFFFFFBF2);
const _white = Color(0xFFFFFFFF);

/// Total length of every slide's entrance, in seconds — the longest one
/// (the map route drawing in) ends at 0.3 + 1.6.
const onboardIntroSeconds = 2.0;

const _popCurve = Cubic(0.3, 1.5, 0.5, 1);
const _dropCurve = Cubic(0.3, 1.35, 0.5, 1);

/// Progress of a sub-animation that starts [delay]s into the entrance and
/// lasts [duration]s.
double _seg(double t, double delay, double duration, [Curve curve = Curves.linear]) =>
    curve.transform(((t - delay) / duration).clamp(0.0, 1.0));

/// 0 → 1 → 0 ease-in-out wave with the given period.
double _wave(double t, double period) => (1 - math.cos(2 * math.pi * t / period)) / 2;

Paint _fill(Color c) => Paint()..color = c;

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _text(
  Canvas canvas,
  String text,
  double x,
  double baseline, {
  required double size,
  FontWeight weight = FontWeight.w800,
  Color color = _ink,
  double letterSpacing = 0,
  bool center = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final top = baseline - tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  tp.paint(canvas, Offset(center ? x - tp.width / 2 : x, top));
}

/// Four-point sparkle centred on [c].
Path _sparkle(Offset c, double r) {
  final k = r * 0.3;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + k, c.dy - k)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx + k, c.dy + k)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - k, c.dy + k)
    ..lineTo(c.dx - r, c.dy)
    ..lineTo(c.dx - k, c.dy - k)
    ..close();
}

/// Scales [draw] by [s] about [origin].
void _scaled(Canvas canvas, Offset origin, double s, void Function() draw) {
  canvas
    ..save()
    ..translate(origin.dx, origin.dy)
    ..scale(s)
    ..translate(-origin.dx, -origin.dy);
  draw();
  canvas.restore();
}

/// Draws [draw] at [opacity] — skipped entirely at 0, no layer at 1.
void _faded(Canvas canvas, double opacity, void Function() draw) {
  if (opacity <= 0) return;
  if (opacity >= 1) return draw();
  canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
  draw();
  canvas.restore();
}

abstract class _OnboardPainter extends CustomPainter {
  _OnboardPainter({required this.time, required this.intro}) : super(repaint: Listenable.merge([time, intro]));

  final ValueListenable<double> time;
  final ValueListenable<double> intro;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / 300, size.height / 300);
    paintArt(canvas, time.value, intro.value);
    canvas.restore();
  }

  void paintArt(Canvas canvas, double t, double i);

  void backdrop(Canvas canvas) => canvas.drawCircle(const Offset(150, 150), 132, _fill(_white.withValues(alpha: 0.6)));

  @override
  bool shouldRepaint(covariant _OnboardPainter old) => old.time != time || old.intro != intro;
}

/// Slide 1 — a scooter racing past a ticking clock.
class ScooterClockPainter extends _OnboardPainter {
  ScooterClockPainter({required super.time, required super.intro});

  @override
  void paintArt(Canvas canvas, double t, double i) {
    backdrop(canvas);

    canvas.save();
    canvas.translate(0, -10 * _wave(t, 3.2));
    const c = Offset(150, 118);
    canvas.drawCircle(c, 72, _fill(_white));
    canvas.drawCircle(c, 72, _stroke(_ink, 8));
    final tick = _stroke(_ink, 4);
    canvas
      ..drawLine(const Offset(150, 54), const Offset(150, 64), tick)
      ..drawLine(const Offset(214, 118), const Offset(204, 118), tick)
      ..drawLine(const Offset(150, 182), const Offset(150, 172), tick)
      ..drawLine(const Offset(86, 118), const Offset(96, 118), tick)
      ..drawLine(c, const Offset(178, 118), _stroke(_ink, 7));
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(2 * math.pi * t / 3)
      ..drawLine(Offset.zero, const Offset(0, -52), _stroke(_gold, 5))
      ..restore();
    canvas.drawCircle(c, 7, _fill(_ink));

    // Lightning badge — "fast".
    _scaled(canvas, const Offset(212, 62), 1 + 0.14 * _wave(t, 1.4), () {
      canvas
        ..drawCircle(const Offset(212, 62), 22, _fill(_gold))
        ..drawCircle(const Offset(212, 62), 22, _stroke(_ink, 3))
        ..drawPath(
          Path()
            ..moveTo(215, 48)
            ..lineTo(203, 66)
            ..lineTo(212, 66)
            ..lineTo(208, 78)
            ..lineTo(222, 58)
            ..lineTo(213, 58)
            ..close(),
          _fill(_ink),
        );
    });
    canvas.restore();

    // Road — dashes scroll left so the scooter reads as moving.
    final road = _stroke(_ink.withValues(alpha: 0.35), 4);
    final phase = (t / 0.5 * 32) % 32;
    canvas
      ..save()
      ..clipRect(const Rect.fromLTRB(8, 250, 292, 274));
    for (var x = 10 - phase; x < 290; x += 32) {
      canvas.drawLine(Offset(math.max(10, x), 262), Offset(math.min(290, x + 18), 262), road);
    }
    canvas.restore();

    // Speed lines streaking off the back.
    final sp = (t % 0.8) / 0.8;
    final spOpacity = sp < 0.4 ? sp / 0.4 : 1 - (sp - 0.4) / 0.6;
    final spDx = 10 - 34 * Curves.easeOut.transform(sp);
    final speed = _stroke(_ink.withValues(alpha: 0.5 * spOpacity), 4);
    canvas
      ..drawLine(Offset(40 + spDx, 204), Offset(72 + spDx, 204), speed)
      ..drawLine(Offset(28 + spDx, 222), Offset(64 + spDx, 222), speed);

    // Scooter body bobs on the suspension.
    canvas.save();
    canvas.translate(0, -3 * _wave(t, 0.7));
    final box = RRect.fromRectAndRadius(const Rect.fromLTWH(92, 184, 46, 40), const Radius.circular(7));
    canvas
      ..drawRRect(box, _fill(_gold))
      ..drawRRect(box, _stroke(_ink, 3))
      ..drawLine(const Offset(115, 184), const Offset(115, 224), _stroke(_ink, 3))
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(96, 224, 88, 12), const Radius.circular(6)), _fill(_inkSoft))
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(138, 212, 30, 9), const Radius.circular(4.5)), _fill(_ink))
      ..drawLine(const Offset(178, 228), const Offset(194, 192), _stroke(_ink, 6))
      ..drawLine(const Offset(186, 190), const Offset(204, 190), _stroke(_ink, 6))
      ..drawCircle(const Offset(200, 203), 5, _fill(_gold))
      ..drawCircle(const Offset(200, 203), 5, _stroke(_ink, 2));
    canvas.restore();

    for (final wx in const [114.0, 186.0]) {
      canvas
        ..save()
        ..translate(wx, 246)
        ..rotate(2 * math.pi * t / 0.6)
        ..drawCircle(Offset.zero, 16, _fill(_ink))
        ..drawLine(const Offset(0, -12), const Offset(0, 12), _stroke(_ivory, 3)..strokeCap = StrokeCap.butt)
        ..drawLine(const Offset(-12, 0), const Offset(12, 0), _stroke(_ivory, 3)..strokeCap = StrokeCap.butt)
        ..restore();
    }
  }
}

/// Slide 2 — fresh produce dropping into a wicker basket.
class ProduceBasketPainter extends _OnboardPainter {
  ProduceBasketPainter({required super.time, required super.intro});

  static const _leaf = Color(0xFF3FA34D);
  static const _wicker = Color(0xFFC98B4E);
  static const _wickerDark = Color(0xFFA0652F);
  static const _weave = Color(0xFF8A5527);

  @override
  void paintArt(Canvas canvas, double t, double i) {
    backdrop(canvas);

    for (final (c, r, color, delay) in const [
      (Offset(58, 84), 10.0, _gold, 0.0),
      (Offset(246, 70), 10.0, _ink, 0.5),
      (Offset(254, 152), 8.0, _gold, 1.0),
    ]) {
      final w = _wave(t - delay, 1.6);
      _scaled(canvas, c, 0.6 + 0.4 * w, () {
        canvas.drawPath(_sparkle(c, r), _fill(color.withValues(alpha: 0.2 + 0.8 * w)));
      });
    }

    canvas.drawPath(
      Path()
        ..moveTo(92, 176)
        ..cubicTo(92, 92, 208, 92, 208, 176),
      _stroke(_wickerDark, 10),
    );

    void drop(double delay, void Function() draw) {
      final linear = _seg(i, delay, 0.9);
      final eased = _seg(i, delay, 0.9, _dropCurve);
      _faded(canvas, (linear * 2).clamp(0.0, 1.0), () {
        canvas
          ..save()
          ..translate(0, -160 * (1 - eased));
        draw();
        canvas.restore();
      });
    }

    final outline = _stroke(_ink, 3);
    drop(0.1, () {
      final r = Rect.fromCenter(center: const Offset(118, 150), width: 48, height: 72);
      canvas
        ..drawOval(r, _fill(_leaf))
        ..drawOval(r, outline)
        ..drawLine(const Offset(118, 122), const Offset(118, 184), _stroke(_ink, 2.5));
    });
    drop(0.25, () {
      final carton = RRect.fromRectAndRadius(const Rect.fromLTWH(166, 112, 38, 70), const Radius.circular(4));
      final roof = Path()
        ..moveTo(166, 112)
        ..lineTo(185, 96)
        ..lineTo(204, 112)
        ..close();
      canvas
        ..drawRRect(carton, _fill(_white))
        ..drawRRect(carton, outline)
        ..drawPath(roof, _fill(const Color(0xFFE8EEF7)))
        ..drawPath(roof, outline)
        ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(172, 134, 26, 16), const Radius.circular(3)), _fill(_inkSoft));
    });
    drop(0.4, () {
      final leaf = Path()
        ..moveTo(150, 136)
        ..quadraticBezierTo(158, 126, 166, 130)
        ..quadraticBezierTo(160, 140, 150, 136)
        ..close();
      canvas
        ..drawCircle(const Offset(150, 160), 24, _fill(const Color(0xFFF59E0B)))
        ..drawCircle(const Offset(150, 160), 24, outline)
        ..drawPath(leaf, _fill(_leaf))
        ..drawPath(leaf, _stroke(_ink, 2));
    });
    drop(0.55, () {
      final calyx = Path()
        ..moveTo(90, 150)
        ..lineTo(98, 156)
        ..lineTo(106, 150)
        ..lineTo(102, 158)
        ..lineTo(94, 158)
        ..close();
      canvas
        ..drawCircle(const Offset(98, 168), 20, _fill(const Color(0xFFE5484D)))
        ..drawCircle(const Offset(98, 168), 20, outline)
        ..drawPath(calyx, _fill(_leaf))
        ..drawPath(calyx, _stroke(_ink, 2));
    });
    drop(0.7, () {
      final carrot = Path()
        ..moveTo(192, 130)
        ..lineTo(216, 136)
        ..lineTo(198, 186)
        ..close();
      final greens = _stroke(_leaf, 3);
      canvas
        ..drawPath(carrot, _fill(const Color(0xFFF97316)))
        ..drawPath(carrot, outline)
        ..drawLine(const Offset(196, 130), const Offset(190, 116), greens)
        ..drawLine(const Offset(202, 131), const Offset(202, 115), greens)
        ..drawLine(const Offset(208, 133), const Offset(214, 120), greens);
    });

    // The basket pops in front of the produce, hiding its lower half.
    final pop = _seg(i, 0, 0.7, _popCurve);
    _faded(canvas, _seg(i, 0, 0.35), () {
      _scaled(canvas, const Offset(150, 220), 0.6 + 0.4 * pop, () {
        final body = Path()
          ..moveTo(66, 178)
          ..lineTo(234, 178)
          ..lineTo(214, 268)
          ..lineTo(86, 268)
          ..close();
        final weave = _stroke(_weave, 3);
        final rim = RRect.fromRectAndRadius(const Rect.fromLTWH(60, 170, 180, 16), const Radius.circular(8));
        canvas
          ..drawPath(body, _fill(_wicker))
          ..drawPath(body, outline)
          ..drawLine(const Offset(112, 192), const Offset(110, 262), weave)
          ..drawLine(const Offset(138, 192), const Offset(137, 262), weave)
          ..drawLine(const Offset(164, 192), const Offset(164, 262), weave)
          ..drawLine(const Offset(190, 192), const Offset(191, 262), weave)
          ..drawLine(const Offset(78, 214), const Offset(222, 214), weave)
          ..drawLine(const Offset(84, 242), const Offset(216, 242), weave)
          ..drawRRect(rim, _fill(_wickerDark))
          ..drawRRect(rim, outline);
      });
    });
  }
}

/// Slide 3 — a navy coupon with a sweeping shine, a swinging ₹ tag and
/// falling coins.
class CouponDealsPainter extends _OnboardPainter {
  CouponDealsPainter({required super.time, required super.intro, required this.background});

  /// Page tint behind the art — the coupon's punched notches are filled
  /// with it so they read as holes.
  final Color background;

  @override
  void paintArt(Canvas canvas, double t, double i) {
    backdrop(canvas);

    canvas.save();
    canvas.translate(0, -10 * _wave(t, 3.2));
    canvas
      ..translate(150, 160)
      ..rotate(-6 * math.pi / 180)
      ..translate(-150, -160);
    final coupon = RRect.fromRectAndRadius(const Rect.fromLTWH(40, 100, 220, 120), const Radius.circular(16));
    canvas.drawRRect(coupon, _fill(_ink));
    canvas
      ..drawCircle(const Offset(40, 160), 12, _fill(background))
      ..drawCircle(const Offset(260, 160), 12, _fill(background));
    final perf = _stroke(_ivory.withValues(alpha: 0.7), 2)..strokeCap = StrokeCap.butt;
    for (var y = 112.0; y < 208; y += 12) {
      canvas.drawLine(Offset(186, y), Offset(186, math.min(208, y + 6)), perf);
    }
    _text(canvas, 'COUPON', 62, 140, size: 12, weight: FontWeight.w700, color: _ivory, letterSpacing: 1.5);
    _text(canvas, 'SAVE', 62, 176, size: 32, color: _gold);
    _text(canvas, 'on every basket', 62, 198, size: 12, weight: FontWeight.w600, color: _ivory);
    _text(canvas, '%', 224, 174, size: 40, color: _gold, center: true);

    // Glint sweeping across: 0–60% of the cycle moving, then a pause.
    final sp = (t % 2.6) / 2.6;
    final shineX = -80 + 400 * Curves.easeInOut.transform(math.min(1, sp / 0.6));
    canvas
      ..save()
      ..clipRRect(coupon)
      ..translate(shineX, 0)
      ..skew(math.tan(-20 * math.pi / 180), 0)
      ..drawRect(const Rect.fromLTWH(0, 90, 36, 140), _fill(_white.withValues(alpha: 0.22)))
      ..restore();
    canvas.restore();

    // Price tag swinging from its string.
    canvas
      ..save()
      ..translate(72, 40)
      ..rotate(-10 * math.pi / 180 * math.cos(2 * math.pi * t / 2.4))
      ..translate(-72, -40);
    final tag = Path()
      ..moveTo(56, 66)
      ..lineTo(92, 66)
      ..lineTo(106, 84)
      ..lineTo(92, 102)
      ..lineTo(56, 102)
      ..close();
    canvas
      ..drawLine(const Offset(72, 40), const Offset(66, 80), _stroke(_ink, 2.5))
      ..drawPath(tag, _fill(_ivory))
      ..drawPath(tag, _stroke(_ink, 3))
      ..drawCircle(const Offset(66, 84), 4, _fill(_ink));
    _text(canvas, '₹', 84, 90, size: 16, center: true);
    canvas.restore();

    _scaled(canvas, const Offset(236, 86), 1 + 0.14 * _wave(t, 1.4), () {
      canvas
        ..drawCircle(const Offset(236, 86), 30, _fill(_gold))
        ..drawCircle(const Offset(236, 86), 30, _stroke(_ink, 3));
      _text(canvas, '%', 236, 96, size: 28, center: true);
    });

    for (final (c, delay) in const [(Offset(206, 258), 0.4), (Offset(236, 246), 0.6)]) {
      final eased = _seg(i, delay, 0.9, _dropCurve);
      _faded(canvas, (_seg(i, delay, 0.9) * 2).clamp(0.0, 1.0), () {
        canvas
          ..save()
          ..translate(0, -160 * (1 - eased))
          ..drawCircle(c, 18, _fill(_gold))
          ..drawCircle(c, 18, _stroke(_ink, 3));
        _text(canvas, '₹', c.dx, c.dy + 6, size: 16, center: true);
        canvas.restore();
      });
    }
  }
}

/// Slide 4 — a mini map with the route drawing itself from store to home
/// and a rider dot looping along it.
class LiveMapPainter extends _OnboardPainter {
  LiveMapPainter({required super.time, required super.intro});

  static final _route = Path()
    ..moveTo(76, 222)
    ..cubicTo(120, 222, 110, 160, 150, 160)
    // SVG `S 196 96, 226 88`: first control point mirrors (110,160) about (150,160).
    ..cubicTo(190, 160, 196, 96, 226, 88);

  @override
  void paintArt(Canvas canvas, double t, double i) {
    final card = RRect.fromRectAndRadius(const Rect.fromLTWH(28, 36, 244, 230), const Radius.circular(22));
    canvas
      ..drawRRect(card, _fill(_white))
      ..drawRRect(card, _stroke(_ink.withValues(alpha: 0.12), 2));

    final street = _stroke(const Color(0xFFE9EDF4), 14)..strokeCap = StrokeCap.butt;
    canvas
      ..save()
      ..clipRRect(card)
      ..drawLine(const Offset(28, 124), const Offset(272, 124), street)
      ..drawLine(const Offset(28, 204), const Offset(272, 204), street)
      ..drawLine(const Offset(112, 36), const Offset(112, 266), street)
      ..drawLine(const Offset(200, 36), const Offset(200, 266), street)
      ..restore();

    final metric = _route.computeMetrics().first;
    final dots = _fill(const Color(0xFFC9D3E3));
    for (var d = 0.0; d <= metric.length; d += 12) {
      canvas.drawCircle(metric.getTangentForOffset(d)!.position, 3, dots);
    }
    final drawn = _seg(i, 0.3, 1.6, Curves.easeOut);
    if (drawn > 0) canvas.drawPath(metric.extractPath(0, metric.length * drawn), _stroke(_ink, 6));

    // Store pin.
    canvas
      ..drawCircle(const Offset(76, 222), 16, _fill(_ink))
      ..drawCircle(const Offset(76, 222), 16, _stroke(_white, 3))
      ..drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(69, 220, 14, 10), const Radius.circular(2)), _fill(_ivory))
      ..drawArc(const Rect.fromLTWH(72, 213, 8, 8), math.pi, math.pi, false, _stroke(_ivory, 2));

    // Home pin, bouncing.
    canvas
      ..save()
      ..translate(0, -8 * _wave(t, 1));
    final pin = Path()
      ..moveTo(226, 90)
      ..cubicTo(214, 74, 206, 66, 206, 56)
      ..arcToPoint(const Offset(246, 56), radius: const Radius.circular(20))
      ..cubicTo(246, 66, 238, 74, 226, 90)
      ..close();
    final house = Path()
      ..moveTo(218, 58)
      ..lineTo(226, 50)
      ..lineTo(234, 58)
      ..lineTo(234, 66)
      ..lineTo(218, 66)
      ..close();
    canvas
      ..drawPath(pin, _fill(_gold))
      ..drawPath(pin, _stroke(_white, 3))
      ..drawPath(house, _fill(_ink))
      ..restore();

    // Rider riding the route on a loop.
    final rider = metric.getTangentForOffset(metric.length * ((t % 3.2) / 3.2))!.position;
    canvas
      ..drawCircle(rider, 9, _fill(_gold))
      ..drawCircle(rider, 9, _stroke(_ink, 3));

    // "On the way" status pill.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 52, 118, 30), const Radius.circular(15)), _fill(_ink));
    _scaled(canvas, const Offset(60, 67), 1 + 0.14 * _wave(t, 1.4), () {
      canvas.drawCircle(const Offset(60, 67), 5, _fill(const Color(0xFF4ADE80)));
    });
    _text(canvas, 'On the way', 72, 72, size: 12, weight: FontWeight.w700, color: _ivory);
  }
}
