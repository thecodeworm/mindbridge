import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/recovery_state.dart';
import 'core/theme.dart';
import 'core/theme_controller.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/home/home_screen.dart';

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
        home: const AuthGate(),
        // Supabase OAuth deep link delivers /?code=... as a Flutter route.
        // The SDK handles the session exchange; we just need to not crash.
        onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const AuthGate()),
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
    // Only used to *set* the persisted flag when a recovery link is opened.
    // Reading it back happens via RecoveryState.isRecovery below, since the
    // event itself is transient and any later emission (tokenRefreshed,
    // userUpdated, initialSession after a relaunch) would otherwise fall
    // through to HomeScreen.
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
            final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;

            if (session != null) {
              return const HomeScreen();
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
