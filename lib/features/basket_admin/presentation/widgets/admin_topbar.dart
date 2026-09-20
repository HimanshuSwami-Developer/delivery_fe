import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sticky header: page title/subtitle, plus a hamburger button on narrow
/// screens.
///
/// [narrow] (screen width < 900, matching `AdminLoginView`'s own threshold)
/// drops the sidebar into a `Drawer` — see `_AdminRoot` — so this bar grows
/// a hamburger button to open it. On the desktop width this was built for,
/// only the subtitle line drops.
class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key, required this.narrow});
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final page = context.select((BasketAdminCubit c) => c.state.page);
    final title = kAdminTitles[page]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: narrow ? 14 : 26, vertical: narrow ? 12 : 18),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBF2).withValues(alpha: 0.62),
        border: Border(bottom: BorderSide(color: AdminColors.ink.withValues(alpha: 0.07))),
      ),
      child: Row(
        children: [
          if (narrow) ...[
            InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: AdminColors.ink.withValues(alpha: 0.12)), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_rounded, size: 18, color: AdminColors.ink),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: narrow ? 16 : 20, fontWeight: FontWeight.w800, color: AdminColors.ink, letterSpacing: -0.3),
                ),
                if (!narrow) ...[
                  const SizedBox(height: 4),
                  Text(title.subtitle, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
