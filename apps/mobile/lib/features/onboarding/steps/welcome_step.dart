import 'package:flutter/material.dart';
import '../../../core/mood_color.dart';
import '../../../widgets/notebook.dart';
import '../notebook_step.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return NotebookStep(
      action: FilledButton(onPressed: onNext, child: const Text('Get started')),
      children: [
        Text('A little space.', style: tt.displaySmall),
        Highlight('Just for you.', color: moodColor(5), style: tt.displaySmall),
        const SizedBox(height: 16),
        Text(
          'A private space to check in with yourself, every day.',
          style: tt.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 40),
        const SectionLabel('Every mood has a color'),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (i, word) in [
              'Heavy',
              'Low',
              'Okay',
              'Good',
              'Great',
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: moodColor(i * 2 + 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      word,
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
