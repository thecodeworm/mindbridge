import 'package:flutter/material.dart';
import '../../core/elevation.dart';
import '../../core/mood_color.dart';
import '../../widgets/breathing_circle.dart';
import '../../widgets/crisis_fab.dart';

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'MindBridge',
                      style: tt.titleLarge?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onLogIn,
                    child: const Text('Log in'),
                  ),
                  const SizedBox(width: 4),
                  const HelpChip(),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  height: 150,
                  width: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      BreathingCircle(
                        colors: [moodColor(1), moodColor(5.5), moodColor(10)],
                        size: 150,
                      ),
                      const Text('🌤️', style: TextStyle(fontSize: 40)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Check in with yourself.',
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'In under two minutes.',
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'MindBridge is a private mood tracker for teens. Rate how you '
                'feel, jot a quick note if you want, and get an '
                'evidence-based coping technique picked for you, instantly, '
                'every time.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onGetStarted,
                child: const Text("Get started free"),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onLogIn,
                child: const Text('I have an account'),
              ),
              const SizedBox(height: 8),
              Text(
                "No cost. No ads. Nothing shared without your say-so.",
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 28),
              _FeatureCard(
                emoji: '🧠',
                title: 'A coping technique, instantly',
                body: 'Every check-in returns a real CBT technique, like a '
                    'breathing exercise, a grounding method, or a reframe, '
                    'picked for how you feel right now.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                emoji: '📈',
                title: 'See your patterns',
                body: 'Mood trends over 7 and 30 days, streaks, and gentle '
                    'insights that surface what actually helps you.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                emoji: '🌙',
                title: 'Built for hard days',
                body: 'Warm, dark-mode-first design for late-night '
                    'journaling. Crisis resources are always one tap away, '
                    'never a red alarm.',
              ),
              const SizedBox(height: 12),
              _FeatureCard(
                emoji: '🔒',
                title: 'Private by design',
                body: 'Your entries are yours. Row-level security means no '
                    'one else can read your data. Not even us.',
              ),
              const SizedBox(height: 28),
              Text(
                'Every mood has a place. No shade means "bad day."',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Row(
                  children: [1, 3, 5, 7, 10]
                      .map((s) => Expanded(
                            child: Container(height: 10, color: moodColor(s.toDouble())),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "If you're in crisis, you're not alone. Call or text 988, "
                'or text HOME to 741741.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppElevation.decoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(body, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
