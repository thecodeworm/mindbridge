import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../core/theme.dart';
import '../../widgets/breathing_circle.dart';
import '../../widgets/crisis_fab.dart';
import '../history/history_service.dart';
import '../help/help_screen.dart';
import 'suggestion_service.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({
    super.key,
    required this.moodLogId,
    required this.userId,
  });

  final String moodLogId;
  final String userId;

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

    final result = await _service.generateSuggestion(
      moodLogId: widget.moodLogId,
      userId: widget.userId,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      _suggestion = result.suggestion;
      _error = result.error;
    });
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terra = isDark ? AppColors.dTerra : AppColors.terra;
    final terraDark = isDark ? AppColors.dTerraDark : AppColors.terraDark;
    final terraTint = isDark ? AppColors.dTerraTint : AppColors.terraTint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your coping technique'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_loading) _buildLoading(),
            if (!_loading && _error != null) _buildError(cs, tt),
            if (!_loading && _error == null && _suggestion != null)
              _buildSuggestion(context, cs, tt, terra, terraDark, terraTint),
          ],
        ),
      ),
      floatingActionButton: const CrisisFab(),
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: AppElevation.decoration(context),
      child: Center(
        child: BreathingCircle(
          colors: [moodColor(1), moodColor(5.5), moodColor(10)],
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _error!,
              style: TextStyle(color: cs.error, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your mood was saved — you can try generating a suggestion again.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _load, child: const Text('Try again')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _done, child: const Text('Done')),
        ],
      ),
    );
  }

  Widget _buildSuggestion(
    BuildContext context,
    ColorScheme cs,
    TextTheme tt,
    Color terra,
    Color terraDark,
    Color terraTint,
  ) {
    final suggestion = _suggestion!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (suggestion.showCrisisResources) ...[
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: terraTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: terra),
              ),
              child: Text(
                "If you're in crisis, you're not alone — tap here for crisis resources.",
                style: tt.bodyMedium?.copyWith(color: terraDark),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppElevation.decoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(suggestion.techniqueName, style: tt.titleLarge),
              const SizedBox(height: 8),
              Text(
                suggestion.description,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ...suggestion.steps
                  .take(3)
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.key + 1}. ', style: tt.bodyMedium),
                          Expanded(
                            child: Text(entry.value, style: tt.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 16),
              // Feedback row
              Row(
                children: [
                  Text(
                    'Helpful?',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  _FeedbackButton(
                    icon: '👍',
                    active: _helpful == true,
                    onTap: () => _setHelpful(_helpful == true ? null : true),
                  ),
                  const SizedBox(width: 4),
                  _FeedbackButton(
                    icon: '👎',
                    active: _helpful == false,
                    onTap: () => _setHelpful(_helpful == false ? null : false),
                  ),
                  const Spacer(),
                  _FeedbackButton(
                    icon: _saved ? '🔖' : '🏷️',
                    active: _saved,
                    onTap: _toggleSaved,
                    tooltip: _saved ? 'Remove from toolkit' : 'Save to toolkit',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _done, child: const Text('Done')),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.active,
    required this.onTap,
    this.tooltip,
  });

  final String icon;
  final bool active;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? cs.primaryContainer : Colors.transparent,
            border: Border.all(color: active ? cs.primary : cs.outline),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: const TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
