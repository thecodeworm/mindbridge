import 'package:flutter/material.dart';
import '../../../core/elevation.dart';
import '../../../core/mood_color.dart';
import '../../../widgets/notebook.dart';
import '../notebook_step.dart';

class TrustStep extends StatelessWidget {
  const TrustStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return NotebookStep(
      action: FilledButton(onPressed: onNext, child: const Text('Next')),
      children: [
        Text('Your entries are', style: tt.displaySmall),
        Highlight('private.', color: moodColor(3), style: tt.displaySmall),
        const SizedBox(height: 16),
        Text(
          'Only you can see them.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 32),
        const SectionLabel('Your space'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppElevation.decoration(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, color: cs.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Not friends, not family, not even MindBridge staff can read your mood logs or journal entries. What you write here stays yours.',
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
