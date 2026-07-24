import 'package:supabase_flutter/supabase_flutter.dart';
import '../mood/mood_log_service.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.moodScore,
    required this.moodTag,
    required this.loggedAt,
    required this.techniqueName,
  });

  final String id;
  final int moodScore;
  final String moodTag;
  final DateTime loggedAt;
  final String? techniqueName;

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final suggestion = json['coping_suggestions'] as Map<String, dynamic>?;
    return HistoryEntry(
      id: json['id'] as String,
      moodScore: json['mood_score'] as int,
      moodTag: json['mood_tag'] as String,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      techniqueName: suggestion?['technique_name'] as String?,
    );
  }
}

class JournalEntry {
  JournalEntry({required this.id, required this.moodLogId, required this.body});

  final String id;
  final String moodLogId;
  final String body;

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        moodLogId: json['mood_log_id'] as String,
        body: json['body'] as String,
      );
}

class CopingSuggestionDetail {
  CopingSuggestionDetail({
    required this.techniqueName,
    required this.description,
    required this.steps,
  });

  final String techniqueName;
  final String description;
  final List<String> steps;

  factory CopingSuggestionDetail.fromJson(Map<String, dynamic> json) => CopingSuggestionDetail(
        techniqueName: json['technique_name'] as String,
        description: json['description'] as String,
        steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
      );
}

class EntryDetail {
  EntryDetail({
    required this.moodLog,
    required this.journalEntry,
    required this.copingSuggestion,
  });

  final MoodLog moodLog;
  final JournalEntry? journalEntry;
  final CopingSuggestionDetail? copingSuggestion;
}

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

  Future<({EntryDetail? detail, String? error})> getEntryDetail(String moodLogId) async {
    try {
      final results = await Future.wait([
        _client
            .from('mood_logs')
            .select('id, user_id, mood_score, mood_tag, logged_at')
            .eq('id', moodLogId)
            .single(),
        _client
            .from('journal_entries')
            .select('id, mood_log_id, user_id, body, created_at')
            .eq('mood_log_id', moodLogId)
            .maybeSingle(),
        _client
            .from('coping_suggestions')
            .select('id, mood_log_id, user_id, technique_name, description, steps, model_used, generated_at')
            .eq('mood_log_id', moodLogId)
            .maybeSingle(),
      ]);

      final moodLog = MoodLog.fromJson(results[0]!);
      final journalJson = results[1];
      final suggestionJson = results[2];

      return (
        detail: EntryDetail(
          moodLog: moodLog,
          journalEntry: journalJson != null ? JournalEntry.fromJson(journalJson) : null,
          copingSuggestion:
              suggestionJson != null ? CopingSuggestionDetail.fromJson(suggestionJson) : null,
        ),
        error: null,
      );
    } on PostgrestException catch (e) {
      return (detail: null, error: e.message);
    }
  }

  Future<String?> deleteEntry(String moodLogId) async {
    // journal_entries and coping_suggestions cascade-delete via their
    // mood_log_id FK — see 0001_init_schema.sql.
    try {
      await _client.from('mood_logs').delete().eq('id', moodLogId);
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
      await _client
          .from('mood_logs')
          .update({'mood_score': moodScore, 'mood_tag': moodTag})
          .eq('id', moodLogId);

      final trimmed = journalBody.trim();

      // journal_entries.mood_log_id has no unique constraint (it's not
      // 1:1 at the schema level like coping_suggestions is), so there's
      // no upsert conflict target — look up the existing row by hand.
      final existing = await _client
          .from('journal_entries')
          .select('id')
          .eq('mood_log_id', moodLogId)
          .maybeSingle();

      if (trimmed.isNotEmpty) {
        if (existing != null) {
          await _client
              .from('journal_entries')
              .update({'body': trimmed})
              .eq('id', existing['id'] as String);
        } else {
          await _client.from('journal_entries').insert({
            'mood_log_id': moodLogId,
            'user_id': userId,
            'body': trimmed,
          });
        }
      } else if (existing != null) {
        await _client.from('journal_entries').delete().eq('id', existing['id'] as String);
      }

      return null;
    } on PostgrestException catch (e) {
      return e.message;
    }
  }
}
