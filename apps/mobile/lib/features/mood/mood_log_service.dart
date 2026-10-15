import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';
import '../../core/models.dart';

export '../../core/models.dart' show MoodLog;

// Mirrors shared/types MOOD_TAGS — update both together.
const kMoodTags = [
  // High energy + pleasant
  {'quadrant': 'high-pleasant', 'value': 'excited',     'emoji': '🤩', 'label': 'Excited'},
  {'quadrant': 'high-pleasant', 'value': 'happy',       'emoji': '😊', 'label': 'Happy'},
  {'quadrant': 'high-pleasant', 'value': 'energized',   'emoji': '⚡', 'label': 'Energized'},
  {'quadrant': 'high-pleasant', 'value': 'proud',       'emoji': '💪', 'label': 'Proud'},
  {'quadrant': 'high-pleasant', 'value': 'grateful',    'emoji': '🙏', 'label': 'Grateful'},
  {'quadrant': 'high-pleasant', 'value': 'hopeful',     'emoji': '🌟', 'label': 'Hopeful'},
  // High energy + unpleasant
  {'quadrant': 'high-unpleasant', 'value': 'anxious',     'emoji': '😰', 'label': 'Anxious'},
  {'quadrant': 'high-unpleasant', 'value': 'angry',       'emoji': '😤', 'label': 'Angry'},
  {'quadrant': 'high-unpleasant', 'value': 'stressed',    'emoji': '😫', 'label': 'Stressed'},
  {'quadrant': 'high-unpleasant', 'value': 'frustrated',  'emoji': '😣', 'label': 'Frustrated'},
  {'quadrant': 'high-unpleasant', 'value': 'overwhelmed', 'emoji': '🌀', 'label': 'Overwhelmed'},
  {'quadrant': 'high-unpleasant', 'value': 'irritated',   'emoji': '😒', 'label': 'Irritated'},
  // Low energy + pleasant
  {'quadrant': 'low-pleasant', 'value': 'calm',        'emoji': '😌', 'label': 'Calm'},
  {'quadrant': 'low-pleasant', 'value': 'content',     'emoji': '🙂', 'label': 'Content'},
  {'quadrant': 'low-pleasant', 'value': 'relaxed',     'emoji': '😮‍💨', 'label': 'Relaxed'},
  {'quadrant': 'low-pleasant', 'value': 'peaceful',    'emoji': '🕊️', 'label': 'Peaceful'},
  {'quadrant': 'low-pleasant', 'value': 'focused',     'emoji': '🎯', 'label': 'Focused'},
  {'quadrant': 'low-pleasant', 'value': 'satisfied',   'emoji': '✨', 'label': 'Satisfied'},
  // Low energy + unpleasant
  {'quadrant': 'low-unpleasant', 'value': 'sad',       'emoji': '😢', 'label': 'Sad'},
  {'quadrant': 'low-unpleasant', 'value': 'tired',     'emoji': '😴', 'label': 'Tired'},
  {'quadrant': 'low-unpleasant', 'value': 'confused',  'emoji': '🤔', 'label': 'Confused'},
  {'quadrant': 'low-unpleasant', 'value': 'meh',       'emoji': '😐', 'label': 'Meh'},
  {'quadrant': 'low-unpleasant', 'value': 'lonely',    'emoji': '🫂', 'label': 'Lonely'},
  {'quadrant': 'low-unpleasant', 'value': 'bored',     'emoji': '😑', 'label': 'Bored'},
];

const kMoodQuadrants = [
  {'value': 'high-pleasant',   'label': 'Feeling good & activated', 'emoji': '✨'},
  {'value': 'high-unpleasant', 'label': 'Activated but struggling', 'emoji': '⚡'},
  {'value': 'low-pleasant',    'label': 'Calm & at ease',           'emoji': '🌿'},
  {'value': 'low-unpleasant',  'label': 'Low & drained',            'emoji': '🌧️'},
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

  Future<String> logMood({
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
      return data['id'] as String;
    } on PostgrestException catch (e) {
      throw AppException(e.message);
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
      return friendlyErrorMessage(e.message);
    }
  }

  Future<List<MoodLog>> getMoodLogsInRange({
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
      return (data as List<dynamic>)
          .map((row) => MoodLog.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  Future<List<MoodLog>> getAllLogsForYear({
    required String userId,
  }) async {
    final since = DateTime.now().subtract(const Duration(days: 366));
    try {
      final data = await _client
          .from('mood_logs')
          .select('id, user_id, mood_score, mood_tag, logged_at')
          .eq('user_id', userId)
          .gte('logged_at', since.toIso8601String())
          .order('logged_at', ascending: true);
      return (data as List<dynamic>)
          .map((row) => MoodLog.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  Future<List<ActivityTag>> getActivityTags() async {
    try {
      final data = await _client
          .from('activity_tags')
          .select('id, user_id, slug, label, emoji')
          .order('label', ascending: true);
      return (data as List<dynamic>)
          .map((row) => ActivityTag.fromJson(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }

  Future<String?> setEntryActivities({
    required String moodLogId,
    required String userId,
    required List<String> tagIds,
  }) async {
    try {
      await _client
          .from('mood_log_activities')
          .delete()
          .eq('mood_log_id', moodLogId)
          .eq('user_id', userId);

      if (tagIds.isNotEmpty) {
        await _client.from('mood_log_activities').insert(
          tagIds.map((id) => {
            'mood_log_id': moodLogId,
            'activity_tag_id': id,
            'user_id': userId,
          }).toList(),
        );
      }
      return null;
    } on PostgrestException catch (e) {
      return friendlyErrorMessage(e.message);
    }
  }

  Future<List<({MoodLog log, List<ActivityTag> activities})>> getLogsWithActivities({
    required String userId,
    required int days,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    try {
      final data = await _client
          .from('mood_logs')
          .select(
            'id, user_id, mood_score, mood_tag, logged_at, '
            'mood_log_activities(activity_tag_id, activity_tags(id, user_id, slug, label, emoji))',
          )
          .eq('user_id', userId)
          .gte('logged_at', since.toIso8601String())
          .order('logged_at', ascending: true);

      return (data as List<dynamic>).map((row) {
        final map = row as Map<String, dynamic>;
        final log = MoodLog.fromJson(map);
        final activityRows = (map['mood_log_activities'] as List<dynamic>?) ?? [];
        final activities = activityRows
            .map((a) {
              final tagRow = (a as Map<String, dynamic>)['activity_tags'] as Map<String, dynamic>?;
              return tagRow != null ? ActivityTag.fromJson(tagRow) : null;
            })
            .whereType<ActivityTag>()
            .toList();
        return (log: log, activities: activities);
      }).toList();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    }
  }
}
