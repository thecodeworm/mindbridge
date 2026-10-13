import 'package:flutter/material.dart';
import '../../core/motion.dart';
import '../../core/onboarding_state.dart';
import 'steps/first_checkin_step.dart';
import 'steps/how_it_works_step.dart';
import 'steps/personalization_step.dart';
import 'steps/trust_step.dart';
import 'steps/welcome_step.dart';

const _kStepCount = 5;

/// Five-screen onboarding flow, shown once per install ahead of `AuthGate`.
/// docs/research/00-design-direction.md §6 — dots not a percentage bar,
/// swipeable via PageView's native shared-axis-style drag, skippable from
/// screen 3 onward (never before the privacy screen).
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, required this.onFinished});

  /// Called after finish/skip, once the persisted completed flag is set.
  final VoidCallback onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pageController = PageController();
  int _page = 0;
  String? _personalization;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: AppMotion.medium,
      curve: AppMotion.standard,
    );
  }

  void _finish({double? score, String? tag}) {
    if (score != null && tag != null) {
      OnboardingState.pendingScore = score;
      OnboardingState.pendingTag = tag;
    }
    OnboardingState.set(true);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: Skip lives in its own row so it never collides with
            // a step's headline (it used to float over the content).
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedOpacity(
                    opacity: _page >= 2 ? 1 : 0,
                    duration: AppMotion.micro,
                    child: IgnorePointer(
                      ignoring: _page < 2,
                      child: TextButton(
                        onPressed: () => _finish(),
                        child: const Text('Skip'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  WelcomeStep(onNext: () => _goTo(1)),
                  TrustStep(onNext: () => _goTo(2)),
                  PersonalizationStep(
                    selected: _personalization,
                    onSelected: (v) => setState(() => _personalization = v),
                    onNext: () => _goTo(3),
                  ),
                  HowItWorksStep(
                    personalization: _personalization,
                    onNext: () => _goTo(4),
                  ),
                  FirstCheckinStep(
                    onCreateAccount: (score, tag) => _finish(score: score, tag: tag),
                    onHaveAccount: () => _finish(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_kStepCount, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: AppMotion.micro,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: active ? cs.primary : cs.outline,
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
