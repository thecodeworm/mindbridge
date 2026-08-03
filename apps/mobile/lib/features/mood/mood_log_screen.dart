import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mood_color.dart';
import '../history/history_service.dart';
import 'activity_tag_picker.dart';
import 'distortion_picker.dart';
import 'mood_log_service.dart';
import 'suggestion_screen.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key, this.editing});

  /// When set, edits this existing entry. Coping suggestion is not regenerated.
  final EntryDetail? editing;

  @override
  State<MoodLogScreen> createState() => _MoodLogScreenState();
}

class _MoodLogScreenState extends State<MoodLogScreen> {
  final _service = MoodLogService(Supabase.instance.client);
  final _historyService = HistoryService(Supabase.instance.client);
  final _journalController = TextEditingController();

  bool get _isEditing => widget.editing != null;

  late double _score;
  String? _tag;
  String? _quadrant;
  Set<String> _selectedActivities = {};
  List<ActivityTag> _activityTags = [];
  bool _loadingTags = true;

  // Distortion flow state (new entries only)
  String? _pendingMoodLogId;

  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _score = editing?.moodLog.moodScore.toDouble() ?? 5;
    _tag = editing?.moodLog.moodTag;
    _journalController.text = editing?.journalEntry?.body ?? '';
    _selectedActivities = editing?.activities.map((a) => a.id).toSet() ?? {};

    // Pre-select quadrant from existing tag
    if (_tag != null) {
      final info = moodTagInfo(_tag!);
      _quadrant = info?['quadrant'];
    }

    _loadTags();
  }

  Future<void> _loadTags() async {
    final result = await _service.getActivityTags();
    if (!mounted) return;
    setState(() {
      _activityTags = result.tags;
      _loadingTags = false;
    });
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_tag == null) {
      setState(() => _error = 'Pick a mood tag before submitting.');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    if (_isEditing) {
      final error = await _historyService.updateEntry(
        moodLogId: widget.editing!.moodLog.id,
        userId: userId,
        moodScore: _score.round(),
        moodTag: _tag!,
        journalBody: _journalController.text,
      );
      if (!mounted) return;

      if (_selectedActivities.isNotEmpty || widget.editing!.activities.isNotEmpty) {
        await _service.setEntryActivities(
          moodLogId: widget.editing!.moodLog.id,
          userId: userId,
          tagIds: _selectedActivities.toList(),
        );
      }

      if (!mounted) return;
      if (error != null) {
        setState(() {
          _submitting = false;
          _error = error;
        });
        return;
      }
      Navigator.pop(context, true);
      return;
    }

    final result = await _service.logMood(
      userId: userId,
      moodScore: _score.round(),
      moodTag: _tag!,
    );
    if (!mounted) return;

    if (result.error != null || result.moodLogId == null) {
      setState(() {
        _submitting = false;
        _error = result.error ?? 'Something went wrong.';
      });
      return;
    }

    final moodLogId = result.moodLogId!;

    // Save activities
    if (_selectedActivities.isNotEmpty) {
      await _service.setEntryActivities(
        moodLogId: moodLogId,
        userId: userId,
        tagIds: _selectedActivities.toList(),
      );
    }
    if (!mounted) return;

    final journal = _journalController.text.trim();
    if (journal.isNotEmpty) {
      final journalError = await _service.addJournalEntry(
        moodLogId: moodLogId,
        userId: userId,
        body: journal,
      );
      if (!mounted) return;
      if (journalError != null) {
        setState(() {
          _submitting = false;
          _error = journalError;
        });
        return;
      }
      // Show distortion picker before navigating
      setState(() {
        _submitting = false;
        _pendingMoodLogId = moodLogId;
      });
      return;
    }

    // No journal — go straight to suggestion
    _navigateToSuggestion(moodLogId, userId);
  }

  Future<void> _handleDistortionDone(
    String moodLogId,
    List<String> distortions,
    String reframe,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (distortions.isNotEmpty) {
      await Supabase.instance.client
          .from('journal_entries')
          .update({'distortions': distortions, 'reframe': reframe})
          .eq('mood_log_id', moodLogId)
          .eq('user_id', userId);
    }
    if (!mounted) return;
    _navigateToSuggestion(moodLogId, userId);
  }

  void _navigateToSuggestion(String moodLogId, String userId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SuggestionScreen(moodLogId: moodLogId, userId: userId),
      ),
    );
  }

  List<Map<String, String>> get _tagsForQuadrant => _quadrant == null
      ? []
      : kMoodTags.where((t) => t['quadrant'] == _quadrant).toList();

  @override
  Widget build(BuildContext context) {
    final color = moodColor(_score);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Distortion step overlay
    if (_pendingMoodLogId != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reflect on your thoughts'),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          foregroundColor: cs.onSurface,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: DistortionPicker(
            onDone: (distortions, reframe) =>
                _handleDistortionDone(_pendingMoodLogId!, distortions, reframe),
            onSkip: () {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) _navigateToSuggestion(_pendingMoodLogId!, userId);
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit entry' : 'How are you feeling?'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 14)),
              ),
              const SizedBox(height: 16),
            ],

            // Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mood score', style: tt.bodyMedium),
                Text(
                  '${_score.round()}',
                  style: tt.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _score,
              min: 1,
              max: 10,
              activeColor: color,
              inactiveColor: color.withValues(alpha: 0.25),
              onChanged: (v) => setState(() => _score = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1', style: tt.bodySmall),
                Text('10', style: tt.bodySmall),
              ],
            ),
            const SizedBox(height: 24),

            // Two-step tag picker
            Text('How does it feel?', style: tt.bodyMedium),
            const SizedBox(height: 8),
            if (_quadrant == null) ...[
              ...kMoodQuadrants.map((q) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => setState(() => _quadrant = q['value']),
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: Text('${q['emoji']}  ${q['label']}'),
                  ),
                );
              }),
            ] else ...[
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _quadrant = null;
                      _tag = null;
                    }),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(
                      kMoodQuadrants.firstWhere((q) => q['value'] == _quadrant)['label']!,
                      style: tt.bodySmall,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tagsForQuadrant.map((t) {
                  final selected = _tag == t['value'];
                  return FilterChip(
                    label: Text('${t['emoji']} ${t['label']}'),
                    selected: selected,
                    onSelected: (_) => setState(() => _tag = t['value']),
                    selectedColor: cs.primaryContainer,
                    checkmarkColor: cs.primary,
                    labelStyle: TextStyle(
                      color: selected ? cs.primary : cs.onSurface,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Activity tags
            Text('What were you doing?', style: tt.bodyMedium),
            const SizedBox(height: 4),
            Text('Optional', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (_loadingTags)
              const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
            else
              ActivityTagPicker(
                tags: _activityTags,
                selected: _selectedActivities,
                onChanged: (next) => setState(() => _selectedActivities = next),
              ),
            const SizedBox(height: 24),

            // Journal
            Text('Journal (optional)', style: tt.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _journalController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: 'How are you feeling? (optional)',
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(
                      _submitting ? 'Saving…' : (_isEditing ? 'Save changes' : 'Save'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
