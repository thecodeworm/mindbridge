import 'package:flutter/material.dart';
import '../../../core/elevation.dart';
import '../../../core/mood_color.dart';
import '../../../widgets/breathing_circle.dart';
import '../../../widgets/felt_mood_slider.dart';
import '../../../widgets/mood_tag_picker.dart';

/// A small, honest sample bank keyed by quadrant — NOT a real Claude Haiku
/// call. There's no session/user_id yet at this point in onboarding, so a
/// live Edge Function call isn't possible without a pre-auth write; this
/// preview is explicitly labeled as a sample rather than presented as real
/// AI output. The user's actual first check-in happens for real, through
/// the unmodified `generate-suggestion` pipeline, right after they sign up.
const _kSampleTechniques = {
  'high-pleasant': (
    name: 'Savoring the moment',
    steps: [
      'Pause and name one specific thing that felt good just now.',
      "Notice where you feel it in your body — that's the savoring.",
      'Write one sentence about it so future-you can look back on it.',
    ],
  ),
  'high-unpleasant': (
    name: 'Box breathing',
    steps: [
      'Breathe in slowly for 4 counts.',
      'Hold for 4 counts, then breathe out for 4 counts.',
      'Hold empty for 4 counts. Repeat 4 times.',
    ],
  ),
  'low-pleasant': (
    name: 'Progressive muscle relaxation',
    steps: [
      'Tense your shoulders for 5 seconds, then release.',
      'Move down through your arms, hands, and legs the same way.',
      'Notice the difference between tense and relaxed.',
    ],
  ),
  'low-unpleasant': (
    name: 'Grounding: 5-4-3-2-1',
    steps: [
      'Name 5 things you can see, 4 you can touch, 3 you can hear.',
      'Name 2 things you can smell, 1 you can taste.',
      "Notice you're here, right now, safe.",
    ],
  ),
};

/// Onboarding screen 5 — a real mood pick (local only, nothing written yet)
/// followed by a clearly-labeled sample suggestion, then account creation.
/// docs/research/00-design-direction.md §6.5.
class FirstCheckinStep extends StatefulWidget {
  const FirstCheckinStep({
    super.key,
    required this.onCreateAccount,
    required this.onHaveAccount,
  });

  final void Function(double score, String tag) onCreateAccount;
  final VoidCallback onHaveAccount;

  @override
  State<FirstCheckinStep> createState() => _FirstCheckinStepState();
}

class _FirstCheckinStepState extends State<FirstCheckinStep> {
  double _score = 5;
  String? _quadrant;
  String? _tag;
  bool _generating = false;
  bool _showPreview = false;

  Future<void> _reveal() async {
    setState(() => _generating = true);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _generating = false;
      _showPreview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = moodColor(_score);

    if (_showPreview) {
      final sample = _kSampleTechniques[_quadrant] ?? _kSampleTechniques['low-pleasant']!;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                "Here's what you'll get after every real check-in:",
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppElevation.decoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.name,
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    ...sample.steps.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${e.key + 1}. ${e.value}', style: tt.bodyMedium),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => widget.onCreateAccount(_score, _tag!),
                child: const Text('Save this — create my account'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.onHaveAccount,
                child: const Text('I already have an account'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            "Let's try it — how are you feeling right now?",
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mood score', style: tt.bodyMedium),
              Text(
                '${_score.round()}',
                style: tt.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          FeltMoodSlider(value: _score, onChanged: (v) => setState(() => _score = v)),
          const SizedBox(height: 16),
          MoodTagPicker(
            quadrant: _quadrant,
            tag: _tag,
            onQuadrantChanged: (v) => setState(() => _quadrant = v),
            onTagChanged: (v) => setState(() => _tag = v),
          ),
          const SizedBox(height: 32),
          if (_generating)
            Center(child: BreathingCircle(color: color, size: 72))
          else
            FilledButton(
              onPressed: _tag == null ? null : _reveal,
              child: const Text('See what you\'d get'),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
