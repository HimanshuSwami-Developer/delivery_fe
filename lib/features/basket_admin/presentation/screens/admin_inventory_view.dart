import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFlex = [2.3, 1.0, 1.0, 1.0, 1.4];

const _kStateLabels = {'healthy': 'Healthy', 'low': 'Below reorder', 'out_of_stock': 'Out of stock'};

const _kStateChips = [
  (null, 'All states'),
  ('healthy', 'Healthy'),
  ('low', 'Below reorder'),
  ('out_of_stock', 'Out of stock'),
];

/// Light red row wash for stock that needs attention — a touch stronger
/// once it's actually hit zero than while it's merely below reorder level.
const _kDanger = AdminSurface.error;
Color? _stockRowTint(String state) => switch (state) {
      'out_of_stock' => _kDanger.withValues(alpha: 0.10),
      'low' => _kDanger.withValues(alpha: 0.055),
      _ => null,
    };

/// Inventory: 4 store-wide summary stats (independent of whatever's
/// filtered/paginated below), category tabs + a stock-state filter + search,
/// and a paginated stock table with inline +/- adjust controls calling the
/// real stock-adjust API.
class AdminInventoryView extends StatefulWidget {
  const AdminInventoryView({super.key});

  @override
  State<AdminInventoryView> createState() => _AdminInventoryViewState();
}

class _AdminInventoryViewState extends State<AdminInventoryView> {
  late final _search = TextEditingController(text: context.read<BasketAdminCubit>().state.stockSearch);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final categories = context.select((BasketAdminCubit c) => c.state.apiCategories);
    final catTab = context.select((BasketAdminCubit c) => c.state.stockCatTab);
    final stateFilter = context.select((BasketAdminCubit c) => c.state.stockState);
    final stocks = context.select((BasketAdminCubit c) => c.state.apiStocks);
    final loading = context.select((BasketAdminCubit c) => c.state.stocksLoading);
    final summary = context.select((BasketAdminCubit c) => c.state.stockSummary);
    final page = context.select((BasketAdminCubit c) => c.state.stockPage);
    final count = context.select((BasketAdminCubit c) => c.state.stockCount);

