import 'package:flutter/material.dart';
import '../features/mood/mood_log_service.dart';
import 'notebook.dart';

/// Two-step quadrant → word mood-tag picker. Extracted from
/// `mood_log_screen.dart` so the onboarding first-check-in step can reuse the
/// exact same interaction without duplicating it.
class MoodTagPicker extends StatelessWidget {
  const MoodTagPicker({
    super.key,
    required this.quadrant,
    required this.tag,
    required this.onQuadrantChanged,
    required this.onTagChanged,
  });

  final String? quadrant;
  final String? tag;
  final ValueChanged<String?> onQuadrantChanged;
  final ValueChanged<String?> onTagChanged;

  List<Map<String, String>> get _tagsForQuadrant => quadrant == null
      ? []
      : kMoodTags.where((t) => t['quadrant'] == quadrant).toList();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (quadrant == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('Pick a feeling'),
          const SizedBox(height: 10),
          ...kMoodQuadrants.map((q) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onQuadrantChanged(q['value']),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: cs.outline, width: 1.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: Text(q['label']!),
              ),
            );
          }),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                onQuadrantChanged(null);
                onTagChanged(null);
              },
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(
                kMoodQuadrants.firstWhere(
                  (q) => q['value'] == quadrant,
                )['label']!,
                style: tt.bodySmall,
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tagsForQuadrant.map((t) {
            final selected = tag == t['value'];
            return FilterChip(
              label: Text('${t['emoji']} ${t['label']}'),
              selected: selected,
              onSelected: (_) => onTagChanged(t['value']),
              selectedColor: cs.onSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: cs.outline, width: 1.5),
              checkmarkColor: cs.surface,
              labelStyle: TextStyle(
                color: selected ? cs.surface : cs.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
