import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:flutter/services.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Verificar si el dispositivo tiene biometría disponible
  Future<bool> isAvailable() async {
    try {
      final bool canCheckBiometrics = await _auth.canCheckBiometrics;
      final bool isDeviceSupported = await _auth.isDeviceSupported();

      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Obtener tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Autenticar con biometría
  Future<bool> authenticate({
    String localizedReason = 'Por favor, autentícate para continuar',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        print('Biometría no disponible');
      } else if (e.code == auth_error.notEnrolled) {
        print('No hay biometría registrada');
      } else if (e.code == auth_error.lockedOut || e.code == auth_error.permanentlyLockedOut) {
        print('Biometría bloqueada');
      } else {
        print('Error de autenticación biométrica: ${e.message}');
      }
      return false;
    } catch (e) {
      print('Error inesperado en autenticación biométrica: $e');
      return false;
    }
  }

  /// Verificar si tiene huella digital
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint);
  }

  /// Verificar si tiene Face ID/reconocimiento facial
  Future<bool> hasFaceRecognition() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Obtener nombre descriptivo de la biometría disponible
  Future<String> getBiometricTypeName() async {
    final biometrics = await getAvailableBiometrics();

    if (biometrics.isEmpty) return 'Biometría';

    if (biometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometrics.contains(BiometricType.fingerprint)) {
      return 'Huella Digital';
    } else if (biometrics.contains(BiometricType.iris)) {
      return 'Reconocimiento de Iris';
    } else {
      return 'Biometría';
    }
  }

  /// Autenticar para login
  Future<bool> authenticateForLogin() async {
    return await authenticate(
      localizedReason: 'Autentícate para iniciar sesión',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  /// Autenticar para habilitar biometría
  Future<bool> authenticateToEnable() async {
    return await authenticate(
      localizedReason: 'Autentícate para habilitar el acceso biométrico',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  /// Autenticar para acciones sensibles
  Future<bool> authenticateForSensitiveAction(String action) async {
    return await authenticate(
      localizedReason: 'Autentícate para $action',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }
}
