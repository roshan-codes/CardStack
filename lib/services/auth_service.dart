import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final LocalAuthentication _auth;

  AuthService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Checks whether the device hardware supports biometrics or device credentials.
  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported || canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Returns available biometric hardware types (e.g. face, fingerprint).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate using face lock, fingerprint, or device passcode/PIN.
  Future<bool> authenticate({
    String reason = 'Authenticate to access your secure CardStack',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Supports phone lock (passcode/PIN) and face lock
          useErrorDialogs: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
