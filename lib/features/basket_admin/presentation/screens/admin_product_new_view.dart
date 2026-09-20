import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/core/basket_api/models/catalog_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_gallery_picker.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kGstSlabs = ['0', '5', '12', '18'];

/// Add/edit product — [BasketAdminState.currentProduct] (set by
/// `goProductNew`, read once at `initState`) says which mode: null seeds a
/// blank draft and calls `createProduct`, non-null seeds every field from
/// that product and calls `updateProduct`. Every field here is a real,
/// editable control bound to [ProductWriteSerializer]'s shape — this used
/// to be a static mock of "Aashirvaad Shudh Chakki Atta" where every row's
/// "open" action landed on the same prefilled draft and "Save" just
/// navigated back without persisting anything.
class AdminProductNewView extends StatefulWidget {
  const AdminProductNewView({super.key});

  @override
  State<AdminProductNewView> createState() => _AdminProductNewViewState();
}

class _AdminProductNewViewState extends State<AdminProductNewView> {
  late final ApiProduct? _editing = context.read<BasketAdminCubit>().state.currentProduct;

  late final _name = TextEditingController(text: _editing?.name ?? '');
  late final _brand = TextEditingController(text: _editing?.brand ?? '');
  late final _pack = TextEditingController(text: _editing?.pack ?? '');
  late final _sku = TextEditingController(text: _editing?.sku ?? '');
  late final _hsnCode = TextEditingController(text: _editing?.hsnCode ?? '');
  late final _description = TextEditingController(text: _editing?.description ?? '');
  late final _mrp = TextEditingController(text: _editing == null ? '' : '${_editing.mrp}');
  late final _price = TextEditingController(text: _editing == null ? '' : '${_editing.price}');
  late final _costPrice = TextEditingController();
  late final _initialStock = TextEditingController();
  late String _mainImageUrl = _editing?.mainImageUrl ?? '';

  int? _categoryId;
  bool _categoryInitialized = false;
  late String _gstSlab = _editing?.gstSlab ?? '5';
  late bool _outOfStock = _editing?.isOutOfStock ?? false;

  bool _loading = false;
  String? _error;

  /// Gallery photos beyond the main image — [_editing] comes from the
  /// products list (`ProductListSerializer`, no `images`), so on edit we
  /// fetch the full detail once here to seed this and [_initialGalleryIds]
  /// (the latter is what `_submit` diffs against to know which existing
  /// `ProductImage` rows were removed).
  List<GalleryImage> _gallery = [];
  List<int> _initialGalleryIds = [];

