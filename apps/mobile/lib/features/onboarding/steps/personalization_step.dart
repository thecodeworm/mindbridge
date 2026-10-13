import 'package:flutter/material.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What brings you here?',
            textAlign: TextAlign.center,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Totally optional. It just helps us tailor a few things.',
            textAlign: TextAlign.center,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: kPersonalizationOptions.map((o) {
              final isSelected = selected == o['value'];
              return FilterChip(
                label: Text('${o['emoji']} ${o['label']}'),
                selected: isSelected,
                onSelected: (_) =>
                    onSelected(isSelected ? null : o['value']),
                selectedColor: cs.primaryContainer,
                checkmarkColor: cs.primary,
                labelStyle: TextStyle(color: isSelected ? cs.primary : cs.onSurface),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          FilledButton(onPressed: onNext, child: const Text('Next')),
        ],
      ),
    );
  }
}