    final stats = [
      ('SKUs tracked', summary == null ? '—' : '${summary.tracked}', 'In your store'),
      ('Below reorder', summary == null ? '—' : '${summary.belowReorder}', 'Restock today'),
      (
        'Out of stock',
        summary == null ? '—' : '${summary.outOfStock}',
        summary != null && summary.outOfStock == 0 ? 'All clear' : 'Needs attention',
      ),
      ('Units on hand', summary == null ? '—' : indianGroup(summary.onHandTotal), 'Across tracked SKUs'),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminResponsiveGrid(children: [for (final s in stats) AdminStatCard(label: s.$1, value: s.$2, sub: s.$3)]),
          const SizedBox(height: AdminSpace.section),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: AdminSpace.xs,
                  runSpacing: AdminSpace.xs,
                  children: [
                    AdminPillButton(label: 'All', selected: catTab == 'All', onTap: () => cubit.setStockCatTab('All')),
                    for (final c in categories) AdminPillButton(label: c.name, selected: catTab == c.key, onTap: () => cubit.setStockCatTab(c.key)),
                  ],
                ),
              ),
              const SizedBox(width: AdminSpace.xs),
              SizedBox(width: 220, child: _SearchField(controller: _search, onChanged: cubit.setStockSearch)),
            ],
          ),
          const SizedBox(height: AdminSpace.sm),
          Wrap(
            spacing: AdminSpace.xs,
            runSpacing: AdminSpace.xs,
            children: [
              for (final chip in _kStateChips)
                AdminPillButton(label: chip.$2, selected: stateFilter == chip.$1, onTap: () => cubit.setStockStateFilter(chip.$1)),
            ],
          ),
          const SizedBox(height: AdminSpace.section),
          Container(
            padding: const EdgeInsets.all(AdminSpace.md),
            decoration: adminCard(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AdminSpace.sm, AdminSpace.xxs, AdminSpace.sm, AdminSpace.sm),
                      child: Row(
                        children: [
                          const Expanded(child: AdminSectionTitle('Stock by SKU')),
                          const AdminButton.secondary(label: '⤓ Stock sheet', onPressed: null),
                          const SizedBox(width: AdminSpace.xs),
                          const AdminButton(label: 'Bulk restock', onPressed: null),
                        ],
                      ),
                    ),
                    const AdminTableHeader(flex: _kFlex, labels: ['Product', 'On hand', 'Reserved', 'Reorder at', 'Adjust']),
                    if (loading && stocks.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(vertical: AdminSpace.xxl), child: Center(child: CircularProgressIndicator()))
                    else if (stocks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: AdminSpace.lg),
                        child: Text('No stock records match your filters.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                      )
                    else
                      for (final s in stocks) _StockRow(stock: s),
                    if (count > 0) ...[
                      const SizedBox(height: 4),
                      _PaginationBar(page: page, count: count, onPageChanged: cubit.goToStockPage),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      cursorColor: AdminColors.ink,
      style: adminInputText(),
      decoration: adminInputDecoration(
        hintText: 'Search name or SKU',
        prefixIcon: const Icon(Icons.search, size: 18),
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({required this.page, required this.count, required this.onPageChanged});
  final int page;
  final int count;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = ((count - 1) ~/ BasketAdminCubit.stockPageSize) + 1;
    final start = (page - 1) * BasketAdminCubit.stockPageSize + 1;
    final end = (page * BasketAdminCubit.stockPageSize).clamp(0, count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AdminSpace.sm, AdminSpace.sm, AdminSpace.sm, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing $start–$end of $count',
              style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w600, color: AdminColors.muted),
            ),
          ),
          AdminIconActionButton(icon: Icons.chevron_left, onTap: page > 1 ? () => onPageChanged(page - 1) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('Page $page of $totalPages', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
          AdminIconActionButton(icon: Icons.chevron_right, onTap: page < totalPages ? () => onPageChanged(page + 1) : null),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.stock});
  final ApiProductStock stock;

  Future<void> _adjust(BuildContext context, int delta) async {
    try {
      await context.read<BasketAdminCubit>().adjustStock(stock.id, delta);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockFg = stock.state == 'out_of_stock' ? _kDanger : (stock.state == 'healthy' ? AdminColors.ink : AdminColors.muted);

    return AdminTableRow(
      flex: _kFlex,
      backgroundColor: _stockRowTint(stock.state),
      children: [
        Row(
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: stock.mainImageUrl.isEmpty
                  ? const ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.sm, mini: true)
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AdminRadius.sm),
                      child: Image.network(
                        stock.mainImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ImageSlot(shape: ImageSlotShape.rounded, radius: AdminRadius.sm, mini: true),
                      ),
                    ),
            ),
            const SizedBox(width: AdminSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(stock.productName, overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('${stock.sku} · ${stock.pack}',
                      overflow: TextOverflow.ellipsis, style: GoogleFonts.manrope(fontSize: 10.5, fontWeight: FontWeight.w500, color: AdminColors.faint)),
                ],
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${stock.onHand} u', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800, color: stockFg)),
            const SizedBox(height: 2),
            Text(_kStateLabels[stock.state] ?? stock.state,
                style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: stock.state == 'healthy' ? AdminColors.faint : stockFg)),
          ],
        ),
        Text('${stock.reserved} u', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Text('${stock.reorderLevel} u', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
        Row(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AdminSurface.card,
                border: Border.all(color: AdminSurface.borderStrong),
                borderRadius: BorderRadius.circular(AdminRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _adjust(context, -1),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(AdminRadius.sm)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: AdminSpace.xs),
                      child: Text('−', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text(
                      '${stock.onHand}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                  InkWell(
                    onTap: () => _adjust(context, 1),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(AdminRadius.sm)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AdminSpace.sm, vertical: AdminSpace.xs),
                      child: Text('+', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
