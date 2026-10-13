import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';

class SettingsService {
  SettingsService(this._client);

  final SupabaseClient _client;

  Future<String?> updateDisplayName(String userId, String displayName) async {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'Display name cannot be empty.';

    // Kept in sync in two places: auth user_metadata (what the dashboard
    // greeting reads — see HomeScreen) and public.users.display_name (the
    // DB column, source of truth for any future server-side read).
    try {
      await _client.auth.updateUser(UserAttributes(data: {'display_name': trimmed}));
    } on AuthException catch (e) {
      return friendlyErrorMessage(e.message);
    }

    try {
      await _client.from('users').update({'display_name': trimmed}).eq('id', userId);
      return null;
    } on PostgrestException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<String?> deleteAllUserData(String userId) async {
    // journal_entries and coping_suggestions cascade-delete via their
    // mood_log_id FK — see 0001_init_schema.sql. This clears all mood data
    // but does not close the login itself (that needs the admin API, which
    // requires a service-role Edge Function — not built yet).
    try {
      await _client.from('mood_logs').delete().eq('user_id', userId);
      return null;
    } on PostgrestException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }
}
