import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../core/theme_controller.dart';
import '../auth/auth_service.dart';
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
    // SettingsScreen is pushed on top of "/" (unlike HomeScreen, which
    // AuthGate renders directly), so signing out alone wouldn't surface
    // SignInScreen — AuthGate's stream swaps the content underneath this
    // still-topmost route. Pop back to it explicitly.
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section(
              cs,
              tt,
              title: 'Profile',
              child: Column(
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
              ),
            ),
            const SizedBox(height: 16),
            _section(
              cs,
              tt,
              title: 'Appearance',
              child: Column(
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
              ),
            ),
            const SizedBox(height: 16),
            _section(
              cs,
              tt,
              title: 'Account',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    // See the identical workaround this replaces at the old
                    // home_screen.dart:68-74 — OutlinedButton's theme default
                    // minimumSize is infinite-width, meant for Expanded
                    // wrappers. This one isn't wrapped, so it needs its own.
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
                    "Your login stays active — this clears your data, it doesn't close your account.",
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(ColorScheme cs, ThemeMode current, ThemeMode value, String label) {
    final selected = current == value;
    // primaryContainer isn't set in AppTheme's ColorScheme (see trap 3b in
    // the design-system notes) — use AppColors directly instead of letting
    // it silently fall back to a non-design-system M3 default.
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
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
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
