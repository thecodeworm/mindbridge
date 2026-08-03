import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terraDark = isDark ? AppColors.dTerraDark : AppColors.terraDark;
    final terraTint = isDark ? AppColors.dTerraTint : AppColors.terraTint;
    final terra = isDark ? AppColors.dTerra : AppColors.terra;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisis resources'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: cs.onSurface,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: terraTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: terra),
              ),
              child: Text(
                "You're not alone. Confidential support is available 24/7 — free and judgment-free.",
                style: tt.bodyMedium?.copyWith(color: terraDark),
              ),
            ),
            const SizedBox(height: 20),
            _ResourceCard(
              name: '988 Suicide & Crisis Lifeline',
              description: 'Call or text 988 anytime, 24/7.',
              chips: [
                _Chip(label: 'Call 988', url: 'tel:988'),
                _Chip(label: 'Text 988', url: 'sms:988'),
              ],
              terraDark: terraDark,
              terraTint: terraTint,
              terra: terra,
            ),
            const SizedBox(height: 12),
            _ResourceCard(
              name: 'Crisis Text Line',
              description: 'Text HOME to 741741. Free 24/7 support via text.',
              chips: [
                _Chip(label: 'Text HOME to 741741', url: 'sms:741741?body=HOME'),
              ],
              terraDark: terraDark,
              terraTint: terraTint,
              terra: terra,
            ),
            const SizedBox(height: 12),
            _ResourceCard(
              name: 'The Trevor Project',
              description:
                  'LGBTQ+ youth crisis support. Call 1-866-488-7386 or text START to 678-678.',
              chips: [
                _Chip(label: 'Call Trevor Project', url: 'tel:18664887386'),
                _Chip(label: 'Text START to 678-678', url: 'sms:678678?body=START'),
              ],
              terraDark: terraDark,
              terraTint: terraTint,
              terra: terra,
            ),
            const SizedBox(height: 24),
            Text(
              'MindBridge is a mood-tracking tool, not a crisis service. '
              'If you or someone you know is in immediate danger, call 911.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({
    required this.name,
    required this.description,
    required this.chips,
    required this.terraDark,
    required this.terraTint,
    required this.terra,
  });

  final String name;
  final String description;
  final List<_Chip> chips;
  final Color terraDark;
  final Color terraTint;
  final Color terra;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(description, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.map((chip) {
              return OutlinedButton(
                onPressed: () async {
                  final uri = Uri.parse(chip.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: terraDark,
                  side: BorderSide(color: terra),
                  backgroundColor: terraTint,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(chip.label, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _Chip {
  const _Chip({required this.label, required this.url});
  final String label;
  final String url;
}
