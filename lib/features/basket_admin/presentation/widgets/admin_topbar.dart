import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
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
      padding: EdgeInsets.symmetric(horizontal: narrow ? AdminSpace.md : AdminSpace.xl, vertical: narrow ? AdminSpace.sm : AdminSpace.md),
      decoration: BoxDecoration(
        color: Color(0xFFFFFBF2).withValues(alpha: 0.62),
        border: const Border(bottom: BorderSide(color: AdminSurface.border)),
      ),
      child: Row(
        children: [
          if (narrow) ...[
            AdminIconActionButton(
              icon: Icons.menu_rounded,
              color: AdminColors.ink,
              size: 36,
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: AdminSpace.sm),
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
                  const SizedBox(height: AdminSpace.xxs),
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
