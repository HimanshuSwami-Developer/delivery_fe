import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/data/basket_enums.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class _NavTab {
  const _NavTab(this.screen, this.label, this.icon);
  final BasketScreen screen;
  final String label;
  final IconData icon;
}

const _tabs = [
  _NavTab(BasketScreen.home, 'Home', Icons.home_rounded),
  _NavTab(BasketScreen.cats, 'Categories', Icons.grid_view_rounded),
  _NavTab(BasketScreen.cart, 'Basket', Icons.shopping_basket_rounded),
  _NavTab(BasketScreen.account, 'Account', Icons.person_rounded),
];

/// Bottom nav shared across the shopping shell. Tapping a tab resets the
/// internal back-stack (`prev: []`), matching the source design exactly —
/// this is not `go_router` navigation.
class BasketBottomNav extends StatelessWidget {
  const BasketBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = context.select((BasketCubit c) => c.state.screen);
    final count = context.select((BasketCubit c) => cartTotals(c.state).itemCount);

    return DecoratedBox(
      decoration: const BoxDecoration(color: BasketColors.ink),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 11, 8, 10),
          child: Row(
            children: [
              for (final tab in _tabs)
                Expanded(
                  child: _NavItem(
                    icon: tab.icon,
                    label: tab.screen == BasketScreen.cart && count > 0
                        ? '${tab.label} ($count)'
                        : tab.label,
                    selected: screen == tab.screen,
                    onTap: () => context.read<BasketCubit>().goReset(tab.screen),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? BasketColors.primary : Colors.white.withValues(alpha: 0.45);
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
