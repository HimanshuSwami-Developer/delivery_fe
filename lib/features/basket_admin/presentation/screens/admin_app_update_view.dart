import 'package:fastswipe/core/api/api_exception.dart';
import 'package:fastswipe/features/basket_admin/cubit/basket_admin_cubit.dart';
import 'package:fastswipe/features/basket_admin/presentation/admin_ui.dart';
import 'package:fastswipe/features/basket_admin/presentation/basket_admin_style.dart';
import 'package:fastswipe/features/basket_admin/presentation/widgets/admin_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// "App updates": edits the singleton `AppUpdateConfig` (`GET/PATCH
/// /app-update/`) that the customer app's `AppUpdateGate` checks on launch
/// and every time it comes back to the foreground.
///
/// - Optional (manual) update: builds below its version code get an
///   "Update / Later" popup.
/// - Force update: builds below its version code are blocked until they
///   update.
///
/// A switched-off mode is saved as 0, which the app treats as "never".
/// Android only — the version code is the `+N` in pubspec's `version:`.
class AdminAppUpdateView extends StatefulWidget {
  const AdminAppUpdateView({super.key});

  @override
  State<AdminAppUpdateView> createState() => _AdminAppUpdateViewState();
}

class _AdminAppUpdateViewState extends State<AdminAppUpdateView> {
  final _optionalCode = TextEditingController();
  final _forceCode = TextEditingController();
  final _title = TextEditingController();
  final _message = TextEditingController();
  bool _optionalOn = false;
  bool _forceOn = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _loaded;
  String? _thisBuild;
  int? _thisBuildCode;

