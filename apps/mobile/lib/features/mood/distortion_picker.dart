import 'package:flutter/material.dart';

const _kDistortions = [
  {'value': 'all_or_nothing', 'label': 'All-or-nothing thinking', 'emoji': '⚫'},
  {'value': 'catastrophizing', 'label': 'Catastrophizing', 'emoji': '💥'},
  {'value': 'mind_reading', 'label': 'Mind reading', 'emoji': '🔮'},
  {'value': 'overgeneralization', 'label': 'Overgeneralization', 'emoji': '🔁'},
  {'value': 'emotional_reasoning', 'label': 'Emotional reasoning', 'emoji': '💭'},
  {'value': 'should_statements', 'label': '"Should" statements', 'emoji': '📋'},
];

class DistortionPicker extends StatefulWidget {
  const DistortionPicker({super.key, required this.onDone, required this.onSkip});

  final void Function(List<String> distortions, String reframe) onDone;
  final VoidCallback onSkip;

  @override
  State<DistortionPicker> createState() => _DistortionPickerState();
}

class _DistortionPickerState extends State<DistortionPicker> {
  final Set<String> _selected = {};
  bool _showReframe = false;
  final _reframeController = TextEditingController();

  @override
  void dispose() {
    _reframeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _showReframe ? 'Reframe the thought' : 'Spot any thinking patterns?',
            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            _showReframe
                ? 'How might you challenge or reframe this?'
                : 'Optional — helps build self-awareness over time.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (!_showReframe) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kDistortions.map((d) {
                final val = d['value']!;
                final sel = _selected.contains(val);
                return FilterChip(
                  label: Text('${d['emoji']} ${d['label']}'),
                  selected: sel,
                  onSelected: (_) => setState(() {
                    if (sel) {
                      _selected.remove(val);
                    } else {
                      _selected.add(val);
                    }
                  }),
                  selectedColor: cs.primaryContainer,
                  checkmarkColor: cs.primary,
                  labelStyle: TextStyle(fontSize: 12, color: sel ? cs.primary : cs.onSurface),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: widget.onSkip,
                  child: const Text('Skip'),
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  FilledButton(
                    onPressed: () => setState(() => _showReframe = true),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    child: const Text('Next'),
                  ),
              ],
            ),
          ] else ...[
            TextField(
              controller: _reframeController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'e.g. "Even if it goes wrong, I can handle it."',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _showReframe = false),
                  child: const Text('Back'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => widget.onDone(
                    _selected.toList(),
                    _reframeController.text.trim(),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
