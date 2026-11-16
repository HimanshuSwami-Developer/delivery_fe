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
          const SizedBox(width: AdminSpace.sm),
          const _NewOrdersBell(),
        ],
      ),
    );
  }
}

/// Bell with a red count of orders still in `New` status — visible on
/// every page (including narrow screens, where the sidebar's badge is
/// tucked away in the drawer). Tapping it opens Orders filtered to New.
class _NewOrdersBell extends StatelessWidget {
  const _NewOrdersBell();

  @override
  Widget build(BuildContext context) {
    final count = context.select((BasketAdminCubit c) => c.state.newOrdersCount);
    return Tooltip(
      message: count == 0 ? 'No new orders' : '$count new ${count == 1 ? 'order' : 'orders'}',
      child: InkWell(
        onTap: context.read<BasketAdminCubit>().goNewOrders,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                count > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                size: 22,
                color: AdminColors.ink,
              ),
              if (count > 0)
                Positioned(
                  top: 2,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AdminSurface.error,
                      borderRadius: BorderRadius.circular(AdminRadius.pill),
                      border: Border.all(color: const Color(0xFFFFFBF2), width: 1.5),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFFFFBF2)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