  @override
  void initState() {
    super.initState();
    for (final c in [_optionalCode, _forceCode, _title, _message]) {
      c.addListener(() => setState(() {}));
    }
    _load();
    PackageInfo.fromPlatform().then((info) {
      if (!mounted) return;
      setState(() {
        _thisBuildCode = int.tryParse(info.buildNumber);
        _thisBuild = '${info.version} (build ${info.buildNumber})';
      });
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _optionalCode.dispose();
    _forceCode.dispose();
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await context.read<BasketAdminCubit>().api.client.dio.get('/app-update/');
      if (!mounted) return;
      _fill(Map<String, dynamic>.from(res.data as Map));
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fill(Map<String, dynamic> d) {
    final latest = (d['latest_version_code'] as num?)?.toInt() ?? 0;
    final min = (d['min_version_code'] as num?)?.toInt() ?? 0;
    setState(() {
      _loaded = d;
      _optionalOn = latest > 0;
      _forceOn = min > 0;
      _optionalCode.text = latest > 0 ? '$latest' : '';
      _forceCode.text = min > 0 ? '$min' : '';
      _title.text = (d['title'] as String?) ?? '';
      _message.text = (d['message'] as String?) ?? '';
    });
  }

  int get _optional => _optionalOn ? (int.tryParse(_optionalCode.text.trim()) ?? 0) : 0;
  int get _force => _forceOn ? (int.tryParse(_forceCode.text.trim()) ?? 0) : 0;

  /// Why Save is blocked, or null when the form is valid.
  String? get _problem {
    if (_optionalOn && _optional <= 0) return 'Enter a version code for the optional update, or switch it off.';
    if (_forceOn && _force <= 0) return 'Enter a version code for the force update, or switch it off.';
    return null;
  }

  bool get _dirty {
    final l = _loaded;
    if (l == null) return false;
    return _optional != ((l['latest_version_code'] as num?)?.toInt() ?? 0) ||
        _force != ((l['min_version_code'] as num?)?.toInt() ?? 0) ||
        _title.text.trim() != ((l['title'] as String?) ?? '') ||
        _message.text.trim() != ((l['message'] as String?) ?? '');
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await context.read<BasketAdminCubit>().api.client.dio.patch('/app-update/', data: {
        // A build below the force code is blocked anyway, so the optional
        // code is never allowed to sit below it.
        'latest_version_code': _optional < _force ? _force : _optional,
        'min_version_code': _force,
        'title': _title.text.trim(),
        'message': _message.text.trim(),
      });
      if (!mounted) return;
      _fill(Map<String, dynamic>.from(res.data as Map));
      messenger.showSnackBar(const SnackBar(content: Text('App update settings saved — live for every app open from now on.')));
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _loaded == null) return const Center(child: CircularProgressIndicator());
    if (_loaded == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Couldn\'t load app update settings', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700)),
            if (_error != null) ...[
              const SizedBox(height: AdminSpace.xs),
              Text(_error!, style: GoogleFonts.manrope(fontSize: 12, color: AdminColors.muted)),
            ],
            const SizedBox(height: AdminSpace.md),
            AdminButton.secondary(label: 'Retry', onPressed: _load),
          ],
        ),
      );
    }

    final problem = _problem;
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ModeCard(
          title: 'Optional update (manual)',
          description: 'Users on a build below this version code see an "Update / Later" popup. '
              '"Later" hides it until you publish a newer version code.',
          on: _optionalOn,
          onToggle: () => setState(() => _optionalOn = !_optionalOn),
          controller: _optionalCode,
          thisBuildCode: _thisBuildCode,
        ),
        const SizedBox(height: AdminSpace.section),
        _ModeCard(
          title: 'Force update',
          description: 'Users on a build below this version code are blocked with a full-screen "Update required" '
              'screen they can\'t close until they update.',
          on: _forceOn,
          onToggle: () => setState(() => _forceOn = !_forceOn),
          controller: _forceCode,
          thisBuildCode: _thisBuildCode,
          danger: true,
        ),
        const SizedBox(height: AdminSpace.section),
        Container(
          padding: const EdgeInsets.all(AdminSpace.card),
          decoration: adminCard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionTitle('Popup text'),
              const SizedBox(height: AdminSpace.md),
              AdminEditField(label: 'Title', controller: _title, hint: 'Update available'),
              const SizedBox(height: AdminSpace.md),
              AdminEditField(
                label: 'Message',
                controller: _message,
                hint: 'A new version of Aapno Bazar is available with improvements and bug fixes.',
                maxLines: 3,
              ),
              if (problem != null || _error != null) ...[
                const SizedBox(height: AdminSpace.sm),
                Text(problem ?? _error!,
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AdminSurface.error)),
              ],
              const SizedBox(height: AdminSpace.lg),
              Row(
                children: [
                  AdminButton(
                    label: 'Save changes',
                    size: AdminButtonSize.large,
                    loading: _saving,
                    onPressed: !_dirty || _saving || problem != null ? null : _save,
                  ),
                  const SizedBox(width: AdminSpace.sm),
                  if (_dirty)
                    AdminButton.secondary(
                      label: 'Discard',
                      size: AdminButtonSize.large,
                      onPressed: () => _fill(_loaded!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final summary = Container(
      padding: const EdgeInsets.all(AdminSpace.card),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AdminSectionTitle('Who sees what'),
          const SizedBox(height: AdminSpace.md),
          if (_thisBuild != null) ...[
            Text('This admin build: $_thisBuild',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.ink)),
            const SizedBox(height: AdminSpace.xxs),
            Text(
              'The version code is the number after "+" in pubspec.yaml (e.g. 1.0.6+7 → 7). '
              'Bump it for every Play Store release, upload, then set it here.',
              style: GoogleFonts.manrope(fontSize: 11, height: 1.5, fontWeight: FontWeight.w500, color: AdminColors.muted),
            ),
            const SizedBox(height: AdminSpace.md),
          ],
          ..._summaryLines(),
          const SizedBox(height: AdminSpace.md),
          Text(
            'Android only. Open apps pick up changes the next time they\'re opened or brought back to the foreground.',
            style: GoogleFonts.manrope(fontSize: 11, height: 1.5, fontWeight: FontWeight.w500, color: AdminColors.faint),
          ),
        ],
      ),
    );

    return SingleChildScrollView(
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 820) {
          return Column(children: [form, const SizedBox(height: AdminSpace.section), summary]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 11, child: form),
            const SizedBox(width: AdminSpace.section),
            Expanded(flex: 9, child: summary),
          ],
        );
      }),
    );
  }

  List<Widget> _summaryLines() {
    final force = _force;
    final optional = _optional < force ? force : _optional;
    Widget line(String emoji, String text, Color color) => Padding(
          padding: const EdgeInsets.only(bottom: AdminSpace.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: AdminSpace.xs),
              Expanded(child: Text(text, style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: color))),
            ],
          ),
        );
    return [
      if (force > 0) line('⛔', 'Builds 1 – ${force - 1}: blocked until they update', AdminSurface.error),
      if (optional > force) line('🔔', 'Builds ${force > 0 ? force : 1} – ${optional - 1}: "Update / Later" popup', AdminColors.ink),
      line('✅', optional > 0 ? 'Build $optional and above: no prompt' : 'All builds: no prompt (both off)', AdminSurface.success),
    ];
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.description,
    required this.on,
    required this.onToggle,
    required this.controller,
    required this.thisBuildCode,
    this.danger = false,
  });

  final String title;
  final String description;
  final bool on;
  final VoidCallback onToggle;
  final TextEditingController controller;
  final int? thisBuildCode;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpace.card),
      decoration: adminCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: AdminSectionTitle(title)),
              AdminToggle(on: on, onTap: onToggle),
              const SizedBox(width: AdminSpace.xs),
              Text(
                on ? 'On' : 'Off',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: on ? (danger ? AdminSurface.error : AdminSurface.success) : AdminColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: GoogleFonts.manrope(fontSize: 11.5, height: 1.5, fontWeight: FontWeight.w500, color: AdminColors.muted)),
          if (on) ...[
            const SizedBox(height: AdminSpace.md),
            AdminEditField(
              label: 'Prompt builds below version code',
              controller: controller,
              hint: thisBuildCode == null ? 'e.g. 8' : 'e.g. $thisBuildCode',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            if (thisBuildCode != null) ...[
              const SizedBox(height: AdminSpace.xs),
              AdminButton(
                label: 'Use this build ($thisBuildCode)',
                variant: AdminButtonVariant.text,
                size: AdminButtonSize.small,
                onPressed: () => controller.text = '$thisBuildCode',
              ),
            ],
          ],
        ],
      ),
    );
  }
}
