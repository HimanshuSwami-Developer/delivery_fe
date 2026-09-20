import 'package:fastswipe/core/basket_api/models/support_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fetches its own FAQ list on open — every entry point navigates here via
/// a plain `cubit.go(BasketScreen.support)` (the account row, order-detail/
/// tracking "Contact support" buttons), so there's no single cubit method
/// this screen can rely on being called through; loading here instead
/// works regardless of how the user arrived.
class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  @override
  void initState() {
    super.initState();
    context.read<BasketCubit>().loadSupportFaqs();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final config = context.select((BasketCubit c) => c.state.apiSupportConfig);
    final faqs = context.select((BasketCubit c) => c.state.apiSupportFaqs);
    final replyLabel = config?.replyTimeLabel.isNotEmpty == true ? config!.replyTimeLabel : 'Typical reply in under 2 min';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 22),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(26))),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.14)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, color: Color(0xFFFFFBF2), size: 16),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Help & support', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
                  const SizedBox(height: 2),
                  Text(replyLabel, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFFFFBF2).withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ContactTile(
                      icon: Icons.call_outlined,
                      label: 'Call support',
                      filled: true,
                      onTap: config?.phoneNumber.isNotEmpty == true ? () => launchUrl(Uri(scheme: 'tel', path: config!.phoneNumber)) : null,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _ContactTile(
                      icon: Icons.circle_outlined,
                      label: 'WhatsApp',
                      filled: false,
                      onTap: config?.whatsappLink.isNotEmpty == true
                          ? () => launchUrl(Uri.parse(config!.whatsappLink), mode: LaunchMode.externalApplication)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Common questions', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 11),
              if (faqs.isEmpty)
                Text(
                  'No FAQs added yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                )
              else
                for (final faq in faqs) Padding(padding: const EdgeInsets.only(bottom: 10), child: _FaqTile(faq: faq)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.filled, required this.onTap});

  final IconData icon;
  final String label;
  final bool filled;

  /// Null (not just a no-op) when the backend hasn't configured this
  /// contact method yet — [ApiSupportConfig] fields are blank until an
  /// admin fills them in — so the tile renders dimmed and untappable
  /// instead of opening a broken link.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 15),
          decoration: BoxDecoration(
            color: filled ? BasketColors.ink : Colors.transparent,
            border: filled ? null : Border.all(color: BasketColors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: filled ? Color(0xFFFFFBF2) : BasketColors.ink),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: filled ? Color(0xFFFFFBF2) : BasketColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tap to expand/collapse the answer — real Q&A instead of the previous
/// static, non-functional row that only ever showed a question and a
/// decorative chevron.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.faq});

  final ApiSupportFaq faq;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBF2).withValues(alpha: 0.68),
        border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.faq.question, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _expanded ? 0.25 : 0,
                  child: Text('›', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text(
              widget.faq.answer,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, height: 1.55, fontWeight: FontWeight.w500, color: BasketColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
