import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mood_color.dart';
import '../history/history_service.dart';
import 'mood_log_service.dart';
import 'suggestion_screen.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({super.key, this.editing});

  /// When set, the screen edits this existing entry instead of logging a
  /// new one. The coping_suggestions row is 1:1 on mood_log_id and already
  /// exists for this entry — editing doesn't regenerate it.
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
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _score = editing?.moodLog.moodScore.toDouble() ?? 5;
    _tag = editing?.moodLog.moodTag;
    _journalController.text = editing?.journalEntry?.body ?? '';
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

    final journal = _journalController.text.trim();
    if (journal.isNotEmpty) {
      final journalError = await _service.addJournalEntry(
        moodLogId: result.moodLogId!,
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
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestionScreen(moodLogId: result.moodLogId!, userId: userId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = moodColor(_score);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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

            // Tag picker
            Text('Pick a tag', style: tt.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kMoodTags.map((t) {
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
