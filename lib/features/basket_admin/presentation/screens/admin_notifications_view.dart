import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kAudiences = ['All users', 'Cart abandoners', 'Gold + Platinum'];

const _kFlex = [2.0, 1.0, 1.0, 1.0];

/// Notification management: campaign history table on the left (real
/// sent-campaign data), a compose panel + live preview on the right that
/// actually sends via the promotions API.
class AdminNotificationsView extends StatelessWidget {
  const AdminNotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.select((BasketAdminCubit c) => c.state.apiNotifications);

    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 900;

        final history = Container(
          clipBehavior: Clip.antiAlias,
          decoration: adminCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(AdminSpace.card, AdminSpace.card, AdminSpace.card, AdminSpace.sm),
                child: AdminSectionTitle('Campaign history'),
              ),
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(AdminSpace.card, 0, AdminSpace.card, AdminSpace.card),
                  child: Text('No campaigns sent yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 620,
                  child: Column(
                    children: [
                      if (notifications.isNotEmpty) const AdminTableHeader(flex: _kFlex, labels: ['Campaign', 'Audience', 'Sent', 'Opened']),
                      for (final n in notifications) _NotifRow(n: n),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        final compose = _ComposePanel(narrow: narrow);

        if (narrow) {
          return Column(children: [history, const SizedBox(height: AdminSpace.section), compose]);
        }
        // Plain Row rather than `IntrinsicHeight`: the history card's
        // internal horizontal-scrolling table can under-report its
        // intrinsic height relative to its real layout height, which
        // clips it against the shorter compose column. Letting each side
        // size to its own natural height avoids that mismatch entirely.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 150, child: history),
            const SizedBox(width: AdminSpace.section),
            Expanded(flex: 100, child: compose),
          ],
        );
      }),
    );
  }
}

class _NotifRow extends StatelessWidget {
  const _NotifRow({required this.n});
  final ApiNotification n;

  @override
  Widget build(BuildContext context) {
    final openRate = n.sentCount == 0 ? '—' : '${((n.openedCount / n.sentCount) * 100).toStringAsFixed(1)}%';
    return AdminTableRow(
      flex: _kFlex,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.title, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(n.body, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
          ],
        ),
        Text(n.audience, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text('${n.sentCount}', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
        Text(openRate, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ComposePanel extends StatefulWidget {
  const _ComposePanel({required this.narrow});
  final bool narrow;

  @override
  State<_ComposePanel> createState() => _ComposePanelState();
}

class _ComposePanelState extends State<_ComposePanel> {
  final _title = TextEditingController(text: 'Monsoon staples, 20% off');
  final _body = TextEditingController(text: 'Atta, dal and oil at monsoon prices. Tonight only.');
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send(BasketAdminCubit cubit) async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    await cubit.sendNotification(title: _title.text.trim(), body: _body.text.trim());
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final audience = context.select((BasketAdminCubit c) => c.state.audience);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AdminSpace.card),
          decoration: adminDarkCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Compose', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
              const SizedBox(height: AdminSpace.md),
              _DarkField(label: 'Title', controller: _title),
              const SizedBox(height: AdminSpace.md),
              _DarkField(label: 'Body', controller: _body, maxLines: 2),
              const SizedBox(height: AdminSpace.md),
              Wrap(
                spacing: AdminSpace.xs,
                runSpacing: AdminSpace.xs,
                children: [
                  for (final a in _kAudiences)
                    InkWell(
                      onTap: () => cubit.setAudience(a),
                      borderRadius: BorderRadius.circular(AdminRadius.pill),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm),
                        decoration: BoxDecoration(
                          color: audience == a ? Color(0xFFFFFBF2) : Colors.transparent,
                          border: Border.all(color: audience == a ? Color(0xFFFFFBF2) : Color(0xFFFFFBF2).withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(AdminRadius.pill),
                        ),
                        child: Text(a,
                            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: audience == a ? AdminColors.ink : Color(0xFFFFFBF2))),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AdminSpace.md),
              // Secondary (white fill, ink text) — a primary ink button
              // would vanish against this dark ink panel.
              AdminButton.secondary(
                label: _sending ? 'Sending…' : 'Send to $audience',
                expand: true,
                onPressed: _sending ? null : () => _send(cubit),
              ),
            ],
          ),
        ),
        const SizedBox(height: AdminSpace.section),
        Container(
          padding: const EdgeInsets.all(AdminSpace.card),
          decoration: adminCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Preview', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: AdminSpace.sm),
              Container(
                padding: const EdgeInsets.all(AdminSpace.sm),
                decoration: adminCard(color: AdminColors.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: AdminColors.ink, borderRadius: BorderRadius.circular(AdminRadius.sm)),
                          child: Text('b', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2))),
                        ),
                        const SizedBox(width: AdminSpace.xs),
                        Text('basket · now', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AdminColors.muted)),
                      ],
                    ),
                    const SizedBox(height: AdminSpace.xs),
                    AnimatedBuilder(
                      animation: _title,
                      builder: (context, _) => Text(_title.text.isEmpty ? 'Title' : _title.text,
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: AdminSpace.xxs),
                    AnimatedBuilder(
                      animation: _body,
                      builder: (context, _) => Text(_body.text,
                          style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.5, color: AdminColors.muted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({required this.label, required this.controller, this.maxLines = 1});
  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: AdminSpace.sm),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBF2).withValues(alpha: 0.08),
        border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2).withValues(alpha: 0.45), letterSpacing: 0.6)),
          const SizedBox(height: AdminSpace.xxs),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.5, color: Color(0xFFFFFBF2).withValues(alpha: 0.9)),
            cursorColor: Color(0xFFFFFBF2),
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
