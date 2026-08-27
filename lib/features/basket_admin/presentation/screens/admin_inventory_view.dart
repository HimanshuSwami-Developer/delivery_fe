import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/data/basket_admin_data.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFlex = [2.3, 1.0, 1.0, 1.0, 1.4];

const _kStateLabels = {'healthy': 'Healthy', 'low': 'Below reorder', 'out_of_stock': 'Out of stock'};

/// Light red row wash for stock that needs attention — a touch stronger
/// once it's actually hit zero than while it's merely below reorder level.
const _kDanger = Color(0xFFC0392B);
Color? _stockRowTint(String state) => switch (state) {
      'out_of_stock' => _kDanger.withValues(alpha: 0.10),
      'low' => _kDanger.withValues(alpha: 0.055),
      _ => null,
    };

/// Inventory: 4 summary stats + a stock table (per current zone) with
/// inline +/- adjust controls per SKU, calling the real stock-adjust API.
class AdminInventoryView extends StatelessWidget {
  const AdminInventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final zones = context.select((BasketAdminCubit c) => c.state.apiZones);
    final zone = context.select((BasketAdminCubit c) => c.state.zone);
    final zoneLabel = zones.isNotEmpty && zone < zones.length ? zones[zone].name : 'All zones';
    final stocks = context.select((BasketAdminCubit c) => c.state.apiStocks);
    final loading = context.select((BasketAdminCubit c) => c.state.stocksLoading);

    final tracked = stocks.length;
    final belowReorder = stocks.where((s) => s.state == 'low').length;
    final outOfStock = stocks.where((s) => s.state == 'out_of_stock').length;
    final onHandTotal = stocks.fold<int>(0, (a, s) => a + s.onHand);
    final stats = [
      ('SKUs tracked', '$tracked', 'In $zoneLabel'),
      ('Below reorder', '$belowReorder', 'Restock today'),
      ('Out of stock', '$outOfStock', outOfStock == 0 ? 'All clear' : 'Needs attention'),
      ('Units on hand', indianGroup(onHandTotal), 'Across tracked SKUs'),
    ];

    if (loading && stocks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminResponsiveGrid(children: [for (final s in stats) AdminStatCard(label: s.$1, value: s.$2, sub: s.$3)]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            decoration: adminGlassCard(),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 900,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
                      child: Row(
                        children: [
                          Expanded(child: AdminSectionTitle('Stock by SKU · $zoneLabel')),
                          OutlinedButton(
                            onPressed: null,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AdminColors.ink.withValues(alpha: 0.12)),
                              backgroundColor: Colors.white,
                              disabledForegroundColor: AdminColors.ink,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                            ),
                            child: Text('⤓ Stock sheet', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.ink)),
                          ),
                          const SizedBox(width: 9),
                          FilledButton(
                            onPressed: null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AdminColors.ink,
                              disabledBackgroundColor: AdminColors.ink,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                            ),
                            child: Text('Bulk restock', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const AdminTableHeader(flex: _kFlex, labels: ['Product', 'On hand', 'Reserved', 'Reorder at', 'Adjust']),
                    if (stocks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No stock records for this zone yet.', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
                      ),
                    for (final s in stocks) _StockRow(stock: s, cubit: cubit),
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

class _StockRow extends StatelessWidget {
  const _StockRow({required this.stock, required this.cubit});
  final ApiProductStock stock;
  final BasketAdminCubit cubit;

  @override
  Widget build(BuildContext context) {
    final stockFg = stock.state == 'out_of_stock' ? _kDanger : (stock.state == 'healthy' ? AdminColors.ink : AdminColors.muted);

    return AdminTableRow(
      flex: _kFlex,
      backgroundColor: _stockRowTint(stock.state),
      children: [
        Row(
          children: [
            const SizedBox(width: 36, height: 36, child: ImageSlot(shape: ImageSlotShape.rounded, radius: 9, mini: true)),
            const SizedBox(width: 11),
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
              decoration: BoxDecoration(border: Border.all(color: AdminColors.ink, width: 1.3), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => cubit.adjustStock(stock.id, -1),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    onTap: () => cubit.adjustStock(stock.id, 1),
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
