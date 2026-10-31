import 'dart:math' as math;

import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/cubit/basket_state.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _cream = Color(0xFFFFFBF2);
const _green = Color(0xFF16A34A);

/// Cart card: "Add ₹X more for FREE delivery" with a progress bar, which
/// flips to a "FREE delivery unlocked" state once the admin-set threshold
/// is reached (see `StoreSettings.delivery_fee_for`).
class FreeDeliveryProgressCard extends StatelessWidget {
  const FreeDeliveryProgressCard({super.key, required this.t});

  final BasketTotals t;

  @override
  Widget build(BuildContext context) {
    if (!t.freeDeliveryEnabled && t.deliveryFee > 0) return const SizedBox.shrink();
    final unlocked = t.hasFreeDelivery;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: unlocked ? _green.withValues(alpha: 0.1) : _cream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? _green.withValues(alpha: 0.45) : BasketColors.ink.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                  child: child,
                ),
                child: Text(
                  unlocked ? '🎉' : '🛵',
                  key: ValueKey(unlocked),
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text.rich(
                    key: ValueKey('${unlocked}_${t.amountToFreeDelivery}'),
                    unlocked
                        ? TextSpan(children: [
                            const TextSpan(text: 'Yay! You got '),
                            TextSpan(text: 'FREE delivery', style: TextStyle(color: _green, fontWeight: FontWeight.w800)),
                            const TextSpan(text: ' on this order'),
                          ])
                        : TextSpan(children: [
                            const TextSpan(text: 'Add '),
                            TextSpan(
                              text: moneyLabel(t.amountToFreeDelivery),
                              style: const TextStyle(color: BasketColors.primary, fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(text: ' more for '),
                            const TextSpan(text: 'FREE delivery', style: TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: BasketColors.ink),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: t.freeDeliveryProgress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: BasketColors.ink.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(unlocked ? _green : BasketColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unlocked
                ? 'You saved ${moneyLabel(t.standardDeliveryFee)} on delivery'
                : 'Free delivery on orders above ${moneyLabel(t.freeDeliveryAbove)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Bill line for delivery: "₹19", or a struck-through "₹19" + "FREE".
class DeliveryFeeBillRow extends StatelessWidget {
  const DeliveryFeeBillRow({super.key, required this.t});

  final BasketTotals t;

  @override
  Widget build(BuildContext context) {
    final label = GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: BasketColors.muted);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Delivery fee', style: label),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: t.hasFreeDelivery
              ? Row(
                  key: const ValueKey('free'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      moneyLabel(t.standardDeliveryFee),
                      style: label.copyWith(decoration: TextDecoration.lineThrough, color: BasketColors.faint),
                    ),
                    const SizedBox(width: 6),
                    Text('FREE', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: _green)),
                  ],
                )
              : Text(
                  moneyLabel(t.deliveryFee),
                  key: const ValueKey('fee'),
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.ink),
                ),
        ),
      ],
    );
  }
}

/// One-line hint for the floating cart bar.
String freeDeliveryHint(BasketTotals t) {
  if (t.hasFreeDelivery) return '🎉 FREE delivery unlocked';
  if (t.freeDeliveryEnabled && t.amountToFreeDelivery > 0) {
    return 'Add ${moneyLabel(t.amountToFreeDelivery)} more for FREE delivery';
  }
  return '+ ${moneyLabel(t.deliveryFee)} delivery fee';
}

/// Full-screen party-popper burst, fired once each time the basket crosses
/// into free delivery because of a cart change — from any screen. Sits as
/// a non-interactive layer on top of the shopping shell.
class FreeDeliveryCelebration extends StatefulWidget {
  const FreeDeliveryCelebration({super.key});

  @override
  State<FreeDeliveryCelebration> createState() => _FreeDeliveryCelebrationState();
}

class _FreeDeliveryCelebrationState extends State<FreeDeliveryCelebration> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  List<_Confetti> _pieces = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _shouldCelebrate(BasketState prev, BasketState next) {
    if (identical(prev.cart, next.cart)) return false;
    return !cartTotals(prev).hasFreeDelivery && cartTotals(next).hasFreeDelivery;
  }

