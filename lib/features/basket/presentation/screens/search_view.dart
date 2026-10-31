import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
import 'package:fastswipe/features/basket/presentation/basket_ui.dart';
import 'package:fastswipe/features/basket/presentation/widgets/add_qty_control.dart';
import 'package:fastswipe/features/basket/presentation/widgets/product_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _recents = ['amul butter', 'toor dal', 'curd', 'eggs'];
const _trending = ['mango', 'atta 5kg', 'maggi', 'paneer'];

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  late final TextEditingController _text =
      TextEditingController(text: context.read<BasketCubit>().state.query);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setQuery(String q) {
    context.read<BasketCubit>().setQuery(q);
    if (_text.text != q) {
      _text.value = TextEditingValue(text: q, selection: TextSelection.collapsed(offset: q.length));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketCubit>();
    final query = context.select((BasketCubit c) => c.state.query);
    final results = context.select((BasketCubit c) => searchResults(c.state));
    final hasQuery = query.isNotEmpty;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(BasketSpace.gutter, MediaQuery.paddingOf(context).top + BasketSpace.xs, BasketSpace.gutter, BasketSpace.sm),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient),
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
              const SizedBox(width: BasketSpace.sm),
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm),
                  decoration: BoxDecoration(
                    color: BasketSurface.card,
                    border: Border.all(color: BasketSurface.borderStrong),
                    borderRadius: BasketRadius.input,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: BasketColors.muted),
                      const SizedBox(width: BasketSpace.xs),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          onChanged: _setQuery,
                          cursorColor: BasketColors.primary,
                          style: basketInputText(),
                          decoration: InputDecoration(
                            isDense: true,
                            // The white pill around this field is the
                            // search bar's own box — don't let the theme's
                            // filled/outlined input paint a second one.
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Search products',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: BasketColors.faint),
                          ),
                        ),
                      ),
                      if (hasQuery)
                        GestureDetector(
                          onTap: () {
                            cubit.clearQuery();
                            _text.clear();
                          },
                          child: Icon(Icons.close, size: 16, color: BasketColors.muted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(BasketSpace.gutter, BasketSpace.md, BasketSpace.gutter, 90),
            children: [
              if (!hasQuery) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent searches', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('Clear', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: BasketColors.faint)),
                  ],
                ),
                const SizedBox(height: BasketSpace.sm),
                Wrap(
                  spacing: BasketSpace.xs,
                  runSpacing: BasketSpace.xs,
                  children: [
                    for (final r in _recents)
                      _Chip(label: r, filled: false, onTap: () => _setQuery(r)),
                  ],
                ),
                const SizedBox(height: BasketSpace.xl),
                Text('Trending now', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: BasketSpace.sm),
                Wrap(
                  spacing: BasketSpace.xs,
                  runSpacing: BasketSpace.xs,
                  children: [
                    for (final r in _trending)
                      _Chip(label: r, filled: true, onTap: () => _setQuery(r)),
                  ],
                ),
              ] else if (results.isNotEmpty) ...[
                Text(
                  '${results.length} results for "$query"',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: BasketColors.faint),
                ),
                const SizedBox(height: BasketSpace.sm),
                for (final p in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BasketSpace.section),
                    child: GestureDetector(
                      onTap: () => cubit.openProduct(p.id),
                      child: Container(
                        padding: const EdgeInsets.all(BasketSpace.sm),
                        decoration: basketCard(),
                        child: Row(
                          children: [
                            ProductImageMini(size: 56, imageUrl: p.imageUrl),
                            const SizedBox(width: BasketSpace.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(p.pack, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                                  const SizedBox(height: BasketSpace.xxs),
                                  Text(moneyLabel(p.price), style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                            AddQtyControl(product: p),
                          ],
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: BasketSpace.sm),
                  child: Column(
                    children: [
                      Text('No match for "$query"', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: BasketSpace.xs),
                      Text(
                        "Check the spelling, or request it and we'll try to stock it within 48 hours.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                      ),
                      const SizedBox(height: 16),
                      // No request flow exists yet — this was (and stays) a
                      // visual-only CTA, so the callback is a no-op rather
                      // than null (null would render it greyed-out/disabled).
                      BasketButton(
                        label: 'Request this product',
                        size: BasketButtonSize.medium,
                        expand: false,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.filled, required this.onTap});

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: BasketSpace.sm, vertical: BasketSpace.xs),
        decoration: BoxDecoration(
          color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
          border: Border.all(color: filled ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(BasketRadius.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: filled ? FontWeight.w700 : FontWeight.w600),
        ),
      ),
    );
  }
}
