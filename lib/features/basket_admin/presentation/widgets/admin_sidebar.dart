import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dark 238px-wide rail: logo, the full [kAdminNav] list (section headings
/// + routable links with icon/badge), and a profile row with a sign-out
/// action — ported from the source design's left sidebar.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final activePage = context.select((BasketAdminCubit c) => navHighlightFor(c.state.page));

    return Container(
      width: 238,
      color: AdminColors.ink,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            child: Row(
              children: [
                Text('basket', style: GoogleFonts.manrope(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(width: 9),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                  child: Text(
                    'ADMIN',
                    style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w700, color: AdminColors.ink, letterSpacing: 1.4),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final entry in kAdminNav)
                  entry.isHeading
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(10, 16, 10, 7),
                          child: Text(
                            entry.label.toUpperCase(),
                            style: GoogleFonts.manrope(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.32),
                              letterSpacing: 1.1,
                            ),
                          ),
                        )
                      : _NavLink(entry: entry, active: entry.page == activePage, onTap: () => cubit.go(entry.page!)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 2),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1)))),
            child: Row(
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: ImageSlot(shape: ImageSlotShape.circle, mini: true),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Builder(builder: (context) {
                    final name = context.select((BasketAdminCubit c) => c.state.adminName);
                    final mobile = context.select((BasketAdminCubit c) => c.state.adminMobile);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (name != null && name.isNotEmpty) ? name : (mobile ?? 'Admin'),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text('Ops lead', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.45))),
                      ],
                    );
                  }),
                ),
                TextButton(
                  onPressed: cubit.signOut,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text('Exit', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.5))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.entry, required this.active, required this.onTap});

  final AdminNavEntry entry;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : Colors.white.withValues(alpha: 0.62);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: [
                SizedBox(width: 18, child: Text(entry.icon, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: fg))),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(entry.label, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
                ),
                if (entry.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                    child: Text(
                      entry.badge!,
                      style: GoogleFonts.manrope(fontSize: 9.5, fontWeight: FontWeight.w800, color: AdminColors.ink),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
