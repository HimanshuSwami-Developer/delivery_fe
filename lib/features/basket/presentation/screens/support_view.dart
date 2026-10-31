import 'package:fastswipe/core/basket_api/models/support_models.dart';
import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
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
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.sm, BasketSpace.gutter, BasketSpace.lg),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient, borderRadius: BorderRadius.vertical(bottom: Radius.circular(BasketRadius.xl))),
          child: Row(
            children: [
              InkWell(
                onTap: cubit.back,
                borderRadius: BorderRadius.circular(BasketRadius.pill),
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
              const SizedBox(width: BasketSpace.xs),
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
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, BasketSpace.lg),
            children: [
              // Each contact button's `onPressed` is null (not just a no-op)
              // when the backend hasn't configured that contact method yet —
              // [ApiSupportConfig] fields are blank until an admin fills them
              // in — so it renders disabled instead of opening a broken link.
              Row(
                children: [
                  Expanded(
                    child: BasketButton(
                      icon: Icons.call_outlined,
                      label: 'Call support',
                      size: BasketButtonSize.medium,
                      onPressed: config?.phoneNumber.isNotEmpty == true ? () => launchUrl(Uri(scheme: 'tel', path: config!.phoneNumber)) : null,
                    ),
                  ),
                  const SizedBox(width: BasketSpace.xs),
                  Expanded(
                    child: BasketButton.secondary(
                      icon: Icons.circle_outlined,
                      label: 'WhatsApp',
                      size: BasketButtonSize.medium,
                      onPressed: config?.whatsappLink.isNotEmpty == true
                          ? () => launchUrl(Uri.parse(config!.whatsappLink), mode: LaunchMode.externalApplication)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BasketSpace.xl),
              Text('Common questions', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: BasketSpace.sm),
              if (faqs.isEmpty)
                Text(
                  'No FAQs added yet.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500, color: BasketColors.muted),
                )
              else
                for (final faq in faqs) Padding(padding: const EdgeInsets.only(bottom: BasketSpace.xs), child: _FaqTile(faq: faq)),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(BasketSpace.sm),
      decoration: basketCard(),
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
