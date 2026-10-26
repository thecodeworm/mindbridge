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

  Future<String?> deleteAllUserData() async {
    // One server-side call removes everything derived from the user's content:
    // mood logs (cascading to journal entries, suggestions and activity
    // links), weekly AI summaries, custom tags and archived duplicates. The
    // login stays; use deleteAccount() to remove that too.
    try {
      await _client.rpc('delete_my_data');
      return null;
    } on PostgrestException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<String?> deleteAccount(String userId) async {
    // The delete-account Edge Function removes the auth user with the service
    // role; every table cascades from it. The local session is cleared
    // afterwards without a server round trip since the server user is gone.
    try {
      await _client.functions.invoke(
        'delete-account',
        body: {'user_id': userId, 'confirm': 'DELETE'},
      );
    } on FunctionException {
      return "We couldn't delete your account just now. Nothing was removed. Please try again in a moment.";
    } catch (_) {
      return "We couldn't delete your account just now. Nothing was removed. Please try again in a moment.";
    }
    await _client.auth.signOut(scope: SignOutScope.local);
    return null;
  }
}
