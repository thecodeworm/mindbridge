import 'dart:convert';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<String?> exportUserData(String userId, {Rect? sharePositionOrigin}) async {
  final client = Supabase.instance.client;
  try {
    final results = await Future.wait([
      client
          .from('mood_logs')
          .select('id, mood_score, mood_tag, logged_at')
          .eq('user_id', userId)
          .order('logged_at', ascending: false),
      client
          .from('journal_entries')
          .select('id, mood_log_id, body, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false),
      client
          .from('coping_suggestions')
          .select('id, mood_log_id, technique_name, description, steps, generated_at')
          .eq('user_id', userId)
          .order('generated_at', ascending: false),
    ]);

    final now = DateTime.now().toLocal();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final payload = json.encode({
      'exported_at': now.toIso8601String(),
      'mood_logs': results[0],
      'journal_entries': results[1],
      'coping_suggestions': results[2],
    });

    await Share.share(
      payload,
      subject: 'mindbridge-export-$dateStr.json',
      sharePositionOrigin: sharePositionOrigin,
    );
    return null;
  } on PostgrestException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}
