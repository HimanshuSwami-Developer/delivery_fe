import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/data/basket_catalog.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/widgets/glass.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final phone = context.select((BasketCubit c) => c.state.phone);
    final phoneLabel = phone.isEmpty ? '98765 43210' : phone;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18, MediaQuery.paddingOf(context).top + 12, 18, 22),
          decoration: darkHeaderDecoration(),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(width: 52, height: 52, child: ImageSlot(shape: ImageSlotShape.circle, mini: true)),
              ),
              const SizedBox(width: 13),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Aarav Sharma', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(
                    '+91 $phoneLabel',
                    style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Refer & earn ₹250', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(
                      'Your friend gets ₹100 off their first order, you get ₹250 in credits.',
                      style: GoogleFonts.manrope(fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.55)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              'AARAV250',
                              style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11)),
                          child: Text('Share', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: BasketColors.ink)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (final row in BasketCatalog.accountRows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => cubit.go(row.target),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: glassCard(radius: 15),
                      child: Row(
                        children: [
                          Text(row.icon, style: const TextStyle(fontSize: 15)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(row.title, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text(row.sub, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                              ],
                            ),
                          ),
                          Text('›', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: BasketColors.faint)),
                        ],
                      ),
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
