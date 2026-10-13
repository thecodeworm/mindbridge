import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
import '../../core/theme.dart';
import '../../core/theme_controller.dart';
import '../../core/app_lock_state.dart';
import '../../widgets/crisis_fab.dart';
import '../auth/app_lock_service.dart';
import '../auth/auth_service.dart';
import '../help/help_screen.dart';
import 'export_service.dart';
import 'notification_service.dart';
import 'settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService(Supabase.instance.client);
  final _settingsService = SettingsService(Supabase.instance.client);
  late final _nameController = TextEditingController(
    text: Supabase.instance.client.auth.currentUser?.userMetadata?['display_name'] as String? ?? '',
  );

  bool _nameSaving = false;
  String? _nameError;
  bool _nameSaved = false;

  bool _confirmingDelete = false;
  bool _deleting = false;
  String? _deleteError;

  bool _exporting = false;
  String? _exportError;

  bool _appLockAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    initNotifications();
  }

  Future<void> _checkBiometrics() async {
    final available = await isBiometricsAvailable();
    if (!mounted) return;
    setState(() => _appLockAvailable = available);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _nameSaving = true;
      _nameError = null;
      _nameSaved = false;
    });

    final error = await _settingsService.updateDisplayName(userId, _nameController.text);
    if (!mounted) return;
    setState(() {
      _nameSaving = false;
      _nameError = error;
      _nameSaved = error == null;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _confirmDeleteData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _deleting = true);
    final error = await _settingsService.deleteAllUserData(userId);
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _deleting = false;
        _deleteError = error;
      });
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleExport() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    setState(() {
      _exporting = true;
      _exportError = null;
    });
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    final error = await exportUserData(userId, sharePositionOrigin: origin);
    if (!mounted) return;
    setState(() {
      _exporting = false;
      _exportError = error;
    });
  }

  Future<void> _requestNotifications() async {
    final granted = await requestNotificationPermission();
    if (!mounted) return;
    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications enabled.')),
      );
    }
  }

  Future<void> _toggleAppLock() async {
    if (!AppLockState.enabled.value) {
      final ok = await authenticate();
      if (!mounted) return;
      if (ok) await AppLockState.setEnabled(true);
    } else {
      await AppLockState.setEnabled(false);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        actions: const [HelpAction()],
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section(cs, tt, title: 'Profile', child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                  maxLength: 60,
                  onChanged: (_) => setState(() => _nameSaved = false),
                ),
                if (_nameError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_nameError!, style: TextStyle(color: cs.error, fontSize: 14)),
                    ),
                  ),
                if (_nameSaved && _nameError == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Saved.', style: tt.bodySmall?.copyWith(color: cs.primary)),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: _nameSaving ? null : _saveName,
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    child: Text(_nameSaving ? 'Saving…' : 'Save name'),
                  ),
                ),
              ],
            )),
            const SizedBox(height: 16),
            _section(cs, tt, title: 'Appearance', child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Theme', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.mode,
                  builder: (context, mode, _) => Wrap(
                    spacing: 8,
                    children: [
                      _themeChip(cs, mode, ThemeMode.light, 'Light'),
                      _themeChip(cs, mode, ThemeMode.dark, 'Dark'),
                      _themeChip(cs, mode, ThemeMode.system, 'System'),
                    ],
                  ),
                ),
              ],
            )),
            const SizedBox(height: 16),
            _section(cs, tt, title: 'Reminders', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get a daily reminder to check in with your mood.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _requestNotifications,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: const Text('Enable daily reminders'),
                ),
              ],
            )),
            const SizedBox(height: 16),
            _section(cs, tt, title: 'Data', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export all your mood logs, journal entries, and coping suggestions as JSON.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (_exportError != null) ...[
                  const SizedBox(height: 8),
                  Text(_exportError!, style: tt.bodySmall?.copyWith(color: cs.error)),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _exporting ? null : _handleExport,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(_exporting ? 'Exporting…' : 'Export my data'),
                ),
              ],
            )),
            if (_appLockAvailable) ...[
              const SizedBox(height: 16),
              _section(cs, tt, title: 'Security', child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('App lock', style: tt.bodyMedium),
                        Text(
                          'Require biometrics or PIN to open MindBridge.',
                          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: AppLockState.enabled.value,
                    onChanged: (_) => _toggleAppLock(),
                  ),
                ],
              )),
            ],
            const SizedBox(height: 16),
            _section(cs, tt, title: 'Help', child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If you\'re struggling, confidential support is available 24/7.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    foregroundColor: AppColors.terraDark,
                    side: const BorderSide(color: AppColors.terra),
                  ),
                  child: const Text('Crisis resources →'),
                ),
              ],
            )),
            const SizedBox(height: 16),
            _section(cs, tt, title: 'Account', child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: _signOut,
                  child: const Text('Sign out'),
                ),
                const SizedBox(height: 20),
                Divider(color: cs.outline),
                const SizedBox(height: 12),
                Text('Delete my data', style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  "Permanently deletes every mood log, journal entry, and coping suggestion. "
                  "Your login stays active. This clears your data but doesn't close your account.",
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                if (!_confirmingDelete)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        foregroundColor: cs.error,
                        side: BorderSide(color: cs.error),
                      ),
                      onPressed: () => setState(() => _confirmingDelete = true),
                      child: const Text('Delete my data'),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "This can't be undone. Delete all mood data?",
                          style: TextStyle(color: cs.error, fontWeight: FontWeight.w600),
                        ),
                        if (_deleteError != null) ...[
                          const SizedBox(height: 8),
                          Text(_deleteError!, style: TextStyle(color: cs.error, fontSize: 13)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _deleting
                                    ? null
                                    : () => setState(() {
                                        _confirmingDelete = false;
                                        _deleteError = null;
                                      }),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: cs.error,
                                  side: BorderSide(color: cs.error),
                                ),
                                onPressed: _deleting ? null : _confirmDeleteData,
                                child: Text(_deleting ? 'Deleting…' : 'Delete everything'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(ColorScheme cs, ThemeMode current, ThemeMode value, String label) {
    final selected = current == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blueTint = isDark ? AppColors.dBlueTint : AppColors.blueTint;
    final blueDark = isDark ? AppColors.dBlueDark : AppColors.blueDark;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => ThemeController.setMode(value),
      selectedColor: blueTint,
      labelStyle: TextStyle(color: selected ? blueDark : cs.onSurface),
    );
  }

  Widget _section(ColorScheme cs, TextTheme tt, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: tt.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
