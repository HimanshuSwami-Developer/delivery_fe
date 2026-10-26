import 'package:dio/dio.dart';
import 'package:fastswipe/core/api/api_client.dart';
import 'package:fastswipe/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

enum _UpdateMode { none, optional, force }

/// Wraps the whole app (via `MaterialApp.router`'s `builder`) and, on
/// Android, checks `GET /api/app-update/` against the installed build's
/// versionCode (the `+N` in pubspec's `version:`):
///
/// - below `min_version_code` → force update: Play's full-screen immediate
///   update flow, and if the user backs out of it, a blocking screen that
///   can't be dismissed until they update.
/// - below `latest_version_code` → optional update: a "Update / Later"
///   prompt that uses Play's flexible (background download) flow.
///
/// Every failure (offline, sideloaded build without Play, etc.) just lets
/// the app run — an update check must never be what breaks the app.
class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> with WidgetsBindingObserver {
  _UpdateMode _mode = _UpdateMode.none;
  String _title = 'Update available';
  String _message = '';
  String _packageName = '';
  bool _optionalDismissed = false;
  bool _busy = false;

  bool get _supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the Play Store without having updated — re-check so
    // a forced block can't be escaped by backgrounding the app.
    if (state == AppLifecycleState.resumed && _mode == _UpdateMode.force) _check();
  }

  Future<void> _check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _packageName = info.packageName;
      final current = int.tryParse(info.buildNumber) ?? 0;

      final response = await ApiClient().dio.get('/app-update/');
      final data = response.data as Map<String, dynamic>;
      final minCode = (data['min_version_code'] as num?)?.toInt() ?? 0;
      final latestCode = (data['latest_version_code'] as num?)?.toInt() ?? 0;

      final mode = current < minCode
          ? _UpdateMode.force
          : current < latestCode
              ? _UpdateMode.optional
              : _UpdateMode.none;
      if (!mounted) return;
      setState(() {
        _mode = mode;
        _title = (data['title'] as String?)?.trim().isNotEmpty == true ? data['title'] as String : 'Update available';
        _message = (data['message'] as String?) ?? '';
      });
      if (mode == _UpdateMode.force) await _startUpdate();
    } on DioException catch (e) {
      debugPrint('App update check failed: ${e.message}');
    } catch (e) {
      debugPrint('App update check failed: $e');
    }
  }

  /// Tries Play's in-app update flow first (immediate for force, flexible
  /// for optional); falls back to opening the Play Store listing when Play
  /// doesn't offer one (e.g. the new build hasn't propagated yet, or the app
  /// wasn't installed from Play).
  Future<void> _startUpdate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final info = await InAppUpdate.checkForUpdate();
      final available = info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress;

      if (available && _mode == _UpdateMode.force && info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        if (result == AppUpdateResult.success) return;
      } else if (available && _mode == _UpdateMode.optional && info.flexibleUpdateAllowed) {
        if (mounted) setState(() => _optionalDismissed = true);
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) await InAppUpdate.completeFlexibleUpdate();
        return;
      } else {
        await _openStore();
      }
    } catch (e) {
      debugPrint('In-app update failed, opening Play Store: $e');
      await _openStore();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openStore() async {
    final market = Uri.parse('market://details?id=$_packageName');
    final web = Uri.parse('https://play.google.com/store/apps/details?id=$_packageName');
    try {
      if (await launchUrl(market, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // No Play Store app on the device — fall through to the web listing.
    }
    try {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open Play Store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showForce = _mode == _UpdateMode.force;
    final showOptional = _mode == _UpdateMode.optional && !_optionalDismissed;
    return Stack(
      children: [
        widget.child,
        if (showForce) Positioned.fill(child: PopScope(canPop: false, child: _buildForceScreen(context))),
        if (showOptional) Positioned.fill(child: _buildOptionalPrompt(context)),
      ],
    );
  }

  Widget _buildForceScreen(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.system_update, size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              Text('Update required',
                  textAlign: TextAlign.center,
                  style: text.headlineSmall?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                _message.isNotEmpty
                    ? _message
                    : 'This version of the app is no longer supported. Please update to continue.',
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _busy ? null : _startUpdate,
                  child: Text(_busy ? 'Please wait…' : 'Update now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionalPrompt(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.system_update, size: 40, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(_title, style: text.titleLarge?.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w700)),
              if (_message.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_message, style: text.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => setState(() => _optionalDismissed = true),
                    child: const Text('Later', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                    ),
                    onPressed: _busy ? null : _startUpdate,
                    child: const Text('Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
