// Mirrors shared/types/index.ts — update both together.

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

class ActivityTag {
  ActivityTag({
    required this.id,
    required this.userId,
    required this.slug,
    required this.label,
    required this.emoji,
  });

  final String id;
  final String? userId;
  final String slug;
  final String label;
  final String emoji;

  factory ActivityTag.fromJson(Map<String, dynamic> json) => ActivityTag(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        slug: json['slug'] as String,
        label: json['label'] as String,
        emoji: json['emoji'] as String,
      );
}

class CopingSuggestionDetail {
  CopingSuggestionDetail({
    required this.id,
    required this.moodLogId,
    required this.techniqueName,
    required this.description,
    required this.steps,
    required this.crisisSignal,
    required this.helpful,
    required this.saved,
  });

  final String id;
  final String moodLogId;
  final String techniqueName;
  final String description;
  final List<String> steps;
  final bool crisisSignal;
  final bool? helpful;
  final bool saved;

  factory CopingSuggestionDetail.fromJson(Map<String, dynamic> json) =>
      CopingSuggestionDetail(
        id: json['id'] as String? ?? '',
        moodLogId: json['mood_log_id'] as String? ?? '',
        techniqueName: json['technique_name'] as String,
        description: json['description'] as String,
        steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
        crisisSignal: json['crisis_signal'] as bool? ?? false,
        helpful: json['helpful'] as bool?,
        saved: json['saved'] as bool? ?? false,
      );
}

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

class EntryDetail {
  EntryDetail({
    required this.moodLog,
    required this.journalEntry,
    required this.copingSuggestion,
    required this.activities,
  });

  final MoodLog moodLog;
  final JournalEntry? journalEntry;
  final CopingSuggestionDetail? copingSuggestion;
  final List<ActivityTag> activities;
}

class WeeklySummary {
  WeeklySummary({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.summary,
    required this.highlights,
    required this.generatedAt,
    this.crisisSignal = false,
  });

  final String id;
  final String userId;
  final DateTime weekStart;
  final String summary;
  final List<String> highlights;
  final DateTime generatedAt;

  /// True when the week's journals contained crisis language; the card then
  /// points to the Help screen. False for summaries cached before this existed.
  final bool crisisSignal;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) => WeeklySummary(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        weekStart: DateTime.parse(json['week_start'] as String),
        summary: json['summary'] as String? ?? '',
        highlights: ((json['highlights'] as List<dynamic>?) ?? []).map((e) => e as String).toList(),
        generatedAt: DateTime.parse(json['generated_at'] as String),
        crisisSignal: json['crisis_signal'] == true,
      );
}
