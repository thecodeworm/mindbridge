import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_lock_state.dart';
import 'core/onboarding_state.dart';
import 'core/recovery_state.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'features/auth/app_lock_service.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/onboarding/landing_screen.dart';
import 'features/onboarding/onboarding_flow.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'MindBridge',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const _AppLockWrapper(),
        onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const AuthGate()),
      ),
    );
  }
}

// Wraps AuthGate with a lock screen on app resume when app lock is enabled.
class _AppLockWrapper extends StatefulWidget {
  const _AppLockWrapper();

  @override
  State<_AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<_AppLockWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Covers the content before the OS takes its app-switcher snapshot.
        if (AppLockState.enabled.value && !AppLockState.authenticating) {
          AppLockState.obscured.value = true;
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        AppLockState.lock();
      case AppLifecycleState.resumed:
        AppLockState.obscured.value = false;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLockState.obscured,
      builder: (context, obscured, content) => Stack(
        fit: StackFit.expand,
        children: [
          content!,
          if (obscured)
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: AppLockState.locked,
        builder: (context, locked, child) {
          if (locked) {
            return _LockScreen(onUnlocked: AppLockState.unlock);
          }
          return child!;
        },
        child: const _OnboardingGate(),
      ),
    );
  }
}

enum _Stage { landing, onboarding, auth }

/// Records the demo video: `--dart-define=DEMO_MODE=true` replays the
/// landing -> onboarding -> auth sequence on every cold launch, ignoring the
/// persisted "onboarding completed" flag. Off by default.
const bool _kDemoMode = bool.fromEnvironment('DEMO_MODE');

/// First-run front door. Returning users (onboarding already completed or
/// skipped, or an existing session, see main.dart) go straight to
/// [AuthGate]; first-time installs see the landing screen, then onboarding.
class _OnboardingGate extends StatefulWidget {
  const _OnboardingGate();

  @override
  State<_OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<_OnboardingGate> {
  late _Stage _stage =
      !_kDemoMode && OnboardingState.completed.value ? _Stage.auth : _Stage.landing;

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.landing:
        return LandingScreen(
          onGetStarted: () => setState(() => _stage = _Stage.onboarding),
          onLogIn: () {
            OnboardingState.set(true);
            setState(() => _stage = _Stage.auth);
          },
        );
      case _Stage.onboarding:
        return OnboardingFlow(
          onFinished: () => setState(() => _stage = _Stage.auth),
        );
      case _Stage.auth:
        return const AuthGate();
    }
  }
}

class _LockScreen extends StatefulWidget {
  const _LockScreen({required this.onUnlocked});
  final VoidCallback onUnlocked;

  @override
  State<_LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<_LockScreen> {
  bool _attempting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _attempt();
  }

  Future<void> _attempt() async {
    setState(() {
      _attempting = true;
      _error = null;
    });
    final ok = await authenticate();
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _attempting = false;
        _error = 'Authentication failed. Try again.';
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    widget.onUnlocked();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: cs.primary),
              const SizedBox(height: 16),
              Text('MindBridge is locked', style: tt.titleMedium),
              const SizedBox(height: 8),
              if (_error != null)
                Text(_error!, style: tt.bodySmall?.copyWith(color: cs.error)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _attempting ? null : _attempt,
                child: Text(_attempting ? 'Authenticating…' : 'Unlock'),
              ),
              const SizedBox(height: 8),
              // Escape hatch: a phone with no screen lock set up (or a failed
              // biometric) must never leave someone permanently locked out.
              TextButton(
                onPressed: _attempting ? null : _signOut,
                child: const Text('Sign out instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showSignUp = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        RecoveryState.set(true);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: RecoveryState.isRecovery,
      builder: (context, isRecovery, _) {
        if (isRecovery) {
          return const ResetPasswordScreen();
        }

        return StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session =
                snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;

            if (session != null) {
              return const MainShell();
            }

            return _showSignUp
                ? SignUpScreen(onSwitchToSignIn: () => setState(() => _showSignUp = false))
                : SignInScreen(onSwitchToSignUp: () => setState(() => _showSignUp = true));
          },
        );
      },
    );
  }
}
