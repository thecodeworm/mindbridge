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

Map<String, String>? moodTagInfo(String value) {
  for (final tag in kMoodTags) {
    if (tag['value'] == value) return tag;
  }
  return null;
}

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

  Future<({List<MoodLog> logs, String? error})> getMoodLogsInRange({
    required String userId,
    required int days,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    try {
      final data = await _client
          .from('mood_logs')
          .select('id, user_id, mood_score, mood_tag, logged_at')
          .eq('user_id', userId)
          .gte('logged_at', since.toIso8601String())
          .order('logged_at', ascending: true);
      final logs = (data as List<dynamic>)
          .map((row) => MoodLog.fromJson(row as Map<String, dynamic>))
          .toList();
      return (logs: logs, error: null);
    } on PostgrestException catch (e) {
      return (logs: <MoodLog>[], error: e.message);
    }
  }
}

class MoodLog {
  MoodLog({
    required this.id,
    required this.userId,
    required this.moodScore,
    required this.moodTag,
    required this.loggedAt,
  });

  final String id;
  final String userId;
  final int moodScore;
  final String moodTag;
  final DateTime loggedAt;

  factory MoodLog.fromJson(Map<String, dynamic> json) => MoodLog(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        moodScore: json['mood_score'] as int,
        moodTag: json['mood_tag'] as String,
        loggedAt: DateTime.parse(json['logged_at'] as String),
      );
}
