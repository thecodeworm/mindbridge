import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/motion.dart';
import '../../../core/elevation.dart';
import '../../../core/mood_color.dart';
import '../../../widgets/notebook.dart';
import '../notebook_step.dart';

const _kFrames = [
  {
    'emoji': '🎚️',
    'title': 'Slide to how you feel',
    'subtitle': 'A quick 1 to 10 check-in.',
  },
  {
    'emoji': '🏷️',
    'title': 'Pick a word',
    'subtitle': 'Anxious, calm, proud, whatever fits.',
  },
  {
    'emoji': '💡',
    'title': 'Get an AI coping technique',
    'subtitle': 'A personalized CBT tool, every time.',
  },
];

const _kIntroCopy = {
  'track': "Here's how tracking your mood works:",
  'stress': "Here's how we help you manage stress:",
  'habits': "Here's how the daily habit works:",
  'curious': "Here's a quick look at how it works:",
};

/// Onboarding screen 4 — a short looped explainer (not commissioned
/// illustration, an explicit non-goal per the design doc) cycling through
/// the core loop: slider → word → AI suggestion.
/// docs/research/00-design-direction.md §6.4.
class HowItWorksStep extends StatefulWidget {
  const HowItWorksStep({
    super.key,
    required this.onNext,
    required this.personalization,
  });

  final VoidCallback onNext;
  final String? personalization;

  @override
  State<HowItWorksStep> createState() => _HowItWorksStepState();
}

class _HowItWorksStepState extends State<HowItWorksStep> {
  int _frame = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % _kFrames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final frame = _kFrames[_frame];

    const icons = [
      Icons.tune_outlined,
      Icons.sell_outlined,
      Icons.lightbulb_outline,
    ];
    return NotebookStep(
      action: FilledButton(onPressed: widget.onNext, child: const Text('Next')),
      children: [
        Text('Small steps.', style: tt.displaySmall),
        Highlight('Every day.', color: moodColor(9), style: tt.displaySmall),
        const SizedBox(height: 16),
        Text(
          _kIntroCopy[widget.personalization] ??
              "Here's a quick look at how it works:",
          style: tt.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 32),
        const SectionLabel('How it works'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppElevation.decoration(context),
          child: AnimatedSwitcher(
            duration: AppMotion.medium,
            switchInCurve: AppMotion.standardDecelerate,
            switchOutCurve: AppMotion.standardAccelerate,
            child: Column(
              key: ValueKey(_frame),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_frame + 1}',
                        style: tt.labelLarge?.copyWith(color: cs.onPrimary),
                      ),
                    ),
                    const Spacer(),
                    Icon(icons[_frame], color: cs.primary),
                  ],
                ),
                const SizedBox(height: 24),
                Text(frame['title']!, style: tt.titleLarge),
                const SizedBox(height: 8),
                Text(
                  frame['subtitle']!,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            _kFrames.length,
            (i) => Container(
              margin: const EdgeInsets.only(right: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: i == _frame ? cs.onSurface : cs.outline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
