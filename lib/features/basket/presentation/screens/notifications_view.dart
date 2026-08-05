import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Backend notifications don't carry their own glyph — pick one from the
/// audience they were sent to, matching the source design's per-item icons.
String _iconFor(String audience) => switch (audience) {
      'transactional' => '⬒',
      'cart_abandoners' => '◍',
      'gold_platinum' => '◐',
      _ => '✧',
    };

String _relativeTime(DateTime? sentAt) {
  if (sentAt == null) return 'Draft';
  final diff = DateTime.now().difference(sentAt.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} hr ago';
  return '${diff.inDays} days ago';
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final notifications = context.select((BasketCubit c) => c.state.apiNotifications);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 16),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Text('Notifications', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              for (final n in notifications)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: glassCard(radius: 15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(_iconFor(n.audience), style: const TextStyle(fontSize: 13, color: Colors.white)),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(n.body, style: GoogleFonts.manrope(fontSize: 11, height: 1.5, fontWeight: FontWeight.w500, color: BasketColors.muted)),
                              const SizedBox(height: 6),
                              Text(_relativeTime(n.sentAt), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: BasketColors.faint)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
