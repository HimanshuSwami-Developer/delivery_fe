import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket/presentation/widgets/app_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Fraction across the map width for the rider marker at each of the 4
/// tracking stages, proportioned from the source design's fixed pixel
/// offsets (104/142/182/214 of a 390px canvas) so it holds up on any
/// screen width.
const _riderFractions = [104 / 390, 142 / 390, 182 / 390, 214 / 390];
const _homeFraction = 262 / 390;

/// The backend has no live rider GPS (`Order`/`DeliveryPartner` carry no
/// lat/lng), so the rider marker's position is still simulated from
/// [trackingStage] like before — this is just a real basemap under it
/// instead of the painted grid placeholder. Non-interactive: it's a
/// backdrop, not something the user pans/zooms.
const _mapCenter = LatLng(12.9352, 77.6146);

class OrderTrackingView extends StatelessWidget {
  const OrderTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final stage = context.select((BasketCubit c) => c.state.trackingStage);
    final order = context.select((BasketCubit c) => c.state.currentOrder);
    final etaLeft = etaLeftForStage(stage, eta: BasketCubit.etaMinutes);
    final headline = ['Order confirmed', 'Packing your basket', 'Rider is on the way', 'Delivered — enjoy!'][stage];
    final riderName = order?.deliveryPartnerName ?? 'Your rider';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 270,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  const Positioned.fill(child: AppMap(center: _mapCenter, zoom: 15, interactive: false)),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 110,
                    child: Container(height: 15, color: Colors.white.withValues(alpha: 0.78)),
                  ),
                  Positioned(
                    left: width * _riderFractions[stage],
                    top: 100,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(8)),
                            child: Text('Rider', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: BasketColors.ink,
                              boxShadow: [BoxShadow(color: BasketColors.ink.withValues(alpha: 0.16), spreadRadius: 6)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: width * _homeFraction,
                    top: 96,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, 0),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: BasketColors.ink.withValues(alpha: 0.12)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('You', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, border: Border.all(color: BasketColors.ink, width: 2.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 8,
                    left: 14,
                    child: InkWell(
                      onTap: cubit.back,
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: BasketColors.ink, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: ListView(
                children: [
                  Center(
                    child: Container(
                      width: 34,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(color: BasketColors.ink.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(9)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(headline, style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                            const SizedBox(height: 5),
                            Text(
                              '${order?.orderNumber ?? '—'} · ${order?.itemCount ?? 0} ${order?.itemCount == 1 ? 'item' : 'items'}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: BasketColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$etaLeft min', style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text('remaining', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const SizedBox(width: 42, height: 42, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(riderName, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                              const SizedBox(height: 3),
                              Text('Honda Activa · ★ 4.8', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55))),
                            ],
                          ),
                        ),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.call_outlined, color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: const Icon(Icons.mail_outline, color: BasketColors.ink, size: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (var i = 0; i < BasketCatalog.trackingSteps.length; i++)
                    _TimelineStep(
                      index: i,
                      title: BasketCatalog.trackingSteps[i].title,
                      sub: i == stage ? 'Now' : BasketCatalog.trackingSteps[i].sub,
                      done: i <= stage,
                      isLast: i == BasketCatalog.trackingSteps.length - 1,
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BasketColors.ink, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.refreshTracking,
                          child: Text('Refresh status', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: BasketColors.ink)),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: BasketColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: Size.zero,
                          ),
                          onPressed: cubit.goToSupport,
                          child: Text('Get help', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.index,
    required this.title,
    required this.sub,
    required this.done,
    required this.isLast,
  });

  final int index;
  final String title;
  final String sub;
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: done ? 1 : 0.45,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? BasketColors.ink : Colors.white,
                  border: Border.all(color: BasketColors.ink, width: 2),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 26,
                  color: done ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.12),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(sub, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
