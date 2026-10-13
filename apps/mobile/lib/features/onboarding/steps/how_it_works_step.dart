import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/motion.dart';

const _kFrames = [
  {'emoji': '🎚️', 'title': 'Slide to how you feel', 'subtitle': 'A quick 1 to 10 check-in.'},
  {'emoji': '🏷️', 'title': 'Pick a word', 'subtitle': 'Anxious, calm, proud, whatever fits.'},
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _kIntroCopy[widget.personalization] ?? "Here's a quick look at how it works:",
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 160,
            child: AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.standardDecelerate,
              switchOutCurve: AppMotion.standardAccelerate,
              child: Column(
                key: ValueKey(_frame),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(frame['emoji']!, style: const TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(
                    frame['title']!,
                    textAlign: TextAlign.center,
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    frame['subtitle']!,
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_kFrames.length, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _frame ? cs.primary : cs.outline,
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          FilledButton(onPressed: widget.onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}
