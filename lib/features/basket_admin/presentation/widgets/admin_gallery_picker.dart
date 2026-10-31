import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// One PDP gallery photo. [id] is the backend `ProductImage` row's id once
/// it's been saved — null for a freshly-uploaded photo that only exists in
/// this form's draft state until "Save" is pressed (see
/// `AdminProductNewView._submit`, which diffs against the id-bearing
/// originals to know what to create/delete).
typedef GalleryImage = ({int? id, String url});

/// Multi-photo companion to [AdminImagePicker]'s single "Main image" field —
/// these extra photos become the PDP's swipeable gallery. Purely a draft
/// editor: picking a file uploads it to Cloudinary immediately (same as
/// [AdminImagePicker]), but linking/unlinking it to the product is deferred
/// to the parent form's Save, same as every other field here.
class AdminGalleryPicker extends StatefulWidget {
  const AdminGalleryPicker({
    super.key,
    required this.images,
    required this.onChanged,
    this.label = 'Gallery images',
  });

  final List<GalleryImage> images;
  final ValueChanged<List<GalleryImage>> onChanged;
  final String label;

  @override
  State<AdminGalleryPicker> createState() => _AdminGalleryPickerState();
}

class _AdminGalleryPickerState extends State<AdminGalleryPicker> {
  bool _uploading = false;
  String? _error;

  Future<void> _pickAndUpload() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (!mounted || file == null) return;

    final cubit = context.read<BasketAdminCubit>();
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final bytes = await file.readAsBytes();
      final url = await cubit.api.catalog.uploadImage(bytes, file.name);
      if (mounted) widget.onChanged([...widget.images, (id: null, url: url)]);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _remove(int index) {
    final next = [...widget.images]..removeAt(index);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel(widget.label),
        Wrap(
          spacing: AdminSpace.sm,
          runSpacing: AdminSpace.sm,
          children: [
            for (var i = 0; i < widget.images.length; i++)
              _GalleryThumb(url: widget.images[i].url, onRemove: () => _remove(i)),
            _AddTile(uploading: _uploading, onTap: _uploading ? null : _pickAndUpload),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AdminSpace.xs),
          Text(_error!, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AdminSurface.error)),
        ],
        const SizedBox(height: AdminSpace.xs),
        Text(
          'Shown as a swipeable gallery on the product detail page, alongside the main image above.',
          style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w500, height: 1.5, color: AdminColors.faint),
        ),
      ],
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  const _GalleryThumb({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AdminRadius.sm),
          child: Image.network(
            url,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(width: 64, height: 64, color: AdminColors.card),
          ),
        ),
        Positioned(
          top: -AdminSpace.xs,
          right: -AdminSpace.xs,
          child: InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(AdminRadius.pill),
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(color: AdminColors.ink, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 12, color: Color(0xFFFFFBF2)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.uploading, required this.onTap});

  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminRadius.sm),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AdminSurface.card,
          border: Border.all(color: AdminSurface.borderStrong),
          borderRadius: BorderRadius.circular(AdminRadius.sm),
        ),
        alignment: Alignment.center,
        child: uploading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(Icons.add, color: AdminColors.ink.withValues(alpha: 0.6)),
      ),
    );
  }
}
