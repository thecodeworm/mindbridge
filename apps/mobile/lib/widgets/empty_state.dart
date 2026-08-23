import 'package:flutter/material.dart';

/// Notion-style empty state: monochrome icon + headline + one line of copy +
/// a single CTA that deep-links into the relevant action (never a generic
/// "go home" button). Used wherever a list/collection can be genuinely empty.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.copy,
    this.ctaLabel,
    this.onCta,
  });

  final IconData icon;
  final String headline;
  final String copy;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(headline, style: tt.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            copy,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onCta, child: Text(ctaLabel!)),
          ],
        ],
      ),
    );
  }
}
