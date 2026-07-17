import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import 'suggestion_service.dart';

class SuggestionScreen extends StatefulWidget {
  const SuggestionScreen({super.key, required this.moodLogId, required this.userId});

  final String moodLogId;
  final String userId;

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> {
  late final SuggestionService _service = SuggestionService(Supabase.instance.client);

  SuggestionResult? _suggestion;
  bool _loading = true;
  String? _error;

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
            if (_loading) _buildSkeleton(cs),
            if (!_loading && _error != null) _buildError(cs, tt),
            if (!_loading && _error == null && _suggestion != null)
              _buildSuggestion(context, cs, tt, terra, terraDark, terraTint),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(ColorScheme cs) {
    Widget block(double width, double height) => Container(
          width: width,
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(180, 24),
          const SizedBox(height: 8),
          block(double.infinity, 16),
          block(240, 16),
          const SizedBox(height: 12),
          block(double.infinity, 16),
          block(double.infinity, 16),
          block(200, 16),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_error!, style: TextStyle(color: cs.error, fontSize: 14)),
          ),
          const SizedBox(height: 12),
          Text(
            'Your mood was saved — you can try generating a suggestion again.',
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _load,
            child: const Text('Try again'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _done,
            child: const Text('Done'),
          ),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: terraTint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: terra),
            ),
            child: Text(
              "If you're in crisis, you're not alone — call or text 988, or text HOME to 741741.",
              style: tt.bodyMedium?.copyWith(color: terraDark),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline),
          ),
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
              ...suggestion.steps.take(3).toList().asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${entry.key + 1}. ', style: tt.bodyMedium),
                          Expanded(child: Text(entry.value, style: tt.bodyMedium)),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _done,
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
