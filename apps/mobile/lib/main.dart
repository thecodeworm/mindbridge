import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/app_lock_state.dart';
import 'core/env.dart';
import 'core/onboarding_state.dart';
import 'core/recovery_state.dart';
import 'core/secure_storage.dart';
import 'core/theme_controller.dart';

const bool _enableFlutterDriver = bool.fromEnvironment(
  'ENABLE_FLUTTER_DRIVER',
);

Future<void> main() async {
  // enableFlutterDriverExtension() creates its own binding — calling it
  // after WidgetsFlutterBinding.ensureInitialized() throws
  // ("Binding is already initialized"). Pick exactly one.
  if (_enableFlutterDriver) {
    enableFlutterDriverExtension();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );
  await ThemeController.load();
  await RecoveryState.load();
  await AppLockState.init(
    hasSession: Supabase.instance.client.auth.currentSession != null,
  );
  await OnboardingState.load();
  if (Supabase.instance.client.auth.currentSession != null) {
    // Existing logged-in users updating the app never see onboarding.
    await OnboardingState.set(true);
  }

  runApp(const App());
}
