import 'package:fastswipe/features/basket/cubit/basket_cubit.dart';
import 'package:fastswipe/features/basket/cubit/basket_selectors.dart';
import 'package:fastswipe/features/basket/presentation/basket_colors.dart';
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
          padding: EdgeInsets.fromLTRB(14, MediaQuery.paddingOf(context).top + 8, 14, 14),
          decoration: const BoxDecoration(gradient: BasketColors.headerGradient),
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
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFBF2).withValues(alpha: 0.1),
                    border: Border.all(color: Color(0xFFFFFBF2).withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 16, color: Color(0xFFFFFBF2).withValues(alpha: 0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _text,
                          focusNode: _focus,
                          onChanged: _setQuery,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2)),
                          decoration: InputDecoration(
                            isDense: true,
                            // Unset `filled` inherits the app-wide theme's
                            // near-white fill — on this dark header, that
                            // painted a near-white box behind the white
                            // input text, making it unreadable.
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Search products',
                            hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFFFFFBF2).withValues(alpha: 0.55)),
                          ),
                        ),
                      ),
                      if (hasQuery)
                        GestureDetector(
                          onTap: () {
                            cubit.clearQuery();
                            _text.clear();
                          },
                          child: Icon(Icons.close, size: 16, color: Color(0xFFFFFBF2).withValues(alpha: 0.6)),
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            children: [
              if (!hasQuery) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent searches', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('Clear', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: BasketColors.faint)),
                  ],
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in _recents)
                      _Chip(label: r, filled: false, onTap: () => _setQuery(r)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Trending now', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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
                const SizedBox(height: 11),
                for (final p in results)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: GestureDetector(
                      onTap: () => cubit.openProduct(p.id),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
                          border: Border.all(color: BasketColors.ink.withValues(alpha: 0.07)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            ProductImageMini(size: 56, imageUrl: p.imageUrl),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(p.pack, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w500, color: BasketColors.faint)),
                                  const SizedBox(height: 4),
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
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                  child: Column(
                    children: [
                      Text('No match for "$query"', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      Text(
                        "Check the spelling, or request it and we'll try to stock it within 48 hours.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.6, fontWeight: FontWeight.w500, color: BasketColors.muted),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(color: BasketColors.ink, borderRadius: BorderRadius.circular(12)),
                        child: Text('Request this product', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFFBF2))),
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
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: Color(0xFFFFFBF2).withValues(alpha: 0.7),
          border: Border.all(color: filled ? BasketColors.ink : BasketColors.ink.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: filled ? FontWeight.w700 : FontWeight.w600),
        ),
      ),
    );
  }
}
