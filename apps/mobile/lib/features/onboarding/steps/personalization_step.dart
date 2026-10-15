import 'package:flutter/material.dart';
import '../../../core/mood_color.dart';
import '../../../widgets/notebook.dart';
import '../notebook_step.dart';

/// Onboarding screen 3 — one tap-only question, chips not text input.
/// Tailors copy on the next screen only; never gates progress (the CTA is
/// always enabled). docs/research/00-design-direction.md §6.3.
const kPersonalizationOptions = [
  {'value': 'track', 'emoji': '📈', 'label': 'Track my mood'},
  {'value': 'stress', 'emoji': '🌊', 'label': 'Manage stress & anxiety'},
  {'value': 'habits', 'emoji': '🌱', 'label': 'Build better habits'},
  {'value': 'curious', 'emoji': '👋', 'label': 'Just exploring'},
];

class PersonalizationStep extends StatelessWidget {
  const PersonalizationStep({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onNext,
  });

  final String? selected;
  final ValueChanged<String?> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const icons = [
      Icons.show_chart,
      Icons.waves_outlined,
      Icons.spa_outlined,
      Icons.explore_outlined,
    ];
    return NotebookStep(
      action: FilledButton(onPressed: onNext, child: const Text('Next')),
      children: [
        Text('What brings', style: tt.displaySmall),
        Highlight('you here?', color: moodColor(7), style: tt.displaySmall),
        const SizedBox(height: 16),
        Text(
          'Totally optional. It just helps us tailor a few things.',
          style: tt.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 32),
        const SectionLabel('Pick what fits'),
        const SizedBox(height: 10),
        for (final (i, o) in kPersonalizationOptions.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilterChip(
              avatar: Icon(
                icons[i],
                size: 20,
                color: selected == o['value'] ? cs.surface : cs.onSurface,
              ),
              label: Text(o['label']!),
              selected: selected == o['value'],
              onSelected: (_) =>
                  onSelected(selected == o['value'] ? null : o['value']),
              selectedColor: cs.onSurface,
              checkmarkColor: cs.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: cs.outline, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              labelStyle: TextStyle(
                color: selected == o['value'] ? cs.surface : cs.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}
