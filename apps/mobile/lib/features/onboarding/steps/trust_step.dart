import 'package:flutter/material.dart';
import '../../../core/elevation.dart';

/// Onboarding screen 2 — trust/privacy. Ranked more important for a teen
/// mental-health app than a general wellness app (Wysa's anonymity-first
/// framing, per docs/research/00-design-direction.md §6.2).
class TrustStep extends StatelessWidget {
  const TrustStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('🔒', textAlign: TextAlign.center, style: TextStyle(fontSize: 56)),
          const SizedBox(height: 24),
          Text(
            'Your entries are private.',
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Only you can see them.',
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppElevation.decoration(context),
            child: Text(
              'Not friends, not family, not even MindBridge staff can read '
              'your mood logs or journal entries. What you write here stays yours.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}