  void _celebrate() {
    HapticFeedback.mediumImpact();
    final rnd = math.Random();
    const colors = [
      Color(0xFFF43F5E),
      Color(0xFFF59E0B),
      Color(0xFF22C55E),
      Color(0xFF3B82F6),
      Color(0xFFA855F7),
      Color(0xFFEC4899),
      Color(0xFFFACC15),
    ];
    // Two poppers, one from each bottom corner, angled up and inward.
    _pieces = [
      for (var i = 0; i < 110; i++)
        () {
          final left = i.isEven;
          final angle = (left ? -60.0 : -120.0) + (rnd.nextDouble() - 0.5) * 50;
          final speed = 0.95 + rnd.nextDouble() * 0.75;
          final rad = angle * math.pi / 180;
          return _Confetti(
            fromLeft: left,
            vx: math.cos(rad) * speed,
            vy: math.sin(rad) * speed,
            color: colors[rnd.nextInt(colors.length)],
            size: 5 + rnd.nextDouble() * 6,
            spin: (rnd.nextDouble() - 0.5) * 18,
            shape: rnd.nextInt(3),
            delay: rnd.nextDouble() * 0.08,
          );
        }(),
    ];
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BasketCubit, BasketState>(
      listenWhen: _shouldCelebrate,
      listener: (_, _) => _celebrate(),
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (!_controller.isAnimating) return const SizedBox.expand();
            final v = _controller.value;
            // Banner pops in, holds, then fades out near the end.
            final bannerIn = Curves.elasticOut.transform((v / 0.25).clamp(0.0, 1.0));
            final bannerOpacity = v < 0.8 ? 1.0 : (1 - (v - 0.8) / 0.2);
            return Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _ConfettiPainter(_pieces, v))),
                Align(
                  alignment: const Alignment(0, -0.25),
                  child: Opacity(
                    opacity: bannerOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: bannerIn,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                        decoration: BoxDecoration(
                          color: BasketColors.ink,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: BasketColors.ink.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 12)),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 34)),
                            const SizedBox(height: 6),
                            Text(
                              'FREE delivery unlocked!',
                              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: _cream),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'No delivery charge on this order',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: _cream.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Confetti {
  const _Confetti({
    required this.fromLeft,
    required this.vx,
    required this.vy,
    required this.color,
    required this.size,
    required this.spin,
    required this.shape,
    required this.delay,
  });

  final bool fromLeft;

  /// Launch velocity in screen-heights per (normalised) second.
  final double vx;
  final double vy;
  final Color color;
  final double size;
  final double spin;
  final int shape; // 0 = strip, 1 = square, 2 = circle
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress);

  final List<_Confetti> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final scale = size.height;
    for (final p in pieces) {
      final t = ((progress - p.delay) / (1 - p.delay)).clamp(0.0, 1.0) * 2.4;
      if (t <= 0) continue;
      // Ballistic arc with air drag on x and gravity on y.
      final drag = 1 - math.exp(-1.6 * t);
      final x = (p.fromLeft ? 0.0 : size.width) + p.vx * scale * 0.55 * drag;
      final y = size.height + p.vy * scale * 0.9 * t + 0.62 * scale * t * t;
      if (y > size.height + 20 && t > 0.5) continue;
      final fade = progress > 0.75 ? (1 - (progress - 0.75) / 0.25) : 1.0;
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      // Fake 3D flutter by squashing one axis over time.
      canvas.scale(1, math.cos(p.spin * t * 0.7).abs() * 0.8 + 0.2);
      switch (p.shape) {
        case 0:
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size * 0.5, height: p.size * 1.8), const Radius.circular(1.5)),
            paint,
          );
        case 1:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
        default:
          canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
