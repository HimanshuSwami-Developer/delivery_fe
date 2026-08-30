import 'dart:math';

import 'package:fastswipe/features/basket/presentation/festival_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Decorative motif layer for a festival-themed home header — picks the
/// right animation/painter for [theme].motif. Meant to sit early in the
/// header's `Stack` (behind the address/search content painted after it).
class FestivalOverlay extends StatelessWidget {
  const FestivalOverlay({super.key, required this.theme});

  final FestivalTheme theme;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: switch (theme.motif) {
          FestivalMotif.diyaLights => CustomPaint(painter: _DiyaGarlandPainter(accent: theme.accent)),
          FestivalMotif.colorSplash => const CustomPaint(painter: _ColorSplashPainter()),
          FestivalMotif.snowfall => const _FallingParticles(kind: _ParticleKind.snow),
          FestivalMotif.confetti => _FallingParticles(kind: _ParticleKind.confetti, accent: theme.accent),
        },
      ),
    );
  }
}

/// Small greeting pill for a festival header — e.g. "Happy Diwali! ...".
class FestivalBadge extends StatelessWidget {
  const FestivalBadge({super.key, required this.theme});

  final FestivalTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.accent.withValues(alpha: 0.18),
        border: Border.all(color: theme.accent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        theme.greeting,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFFFFBF2)),
      ),
    );
  }
}

/// One-time "Happy Diwali!"-style popup — shown at most once a day (see
/// [BasketCubit._maybeShowFestivalPopup]) when a festival is active, styled
/// with that festival's own gradient/motif/accent so it reads as part of
/// the same takeover as the home header, not a generic promo dialog.
Future<void> showFestivalPopup(BuildContext context, FestivalTheme theme) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(gradient: theme.gradient),
          child: Stack(
            children: [
              FestivalOverlay(theme: theme),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      theme.popupTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 21, fontWeight: FontWeight.w800, color: const Color(0xFFFFFBF2)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      theme.popupMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.45, color: const Color(0xFFFFFBF2).withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.accent,
                          foregroundColor: const Color(0xFF0A1F3C),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Shop the sale', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBF2).withValues(alpha: 0.14), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFFFFBF2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A gentle string-lights garland along the header's top edge — a row of
/// glowing bulbs alternating between [accent] gold and a warm orange,
/// strung along a shallow sine curve like a hung festoon.
class _DiyaGarlandPainter extends CustomPainter {
  _DiyaGarlandPainter({required this.accent});

  final Color accent;
  static const _bulbCount = 12;
  static const _warmOrange = Color(0xFFE8703A);

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _bulbCount; i++) {
      final t = _bulbCount == 1 ? 0.0 : i / (_bulbCount - 1);
      final x = size.width * t;
      final y = 14 + 10 * sin(t * pi);
      final color = i.isEven ? accent : _warmOrange;

      canvas.drawCircle(Offset(x, y), 7, Paint()..color = color.withValues(alpha: 0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(Offset(x, y), 2.6, Paint()..color = color.withValues(alpha: 0.9));
    }
  }

  @override
  bool shouldRepaint(covariant _DiyaGarlandPainter oldDelegate) => oldDelegate.accent != accent;
}

/// Soft blurred colour blobs scattered across the header — Holi's colour-
/// powder motif, kept subtle enough not to fight the header's own content.
class _ColorSplashPainter extends CustomPainter {
  const _ColorSplashPainter();

  static const _colors = [Color(0xFFFF6F91), Color(0xFF4FC3F7), Color(0xFFFFD54F), Color(0xFF66BB6A), Color(0xFFBA68C8)];
  static const _spots = [Offset(0.08, 0.15), Offset(0.35, 0.7), Offset(0.62, 0.1), Offset(0.85, 0.55), Offset(0.5, 0.35)];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _spots.length; i++) {
      final center = Offset(_spots[i].dx * size.width, _spots[i].dy * size.height);
      canvas.drawCircle(
        center,
        size.width * 0.16,
        Paint()..color = _colors[i % _colors.length].withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ColorSplashPainter oldDelegate) => false;
}

enum _ParticleKind { snow, confetti }

class _Particle {
  _Particle(Random rng)
      : x = rng.nextDouble(),
        phase = rng.nextDouble(),
        speed = 0.6 + rng.nextDouble() * 0.7,
        size = 3 + rng.nextDouble() * 4,
        sway = rng.nextDouble() * 2 * pi,
        colorIndex = rng.nextInt(4),
        spin = rng.nextDouble() * 2 * pi;

  final double x;
  final double phase;
  final double speed;
  final double size;
  final double sway;
  final int colorIndex;
  final double spin;
}

/// Looping falling-particle animation shared by snowfall (Christmas) and
/// confetti (New Year) — same drift/loop mechanics, different marks.
class _FallingParticles extends StatefulWidget {
  const _FallingParticles({required this.kind, this.accent});

  final _ParticleKind kind;
  final Color? accent;

  @override
  State<_FallingParticles> createState() => _FallingParticlesState();
}

class _FallingParticlesState extends State<_FallingParticles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random(widget.kind.index);
    _particles = List.generate(22, (_) => _Particle(rng));
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.kind == _ParticleKind.snow
        ? const [Color(0xFFFFFBF2), Color(0xFFFFFBF2), Color(0xFFFFFBF2), Color(0xFFE6F0FF)]
        : [const Color(0xFFF3B14A), widget.accent ?? const Color(0xFFF3B14A), const Color(0xFFFFFBF2), const Color(0xFF66BB6A)];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _ParticlesPainter(particles: _particles, t: _controller.value, kind: widget.kind, colors: colors)),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({required this.particles, required this.t, required this.kind, required this.colors});

  final List<_Particle> particles;
  final double t;
  final _ParticleKind kind;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final fall = (p.phase + t * p.speed) % 1.0;
      final dy = fall * size.height;
      final swayX = kind == _ParticleKind.snow ? sin(fall * 2 * pi + p.sway) * 6 : 0.0;
      final dx = p.x * size.width + swayX;
      final color = colors[p.colorIndex % colors.length];
      final fade = (1 - (fall - 0.85).clamp(0, 0.15) / 0.15).clamp(0.0, 1.0);

      if (kind == _ParticleKind.snow) {
        canvas.drawCircle(Offset(dx, dy), p.size * 0.45, Paint()..color = color.withValues(alpha: 0.85 * fade));
      } else {
        canvas.save();
        canvas.translate(dx, dy);
        canvas.rotate(p.spin + fall * 4 * pi);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), Paint()..color = color.withValues(alpha: 0.85 * fade));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => oldDelegate.t != t;
}
