import 'package:flutter/material.dart';
import '../../core/mood_color.dart';
import '../../widgets/crisis_fab.dart';
import '../../widgets/notebook.dart';

/// Public marketing screen — the first thing a fresh install shows, ahead of
/// both the onboarding walkthrough and the sign-in form. Mirrors
/// apps/web/src/pages/LandingPage.tsx. "Get started" pushes into the
/// existing five-step [OnboardingFlow]; "Log in" skips straight to
/// [AuthGate] for returning users who don't need the walkthrough again.
class LandingScreen extends StatelessWidget {
  const LandingScreen({
    super.key,
    required this.onGetStarted,
    required this.onLogIn,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'MindBridge',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(onPressed: onLogIn, child: const Text('Log in')),
                  const SizedBox(width: 4),
                  const HelpChip(),
                ],
              ),
              const SizedBox(height: 40),
              Text('Check in with yourself.', style: tt.displaySmall?.copyWith(fontSize: 40)),
              Highlight('In two minutes.', color: moodColor(5), style: tt.displaySmall?.copyWith(fontSize: 40)),
              const SizedBox(height: 16),
              Text(
                'A private mood journal for teens. Say how you feel, write a '
                'line if you want, and get one small, evidence-based thing to '
                'try right away.',
                style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant, height: 1.45),
              ),
              const SizedBox(height: 28),
              FilledButton(onPressed: onGetStarted, child: const Text('Get started free')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: onLogIn, child: const Text('I have an account')),
              const SizedBox(height: 10),
              Text(
                'No cost. No ads. Nothing shared without your say-so.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 36),
              const SectionLabel('Every mood has a color'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, w) in ['Heavy', 'Low', 'Okay', 'Good', 'Great'].indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: moodColor(i * 2 + 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(w, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'None of them means "bad day." Heavy days get calm colors, not alarms.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 32),
              const SectionLabel('What you get'),
              const SizedBox(height: 4),
              const _Feature(
                tone: 7,
                title: 'A coping technique, instantly',
                body: 'Every check-in returns a real CBT technique, like a breathing exercise, '
                    'a grounding method, or a reframe, picked for how you feel right now.',
              ),
              const _Feature(
                tone: 3,
                title: 'Your patterns, over time',
                body: 'Your week at a glance, 30-day trends, and gentle insights about what actually helps.',
              ),
              const _Feature(
                tone: 1,
                title: 'Made for late nights',
                body: 'A dark mode that is easy on the eyes, and crisis help that is always one tap away.',
              ),
              const _Feature(
                tone: 10,
                title: 'Private by design',
                body: 'Your entries are yours. Nobody else can read them. Not even us.',
                last: true,
              ),
              const SizedBox(height: 24),
              Text(
                "If you're in crisis, you're not alone. Call or text 988, or text HOME to 741741.",
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.tone, required this.title, required this.body, this.last = false});

  final double tone;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: cs.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: moodColor(tone), borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: tt.titleMedium),
                const SizedBox(height: 2),
                Text(body, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
