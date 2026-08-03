import 'package:local_auth/local_auth.dart';

final _auth = LocalAuthentication();

Future<bool> isBiometricsAvailable() async {
  try {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  } catch (_) {
    return false;
  }
}

Future<bool> authenticate() async {
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
  }
}
