import 'package:flutter/material.dart';
import '../../core/models.dart';

class ActivityTagPicker extends StatelessWidget {
  const ActivityTagPicker({
    super.key,
    required this.tags,
    required this.selected,
    required this.onChanged,
  });

  final List<ActivityTag> tags;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = selected.contains(tag.id);
        return FilterChip(
          label: Text('${tag.emoji} ${tag.label}'),
          selected: isSelected,
          onSelected: (_) {
            final next = Set<String>.from(selected);
            if (isSelected) {
              next.remove(tag.id);
            } else {
              next.add(tag.id);
            }
            onChanged(next);
          },
          selectedColor: cs.primaryContainer,
          checkmarkColor: cs.primary,
          labelStyle: TextStyle(
            color: isSelected ? cs.primary : cs.onSurface,
          ),
        );
      }).toList(),
    );
  }
}
