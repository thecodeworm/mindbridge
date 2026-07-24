import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final event = snapshot.data?.event;
        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;

        // The reset-password deep link delivers a recovery session, not a
        // normal sign-in — route to the reset form instead of HomeScreen
        // until the user sets a new password (which signs them out again).
        if (event == AuthChangeEvent.passwordRecovery) {
          return const ResetPasswordScreen();
        }

        if (session != null) {
          return const HomeScreen();
        }

        return _showSignUp
            ? SignUpScreen(onSwitchToSignIn: () => setState(() => _showSignUp = false))
            : SignInScreen(onSwitchToSignUp: () => setState(() => _showSignUp = true));
      },
    );
  }
}
