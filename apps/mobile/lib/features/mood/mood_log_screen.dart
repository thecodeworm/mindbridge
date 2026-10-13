import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/motion.dart';
import '../../widgets/breathing_circle.dart';
import '../../widgets/crisis_fab.dart';
import '../../widgets/felt_mood_slider.dart';
import '../../widgets/mood_tag_picker.dart';
import '../../widgets/inline_notice.dart';
import '../history/history_service.dart';
import 'activity_tag_picker.dart';
import 'distortion_picker.dart';
import 'mood_log_service.dart';
import 'suggestion_screen.dart';

class MoodLogScreen extends StatefulWidget {
  const MoodLogScreen({
    super.key,
    this.editing,
    this.initialScore,
    this.initialTag,
  });

  /// When set, edits this existing entry. Coping suggestion is not regenerated.
  final EntryDetail? editing;

  /// Pre-fills a new entry (e.g. the mood picked during onboarding).
  /// Ignored when [editing] is set.
  final double? initialScore;
  final String? initialTag;

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
    _score = editing?.moodLog.moodScore.toDouble() ?? widget.initialScore ?? 5;
    _tag = editing?.moodLog.moodTag ?? widget.initialTag;
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
    // Errors are swallowed here by design — the picker degrades to "no
    // activity tags" rather than showing an error.
    var tags = <ActivityTag>[];
    try {
      tags = await _service.getActivityTags();
    } catch (_) {
      // ignored, see above
    }
    if (!mounted) return;
    setState(() {
      _activityTags = tags;
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
      setState(() => _error = 'Pick the word that fits best, then you\'re set.');
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

      if (_selectedActivities.isNotEmpty ||
          widget.editing!.activities.isNotEmpty) {
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

    final String moodLogId;
    try {
      moodLogId = await _service.logMood(
        userId: userId,
        moodScore: _score.round(),
        moodTag: _tag!,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
      return;
    }
    if (!mounted) return;

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
        builder: (_) => SuggestionScreen(
          moodLogId: moodLogId,
          userId: userId,
          moodScore: _score.round(),
        ),
      ),
    );
  }

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
          automaticallyImplyLeading: false,
          actions: const [HelpAction()],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: DistortionPicker(
            onDone: (distortions, reframe) =>
                _handleDistortionDone(_pendingMoodLogId!, distortions, reframe),
            onSkip: () {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                _navigateToSuggestion(_pendingMoodLogId!, userId);
              }
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit entry' : 'Check in'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: _submitting ? null : () => Navigator.pop(context),
        ),
        actions: const [HelpAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (_error != null) ...[
            InlineNotice(message: _error!),
            const SizedBox(height: 16),
          ],

          // ── Score ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: AppElevation.decoration(context, radius: 20),
            child: Column(
              children: [
                Text('How are you feeling?', style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${_score.round()}',
                      style: tt.displayMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedSwitcher(
                      duration: AppMotion.short,
                      child: Text(
                        moodWord(_score),
                        key: ValueKey(moodWord(_score)),
                        style: tt.headlineSmall?.copyWith(color: Color.lerp(color, cs.onSurface, 0.45)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FeltMoodSlider(
                  value: _score,
                  onChanged: (v) => setState(() => _score = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Heavy', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                    Text('Great', style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Feeling word ─────────────────────────────────────────
          const _SectionTitle(title: 'Which word fits?'),
          const SizedBox(height: 12),
          MoodTagPicker(
            quadrant: _quadrant,
            tag: _tag,
            onQuadrantChanged: (v) => setState(() => _quadrant = v),
            onTagChanged: (v) => setState(() {
              _tag = v;
              _error = null;
            }),
          ),
          const SizedBox(height: 28),

          // ── Activities ───────────────────────────────────────────
          const _SectionTitle(title: 'What were you up to?', subtitle: 'Optional. Helps spot patterns over time.'),
          const SizedBox(height: 12),
          if (_loadingTags)
            const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
          else
            ActivityTagPicker(
              tags: _activityTags,
              selected: _selectedActivities,
              onChanged: (next) => setState(() => _selectedActivities = next),
            ),
          const SizedBox(height: 28),

          if (_tag != null && _score <= 3) ...[
            Center(child: BreathingCircle(color: color, size: 72)),
            const SizedBox(height: 8),
            Text(
              'Take a breath before you write, if that helps.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
          ],

          // ── Journal ──────────────────────────────────────────────
          const _SectionTitle(title: "What's on your mind?", subtitle: 'Optional. Only you can see this.'),
          const SizedBox(height: 12),
          TextField(
            controller: _journalController,
            maxLines: 5,
            minLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'A sentence or two is plenty.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.card),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: FilledButton(
          onPressed: _submitting ? null : _submit,
          child: Text(
            _submitting
                ? 'Saving…'
                : (_isEditing ? 'Save changes' : 'Get my technique'),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ],
    );
  }
}
