import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/models.dart';

export '../../core/models.dart'
    show HistoryEntry, JournalEntry, CopingSuggestionDetail, EntryDetail, ActivityTag;

const _kNotFound = "We couldn't find that entry. It may have already been deleted.";

class HistoryService {
  HistoryService(this._client);

  final SupabaseClient _client;

  Future<({List<HistoryEntry> entries, String? error})> getHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _client
          .from('mood_logs')
          .select('id, mood_score, mood_tag, logged_at, coping_suggestions(technique_name)')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .range(offset, offset + limit - 1);
      final entries = (data as List<dynamic>)
          .map((row) => HistoryEntry.fromJson(row as Map<String, dynamic>))
          .toList();
      return (entries: entries, error: null);
    } on PostgrestException catch (e) {
      return (entries: <HistoryEntry>[], error: e.message);
    }
  }

  // Every query filters on user_id as well as row id — RLS enforces this
  // server-side; the explicit filter degrades a policy regression to "not found".
  Future<({EntryDetail? detail, String? error})> getEntryDetail({
    required String moodLogId,
    required String userId,
  }) async {
    try {
      final results = await Future.wait<dynamic>([
        _client
            .from('mood_logs')
            .select('id, user_id, mood_score, mood_tag, logged_at')
            .eq('id', moodLogId)
            .eq('user_id', userId)
            .single(),
        _client
            .from('journal_entries')
            .select('id, mood_log_id, user_id, body, created_at')
            .eq('mood_log_id', moodLogId)
            .eq('user_id', userId)
            .maybeSingle(),
        _client
            .from('coping_suggestions')
            .select(
              'id, mood_log_id, user_id, technique_name, description, steps, '
              'model_used, generated_at, crisis_signal, helpful, saved',
            )
            .eq('mood_log_id', moodLogId)
            .eq('user_id', userId)
            .maybeSingle(),
        _client
            .from('mood_log_activities')
            .select('activity_tag_id, activity_tags(id, user_id, slug, label, emoji)')
            .eq('mood_log_id', moodLogId)
            .eq('user_id', userId),
      ]);

      final moodLog = MoodLog.fromJson(results[0]! as Map<String, dynamic>);
      final journalJson = results[1] as Map<String, dynamic>?;
      final suggestionJson = results[2] as Map<String, dynamic>?;
      final activityRows = (results[3] as List<dynamic>?) ?? [];
      final activities = activityRows
          .map((a) {
            final tagRow = (a as Map<String, dynamic>)['activity_tags'] as Map<String, dynamic>?;
            return tagRow != null ? ActivityTag.fromJson(tagRow) : null;
          })
          .whereType<ActivityTag>()
          .toList();

      return (
        detail: EntryDetail(
          moodLog: moodLog,
          journalEntry: journalJson != null ? JournalEntry.fromJson(journalJson) : null,
          copingSuggestion:
              suggestionJson != null ? CopingSuggestionDetail.fromJson(suggestionJson) : null,
          activities: activities,
        ),
        error: null,
      );
    } on PostgrestException catch (e) {
      return (detail: null, error: e.message);
    }
  }

  Future<String?> deleteEntry({
    required String moodLogId,
    required String userId,
  }) async {
    // journal_entries and coping_suggestions cascade-delete via FK.
    // .select() matters: without it an RLS-blocked delete silently reports success.
    try {
      final deleted = await _client
          .from('mood_logs')
          .delete()
          .eq('id', moodLogId)
          .eq('user_id', userId)
          .select('id');
      if ((deleted as List<dynamic>).isEmpty) return _kNotFound;
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateEntry({
    required String moodLogId,
    required String userId,
    required int moodScore,
    required String moodTag,
    required String journalBody,
  }) async {
    try {
      final updatedMood = await _client
          .from('mood_logs')
          .update({'mood_score': moodScore, 'mood_tag': moodTag})
          .eq('id', moodLogId)
          .eq('user_id', userId)
          .select('id');
      if ((updatedMood as List<dynamic>).isEmpty) return _kNotFound;

      final trimmed = journalBody.trim();
      final existing = await _client
          .from('journal_entries')
          .select('id')
          .eq('mood_log_id', moodLogId)
          .eq('user_id', userId)
          .maybeSingle();

      if (trimmed.isNotEmpty) {
        final List<dynamic> written;
        if (existing != null) {
          written = await _client
              .from('journal_entries')
              .update({'body': trimmed})
              .eq('id', existing['id'] as String)
              .eq('user_id', userId)
              .select('id');
        } else {
          written = await _client.from('journal_entries').insert({
            'mood_log_id': moodLogId,
            'user_id': userId,
            'body': trimmed,
          }).select('id');
        }
        if (written.isEmpty) return _kNotFound;
      } else if (existing != null) {
        final deleted = await _client
            .from('journal_entries')
            .delete()
            .eq('id', existing['id'] as String)
            .eq('user_id', userId)
            .select('id');
        if ((deleted as List<dynamic>).isEmpty) return _kNotFound;
      }

      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateSuggestionFeedback({
    required String moodLogId,
    required String userId,
    bool? helpful,
    bool? saved,
  }) async {
    try {
      final update = <String, dynamic>{};
      if (helpful != null) update['helpful'] = helpful;
      if (saved != null) update['saved'] = saved;
      if (update.isEmpty) return null;

      await _client
          .from('coping_suggestions')
          .update(update)
          .eq('mood_log_id', moodLogId)
          .eq('user_id', userId);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }

  Future<({List<CopingSuggestionDetail> techniques, String? error})> getSavedToolkit({
    required String userId,
  }) async {
    try {
      final data = await _client
          .from('coping_suggestions')
          .select(
            'id, technique_name, description, steps, crisis_signal, helpful, saved, '
            'mood_log_id, generated_at',
          )
          .eq('user_id', userId)
          .eq('saved', true)
          .order('generated_at', ascending: false);
      final techniques = (data as List<dynamic>)
          .map((row) => CopingSuggestionDetail.fromJson(row as Map<String, dynamic>))
          .toList();
      return (techniques: techniques, error: null);
    } on PostgrestException catch (e) {
      return (techniques: <CopingSuggestionDetail>[], error: e.message);
    }
  }
}
