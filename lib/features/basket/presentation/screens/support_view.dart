import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportView extends StatelessWidget {
  const SupportView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 22),
          decoration: BoxDecoration(color: BasketColors.ink, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26))),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Help & support', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Typical reply in under 2 min', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.5))),
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
                  Expanded(child: _ContactTile(icon: Icons.chat_bubble_outline, label: 'Chat with us', filled: true)),
                  const SizedBox(width: 9),
                  Expanded(child: _ContactTile(icon: Icons.call_outlined, label: 'Call support', filled: false)),
                  const SizedBox(width: 9),
                  Expanded(child: _ContactTile(icon: Icons.circle_outlined, label: 'WhatsApp', filled: false)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Common questions', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 11),
              for (final q in BasketCatalog.faqs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.68),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(q, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600))),
                        Text('›', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
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

class _ContactTile extends StatelessWidget {
  const _ContactTile({required this.icon, required this.label, required this.filled});

  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 15),
      decoration: BoxDecoration(
        color: filled ? BasketColors.ink : Colors.transparent,
        border: filled ? null : Border.all(color: BasketColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: filled ? Colors.white : BasketColors.ink),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: filled ? Colors.white : BasketColors.ink),
          ),
        ],
      ),
    );
  }
}