  @override
  void initState() {
    super.initState();
    if (_editing != null) {
      context.read<BasketAdminCubit>().api.catalog.fetchProduct(_editing.id).then((full) {
        if (!mounted) return;
        setState(() {
          _gallery = [for (final img in full.images) (id: img.id, url: img.imageUrl)];
          _initialGalleryIds = [for (final g in _gallery) g.id!];
        });
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _pack.dispose();
    _sku.dispose();
    _hsnCode.dispose();
    _description.dispose();
    _mrp.dispose();
    _price.dispose();
    _costPrice.dispose();
    _initialStock.dispose();
    super.dispose();
  }

  Future<void> _submit(BasketAdminCubit cubit) async {
    final name = _name.text.trim();
    final pack = _pack.text.trim();
    final sku = _sku.text.trim();
    final mrp = int.tryParse(_mrp.text.trim());
    final price = int.tryParse(_price.text.trim());
    if (name.isEmpty || pack.isEmpty || sku.isEmpty || _categoryId == null || mrp == null || price == null) {
      setState(() => _error = 'Name, category, pack, SKU, MRP and price are all required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = {
        'name': name,
        'brand': _brand.text.trim(),
        'category': _categoryId,
        'pack': pack,
        'sku': sku,
        'hsn_code': _hsnCode.text.trim(),
        'description': _description.text.trim(),
        'mrp': mrp,
        'price': price,
        'cost_price': int.tryParse(_costPrice.text.trim()),
        'gst_slab': _gstSlab,
        'is_out_of_stock': _outOfStock,
        'main_image_url': _mainImageUrl,
        // Only meaningful at creation — the backend ignores it on update,
        // since editing stock afterward goes through the Inventory screen.
        if (_editing == null) 'initial_stock': int.tryParse(_initialStock.text.trim()) ?? 0,
      };
      final product = _editing == null
          ? await cubit.createProduct(data)
          : await cubit.updateProduct(_editing.id, data);

      final keptIds = {for (final g in _gallery) if (g.id != null) g.id!};
      for (final removedId in _initialGalleryIds.where((id) => !keptIds.contains(id))) {
        await cubit.api.catalog.deleteProductImage(removedId);
      }
      for (var i = 0; i < _gallery.length; i++) {
        if (_gallery[i].id == null) {
          await cubit.api.catalog.addProductImage(product.id, _gallery[i].url, order: i);
        }
      }

      if (mounted) cubit.goProducts();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    final categories = context.select((BasketAdminCubit c) => c.state.apiCategories);

    if (!_categoryInitialized && categories.isNotEmpty) {
      _categoryId = _editing?.categoryId ?? categories.first.id;
      _categoryInitialized = true;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: cubit.goProducts,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('← All products', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.muted)),
          ),
          const SizedBox(height: 14),
          Text(
            _editing == null ? 'Add product' : 'Edit ${_editing.name}',
            style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 900;

            final left = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle('Product details'),
                      const SizedBox(height: 14),
                      AdminEditField(label: 'Product name', controller: _name, hint: 'Aashirvaad Shudh Chakki Atta'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: AdminEditField(label: 'Brand', controller: _brand, hint: 'Aashirvaad')),
                          const SizedBox(width: 12),
                          Expanded(
                            child: categories.isEmpty
                                ? const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Loading categories…'))
                                : AdminEditDropdown<int>(
                                    label: 'Category',
                                    value: _categoryId,
                                    items: [for (final c in categories) c.id],
                                    itemLabel: (id) => categories.firstWhere((c) => c.id == id).name,
                                    onChanged: (v) => setState(() => _categoryId = v),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: AdminEditField(label: 'Pack size', controller: _pack, hint: '5 kg')),
                          const SizedBox(width: 12),
                          Expanded(child: AdminEditField(label: 'SKU code', controller: _sku, hint: 'SKU-1042')),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AdminEditField(
                        label: 'Description',
                        controller: _description,
                        hint: '100% whole wheat atta, chakki-ground for soft rotis.',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AdminSectionTitle('Pricing & tax'),
                      const SizedBox(height: 14),
                      AdminResponsiveGrid(
                        minTileWidth: 130,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          AdminEditField(label: 'MRP', controller: _mrp, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                          AdminEditField(label: 'Selling price', controller: _price, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                          AdminEditField(label: 'Cost price (opt.)', controller: _costPrice, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                          AdminEditField(label: 'HSN code', controller: _hsnCode, hint: '1101'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 9,
                        runSpacing: 9,
                        children: [
                          for (final g in _kGstSlabs)
                            AdminPillButton(label: 'GST $g%', selected: _gstSlab == g, onTap: () => setState(() => _gstSlab = g)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );

            final right = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Image', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      AdminImagePicker(
                        label: 'Main image',
                        imageUrl: _mainImageUrl,
                        onChanged: (url) => setState(() => _mainImageUrl = url),
                      ),
                      const SizedBox(height: 16),
                      AdminGalleryPicker(
                        images: _gallery,
                        onChanged: (v) => setState(() => _gallery = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: adminGlassCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Availability', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 13),
                      InkWell(
                        onTap: () => setState(() => _outOfStock = !_outOfStock),
                        child: Row(
                          children: [
                            AdminToggle(on: !_outOfStock, onTap: () => setState(() => _outOfStock = !_outOfStock)),
                            const SizedBox(width: 10),
                            Text(
                              _outOfStock ? 'Out of stock' : 'In stock',
                              style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: AdminColors.ink),
                            ),
                          ],
                        ),
                      ),
                      if (_editing == null) ...[
                        const SizedBox(height: 14),
                        AdminEditField(
                          label: 'Initial quantity',
                          controller: _initialStock,
                          hint: '0',
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sets the Inventory on-hand count right away — leave blank to start at 0. '
                          'Later restocks are managed from the Inventory page.',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: AdminColors.faint),
                        ),
                      ] else ...[
                        const SizedBox(height: 6),
                        Text(
                          'Stock levels are managed on the Inventory page.',
                          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: AdminColors.faint),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : () => _submit(cubit),
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFFFBF2))),
                          )
                        : Text(
                            _editing == null ? 'Save product' : 'Save changes',
                            style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFFFFBF2)),
                          ),
                  ),
                ),
              ],
            );

            if (narrow) {
              return Column(children: [left, const SizedBox(height: 14), right]);
            }
            // Plain Row, not `IntrinsicHeight` — `left` contains
            // `AdminResponsiveGrid`, which uses `LayoutBuilder` internally,
            // and `IntrinsicHeight` can't compute intrinsic dimensions
            // through a `LayoutBuilder` (throws "RenderBox was not laid
            // out"). `CrossAxisAlignment.start` never stretched the columns
            // to match heights anyway, so nothing is lost by dropping it.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 160, child: left),
                const SizedBox(width: 14),
                Expanded(flex: 100, child: right),
              ],
            );
          }),
        ],
      ),
    );
  }
}
