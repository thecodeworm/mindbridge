import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );
      return null;
    } on AuthException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.mindbridge.mindbridge://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return null;
    } on AuthException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.mindbridge.mindbridge://reset-callback',
      );
      return null;
    } on AuthException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      return null;
    } on AuthException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<void> signOut() => _client.auth.signOut();
}
