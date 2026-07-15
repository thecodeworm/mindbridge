import 'package:supabase_flutter/supabase_flutter.dart';

const kMoodTags = [
  {'value': 'happy',    'emoji': '😊', 'label': 'Happy'},
  {'value': 'calm',     'emoji': '😌', 'label': 'Calm'},
  {'value': 'meh',      'emoji': '😐', 'label': 'Meh'},
  {'value': 'sad',      'emoji': '😢', 'label': 'Sad'},
  {'value': 'anxious',  'emoji': '😰', 'label': 'Anxious'},
  {'value': 'angry',    'emoji': '😤', 'label': 'Angry'},
  {'value': 'tired',    'emoji': '😴', 'label': 'Tired'},
  {'value': 'confused', 'emoji': '🤔', 'label': 'Confused'},
];

class MoodLogService {
  MoodLogService(this._client);

  final SupabaseClient _client;

  Future<({String? moodLogId, String? error})> logMood({
    required String userId,
    required int moodScore,
    required String moodTag,
  }) async {
    try {
      final data = await _client
          .from('mood_logs')
          .insert({'user_id': userId, 'mood_score': moodScore, 'mood_tag': moodTag})
          .select('id')
          .single();
      return (moodLogId: data['id'] as String, error: null);
    } on PostgrestException catch (e) {
      return (moodLogId: null, error: e.message);
    }
  }

  Future<String?> addJournalEntry({
    required String moodLogId,
    required String userId,
    required String body,
  }) async {
    try {
      await _client
          .from('journal_entries')
          .insert({'mood_log_id': moodLogId, 'user_id': userId, 'body': body});
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }
}
