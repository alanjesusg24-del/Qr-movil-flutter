import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
  emailNotVerified,
  deviceChangePending,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final SecureStorageService _storage = SecureStorageService();
  final BiometricService _biometricService = BiometricService();

  AuthUser? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isLoading = false;
  String? _errorMessage;

  AuthUser? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isBiometricAvailable => _biometricAvailable;

  bool _biometricAvailable = false;

  /// Inicializar provider
  Future<void> initialize() async {
    print('🔄 Inicializando AuthProvider...');
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay token guardado
      final hasToken = await _storage.hasToken();
      print('🔍 ¿Tiene token guardado? $hasToken');

      if (hasToken) {
        // Obtener token y configurar en ApiService
        final token = await _storage.getToken();
        print('🎫 Token recuperado: ${token?.substring(0, 10)}...');

        if (token != null) {
          ApiService.setAuthToken(token);
          print('✅ Token configurado en ApiService');
        }

        // Intentar obtener usuario guardado localmente primero
        final savedUser = await _storage.getUser();
        print('👤 Usuario guardado localmente: ${savedUser?.email}');

        if (savedUser != null) {
          // Usar usuario guardado localmente
          _user = savedUser;

          // Verificar estado del usuario
          if (!savedUser.emailVerified) {
            _status = AuthStatus.emailNotVerified;
            print('⚠️ Email no verificado');
          } else {
            _status = AuthStatus.authenticated;
            print('✅ Usuario autenticado (desde storage local)');
          }

          // Intentar actualizar desde el servidor en segundo plano (sin bloquear)
          _authService.getCurrentUser().then((updatedUser) {
            if (updatedUser != null) {
              print('✅ Usuario actualizado desde servidor');
              _user = updatedUser;
              notifyListeners();
            }
          }).catchError((e) {
            print('⚠️ No se pudo actualizar usuario desde servidor (continuando con datos locales): $e');
          });
        } else {
          // No hay usuario local, intentar obtener del servidor
          print('⚠️ No hay usuario guardado localmente, intentando obtener del servidor...');
          final user = await _authService.getCurrentUser();

          if (user != null) {
            _user = user;

            // Verificar estado del usuario
            if (!user.emailVerified) {
              _status = AuthStatus.emailNotVerified;
            } else {
              _status = AuthStatus.authenticated;
            }
            print('✅ Usuario obtenido del servidor');
          } else {
            print('❌ No se pudo obtener usuario del servidor, cerrando sesión');
            _status = AuthStatus.unauthenticated;
            await _storage.clearAuthData();
            ApiService.setAuthToken(null);
          }
        }
      } else {
        print('ℹ️ No hay token guardado, usuario no autenticado');
        _status = AuthStatus.unauthenticated;
        ApiService.setAuthToken(null);
      }

      // Verificar disponibilidad de biometría
      _biometricAvailable = await _biometricService.isAvailable();
      print('🔐 Biometría disponible: $_biometricAvailable');
    } catch (e) {
      print('❌ Error al inicializar auth provider: $e');

      // Si hay error pero tenemos datos locales, mantener la sesión
      final savedUser = await _storage.getUser();
      if (savedUser != null) {
        print('⚠️ Error en inicialización pero hay usuario guardado, manteniendo sesión');
        _user = savedUser;
        _status = savedUser.emailVerified
            ? AuthStatus.authenticated
            : AuthStatus.emailNotVerified;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } finally {
      _isLoading = false;
      print('✅ AuthProvider inicializado: $_status');
      notifyListeners();
    }
  }

  // MÉTODOS DE EMAIL/PASSWORD DESHABILITADOS
  // Solo usamos Google Sign-In ahora

  /*
  /// Registro (DESHABILITADO)
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String deviceId,
  }) async {
    _errorMessage = 'Registro con email/password no disponible. Usa Google Sign-In.';
    notifyListeners();
    return false;
  }

  /// Login (DESHABILITADO)
  Future<bool> login({
    required String email,
    required String password,
    required String deviceId,
    bool rememberMe = false,
  }) async {
    _errorMessage = 'Login con email/password no disponible. Usa Google Sign-In.';
    notifyListeners();
    return false;
  }
  */

  /// Login con Google
  Future<bool> loginWithGoogle(String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.loginWithGoogle(deviceId);

      if (response.success) {
        print('✅ Login con Google exitoso: ${response.user?.email}');
        print('🎫 Token recibido: ${response.token?.substring(0, 10) ?? "SIN TOKEN"}...');

        // Configurar token en ApiService
        if (response.token != null) {
          ApiService.setAuthToken(response.token);
          print('✅ Token configurado en ApiService después de Google login');
        } else {
          print('❌ ERROR: Login Google exitoso pero SIN token');
        }

        _user = response.user;
        _status = AuthStatus.authenticated;
        return true;
      }

      if (response.requiresDeviceChange) {
        _status = AuthStatus.deviceChangePending;
        _errorMessage = response.message;
        return false;
      }

      _errorMessage = response.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error con Google Sign-In: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con biometría
  Future<bool> loginWithBiometric() async {
    try {
      // Verificar si tiene credenciales guardadas
      final hasToken = await _storage.hasToken();
      if (!hasToken) {
        _errorMessage = 'No hay sesión guardada';
        return false;
      }

      // Autenticar con biometría
      final authenticated = await _biometricService.authenticateForLogin();

      if (authenticated) {
        // Obtener usuario
        final user = await _authService.getCurrentUser();

        if (user != null) {
          _user = user;
          _status = AuthStatus.authenticated;
          notifyListeners();
          return true;
        }
      }

      return false;
    } catch (e) {
      _errorMessage = 'Error con autenticación biométrica: ${e.toString()}';
      return false;
    }
  }

  // MÉTODOS DE VERIFICACIÓN DE EMAIL DESHABILITADOS
  // Google Sign-In no requiere verificación de email

  /*
  /// Verificar email (DESHABILITADO)
  Future<bool> verifyEmail(int userId, String code) async {
    _errorMessage = 'Verificación de email no necesaria con Google Sign-In.';
    notifyListeners();
    return false;
  }

  /// Reenviar código de verificación (DESHABILITADO)
  Future<bool> resendVerificationCode(int userId) async {
    _errorMessage = 'Verificación de email no necesaria con Google Sign-In.';
    notifyListeners();
    return false;
  }
  */

  /// Solicitar cambio de dispositivo
  Future<Map<String, dynamic>?> requestDeviceChange({
    required int userId,
    required String newDeviceId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.requestDeviceChange(
        userId: userId,
        newDeviceId: newDeviceId,
      );

      if (response.success) {
        return {
          'request_id': response.requestId,
          'expires_at': response.expiresAt,
        };
      }

      _errorMessage = response.message;
      return null;
    } catch (e) {
      _errorMessage = 'Error al solicitar cambio: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verificar cambio de dispositivo
  Future<bool> verifyDeviceChange({
    required int requestId,
    required String code,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.verifyDeviceChange(
        requestId: requestId,
        code: code,
        password: password,
      );

      if (response.success && response.user != null) {
        _user = response.user;
        _status = AuthStatus.authenticated;
        return true;
      }

      _errorMessage = response.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al verificar cambio: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;

      // Limpiar token de ApiService
      ApiService.setAuthToken(null);
      print('✅ Sesión cerrada y token limpiado');
    } catch (e) {
      print('⚠️ Error al cerrar sesión en backend: $e');
      // Limpiar token de ApiService aunque falle el backend
      ApiService.setAuthToken(null);
      print('✅ Token limpiado localmente');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Habilitar/deshabilitar biometría
  Future<bool> toggleBiometric(bool enable) async {
    if (enable) {
      // Autenticar primero
      final authenticated = await _biometricService.authenticateToEnable();

      if (authenticated) {
        await _storage.setBiometricEnabled(true);
        notifyListeners();
        return true;
      }

      return false;
    } else {
      await _storage.setBiometricEnabled(false);
      notifyListeners();
      return true;
    }
  }

  // MÉTODO DE CAMBIO DE CONTRASEÑA DESHABILITADO
  // Google Sign-In gestiona las contraseñas externamente

  /*
  /// Cambiar contraseña (DESHABILITADO)
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _errorMessage = 'Gestión de contraseñas no disponible. Google maneja tu seguridad.';
    notifyListeners();
    return false;
  }
  */

  /// Limpiar mensaje de error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Actualizar usuario
  void updateUser(AuthUser user) {
    _user = user;
    notifyListeners();
  }
}
