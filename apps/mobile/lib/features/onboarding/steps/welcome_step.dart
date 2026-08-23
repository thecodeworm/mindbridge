import 'package:flutter/material.dart';
import '../../../core/mood_color.dart';
import '../../../widgets/breathing_circle.dart';

/// Onboarding screen 1 — wordmark over the breathing mood-ramp, one-line
/// value prop, single CTA. docs/research/00-design-direction.md §6.1.
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              BreathingCircle(
                colors: [moodColor(1), moodColor(5.5), moodColor(10)],
                size: 220,
                cycleDuration: const Duration(seconds: 5),
              ),
              Text(
                'MindBridge',
                textAlign: TextAlign.center,
                style: tt.displaySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'A private space to check in with yourself, every day.',
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: onNext,
            child: const Text('Get started'),
          ),
        ],
      ),
    );
  }
}
