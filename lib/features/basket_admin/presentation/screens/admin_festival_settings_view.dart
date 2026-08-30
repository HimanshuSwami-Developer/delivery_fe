import 'package:fastswipe/core/basket_api/models/promotion_models.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

const _kFestivalLabels = {
  'diwali': 'Diwali',
  'holi': 'Holi',
  'christmas': 'Christmas',
  'new_year': 'New Year',
  'independence_day': 'Independence / Republic Day',
  'raksha_bandhan': 'Raksha Bandhan',
};

const _kOverrideModeLabels = {'auto': 'Auto — by date', 'force_on': 'Always on', 'force_off': 'Always off'};

const _kMotifLabels = {
  'diyaLights': 'Diya / string lights',
  'colorSplash': 'Colour splash',
  'snowfall': 'Snowfall',
  'confetti': 'Confetti',
};

Color _swatch(String hex) {
  final cleaned = hex.replaceFirst('#', '');
  final value = cleaned.length == 6 ? int.tryParse('FF$cleaned', radix: 16) : null;
  return value == null ? AdminColors.faint : Color(value);
}

/// One row per festival — a fixed set seeded server-side (see
/// `promotions/migrations/0005_seed_festival_settings.py`), so unlike
/// banners there's no "add new"/"delete" here, only "edit". Colours/motif/
/// text here drive the customer app's home-header takeover and popup — see
/// `FestivalCalendar` on the Flutter side.
class AdminFestivalSettingsView extends StatelessWidget {
  const AdminFestivalSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.select((BasketAdminCubit c) => c.state.apiFestivalSettings);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('Festival themes'),
          const SizedBox(height: 4),
          Text(
            'Auto-activates on each festival\'s calendar window unless overridden below.',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w500, color: AdminColors.muted),
          ),
          const SizedBox(height: 14),
          if (settings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text('Loading…', style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.muted)),
            ),
          AdminResponsiveGrid(
            minTileWidth: 300,
            children: [for (final s in settings) _FestivalCard(setting: s)],
          ),
        ],
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.setting});

  final ApiFestivalSetting setting;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BasketAdminCubit>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: adminGlassCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _kFestivalLabels[setting.key] ?? setting.key,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              AdminChipBadge(_kOverrideModeLabels[setting.overrideMode] ?? setting.overrideMode),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ColorDot(_swatch(setting.gradientStart)),
              const SizedBox(width: 4),
              _ColorDot(_swatch(setting.gradientEnd)),
              const SizedBox(width: 8),
              _ColorDot(_swatch(setting.accentColor), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _kMotifLabels[setting.motif] ?? setting.motif,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            setting.greetingText.isEmpty ? '(no greeting text set)' : setting.greetingText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w500, height: 1.4, color: AdminColors.muted),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(setting.popupEnabled ? Icons.chat_bubble_outline_rounded : Icons.speaker_notes_off_outlined, size: 13, color: AdminColors.faint),
              const SizedBox(width: 4),
              Text(
                setting.popupEnabled ? 'Popup on open: on' : 'Popup on open: off',
                style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.faint),
              ),
            ],
          ),
          if (setting.startsOn != null && setting.endsOn != null) ...[
            const SizedBox(height: 4),
            Text(
              '${_fmtDate(setting.startsOn!)} → ${_fmtDate(setting.endsOn!)}',
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.faint),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => cubit.openEditFestivalSetting(setting),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AdminColors.ink, width: 1.3),
                foregroundColor: AdminColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
              ),
              child: Text('Edit', style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: AdminColors.ink)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color, {this.size = 14});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: AdminColors.ink.withValues(alpha: 0.12))),
    );
  }
}

String _fmtDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
