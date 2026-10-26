import 'package:local_auth/local_auth.dart';
import '../../core/app_lock_state.dart';

final _auth = LocalAuthentication();

Future<bool> isBiometricsAvailable() async {
  try {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  } catch (_) {
    return false;
  }
}

Future<bool> authenticate() async {
  // The prompt backgrounds the app; tell the lock not to re-engage meanwhile.
  AppLockState.authenticating = true;
  try {
    return await _auth.authenticate(
      localizedReason: 'Unlock MindBridge',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
  } catch (_) {
    return false;
  } finally {
    AppLockState.authenticating = false;
  }
}
