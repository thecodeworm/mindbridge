import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_exception.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../widgets/breathing_circle.dart';
import '../../widgets/crisis_fab.dart';
import '../../widgets/feedback_chip.dart';
import '../../widgets/notebook.dart';
import '../history/history_service.dart';
import '../help/help_screen.dart';
import 'suggestion_service.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({
    super.key,
    required this.moodLogId,
    required this.userId,
    this.moodScore,
  });

  final String moodLogId;
  final String userId;

  /// Tints the reveal with the mood-temperature ramp when known.
  final int? moodScore;

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  late final SuggestionService _service = SuggestionService(
    Supabase.instance.client,
  );
  late final HistoryService _historyService = HistoryService(
    Supabase.instance.client,
  );

  SuggestionResult? _suggestion;
  bool _loading = true;
  String? _error;

  bool? _helpful;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final suggestion = await _service.generateSuggestion(
        moodLogId: widget.moodLogId,
        userId: widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _suggestion = suggestion;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _setHelpful(bool? value) async {
    setState(() => _helpful = value);
    await _historyService.updateSuggestionFeedback(
      moodLogId: widget.moodLogId,
      userId: widget.userId,
      helpful: value,
    );
  }

  Future<void> _toggleSaved() async {
    final next = !_saved;
    setState(() => _saved = next);
    await _historyService.updateSuggestionFeedback(
      moodLogId: widget.moodLogId,
      userId: widget.userId,
      saved: next,
    );
  }

  void _done() {
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final ready = !_loading && _error == null && _suggestion != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: _done,
        ),
        titleSpacing: 0,
        title: ready ? const SectionLabel('Try this now') : null,
        actions: const [HelpAction()],
      ),
      body: AnimatedSwitcher(
        duration: AppMotion.long,
        switchInCurve: AppMotion.easeOutCubic,
        child: _loading
            ? _buildLoading(tt, cs)
            : _error != null
                ? _buildError(cs, tt)
                : _suggestion != null
                    ? _buildSuggestion(context, cs, tt)
                    : const SizedBox.shrink(),
      ),
      bottomNavigationBar: ready
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton(onPressed: _done, child: const Text('Done')),
            )
          : null,
    );
  }

  Color get _tone => widget.moodScore != null ? moodColor(widget.moodScore!) : moodColor(5.5);

  Widget _buildLoading(TextTheme tt, ColorScheme cs) {
    return Center(
      key: const ValueKey('loading'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BreathingCircle(
              colors: widget.moodScore != null
                  ? [_tone.withValues(alpha: 0.6), _tone]
                  : [moodColor(1), moodColor(5.5), moodColor(10)],
              size: 180,
            ),
            const SizedBox(height: 32),
            Text('Breathe with the circle', style: tt.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Finding one small thing that could help right now.',
              textAlign: TextAlign.center,
              style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme cs, TextTheme tt) {
    return ListView(
      key: const ValueKey('error'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        Icon(Icons.cloud_off_outlined, size: 40, color: cs.onSurfaceVariant),
        const SizedBox(height: 16),
        Text('Your check-in is saved', style: tt.headlineMedium),
        const SizedBox(height: 8),
        Text(_error!, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
        const SizedBox(height: 28),
        FilledButton(onPressed: _load, child: const Text('Try again')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _done, child: const Text('Back to Today')),
      ],
    );
  }

  Widget _buildSuggestion(BuildContext context, ColorScheme cs, TextTheme tt) {
    final suggestion = _suggestion!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terra = isDark ? AppColors.dTerra : AppColors.terra;
    final terraDark = isDark ? AppColors.dTerraDark : AppColors.terraDark;
    final terraTint = isDark ? AppColors.dTerraTint : AppColors.terraTint;

    return ListView(
      key: const ValueKey('suggestion'),
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      children: [
        if (suggestion.showCrisisResources) ...[
          Material(
            color: terraTint,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
              side: BorderSide(color: terra),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite_outline, color: terraDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You don't have to carry this alone",
                            style: tt.bodyLarge?.copyWith(color: terraDark, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Call or text 988 any time, or tap for more ways to reach someone now.',
                            style: tt.bodyMedium?.copyWith(color: terraDark),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: terraDark),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        Highlight(
          suggestion.techniqueName,
          color: _tone,
          style: tt.displaySmall?.copyWith(fontSize: 34),
        ),
        const SizedBox(height: 12),
        Text(
          suggestion.description,
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
          decoration: AppElevation.decoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, step) in suggestion.steps.take(3).indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          '${i + 1}',
                          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: cs.onPrimary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(step, style: tt.bodyLarge?.copyWith(height: 1.45)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SectionLabel('Did this help?'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FeedbackChip(
              icon: Icons.thumb_up_outlined,
              activeIcon: Icons.thumb_up,
              label: 'Helpful',
              active: _helpful == true,
              onTap: () => _setHelpful(_helpful == true ? null : true),
            ),
            FeedbackChip(
              icon: Icons.thumb_down_outlined,
              activeIcon: Icons.thumb_down,
              label: 'Not for me',
              active: _helpful == false,
              onTap: () => _setHelpful(_helpful == false ? null : false),
            ),
            FeedbackChip(
              icon: Icons.bookmark_outline,
              activeIcon: Icons.bookmark,
              label: _saved ? 'In your toolkit' : 'Save to toolkit',
              active: _saved,
              onTap: _toggleSaved,
            ),
          ],
        ),
      ],
    );
  }
}
