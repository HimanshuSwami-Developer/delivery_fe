import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/features/basket/presentation/widgets/image_slot.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

/// A file-upload photo field for every admin form that needs one (category,
/// subcategory, product, banner). Replaces the old "paste an image URL"
/// text field: picking a file uploads it straight to Cloudinary via
/// `CatalogRepository.uploadImage` and [onChanged] fires with the resulting
/// `secure_url`, which is what the form actually submits.
class AdminImagePicker extends StatefulWidget {
  const AdminImagePicker({
    super.key,
    required this.imageUrl,
    required this.onChanged,
    this.label = 'Photo',
  });

  /// The currently-saved image URL (empty if none yet).
  final String imageUrl;

  /// Fires with the newly-uploaded `secure_url` once the upload finishes.
  final ValueChanged<String> onChanged;

  final String label;

  @override
  State<AdminImagePicker> createState() => _AdminImagePickerState();
}

class _AdminImagePickerState extends State<AdminImagePicker> {
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
      if (mounted) widget.onChanged(url);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.muted)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: widget.imageUrl.isEmpty
                    ? const ImageSlot(radius: 12)
                    : Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const ImageSlot(radius: 12),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: _uploading ? null : _pickAndUpload,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AdminColors.ink, width: 1.3),
                      foregroundColor: AdminColors.ink,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            widget.imageUrl.isEmpty ? 'Upload photo' : 'Replace photo',
                            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(_error!, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFC0392B))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
