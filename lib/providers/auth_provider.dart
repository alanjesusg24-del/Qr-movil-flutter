import 'package:flutter/foundation.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

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
    print('Inicializando AuthProvider...');
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay token guardado
      final hasToken = await _storage.hasToken();
      print('[SEARCH] ¿Tiene token guardado? $hasToken');

      if (hasToken) {
        // Obtener token y configurar en ApiService
        final token = await _storage.getToken();
        print('[TOKEN] Token recuperado: ${token?.substring(0, 10)}...');

        if (token != null) {
          ApiService.setAuthToken(token);
          print('[OK] Token configurado en ApiService');
        }

        // Intentar obtener usuario guardado localmente primero
        final savedUser = await _storage.getUser();
        print('Usuario guardado localmente: ${savedUser?.email}');

        if (savedUser != null) {
          // Usar usuario guardado localmente
          _user = savedUser;
          _status = AuthStatus.authenticated;
          print('[OK] Usuario autenticado (desde storage local)');

          // Intentar actualizar desde el servidor en segundo plano (sin bloquear)
          _authService.getCurrentUser().then((updatedUser) {
            if (updatedUser != null) {
              print('[OK] Usuario actualizado desde servidor');
              _user = updatedUser;
              notifyListeners();
            }
          }).catchError((e) {
            print('[WARN] No se pudo actualizar usuario desde servidor (continuando con datos locales): $e');
          });
        } else {
          // No hay usuario local, intentar obtener del servidor
          print('[WARN] No hay usuario guardado localmente, intentando obtener del servidor...');
          final user = await _authService.getCurrentUser();

          if (user != null) {
            _user = user;
            _status = AuthStatus.authenticated;
            print('[OK] Usuario obtenido del servidor');
          } else {
            print('[ERROR] No se pudo obtener usuario del servidor, cerrando sesión');
            _status = AuthStatus.unauthenticated;
            await _storage.clearAuthData();
            ApiService.setAuthToken(null);
          }
        }
      } else {
        print('[INFO] No hay token guardado, usuario no autenticado');
        _status = AuthStatus.unauthenticated;
        ApiService.setAuthToken(null);
      }

      // Verificar disponibilidad de biometría
      _biometricAvailable = await _biometricService.isAvailable();
      print('[AUTH] Biometría disponible: $_biometricAvailable');
    } catch (e) {
      print('[ERROR] Error al inicializar auth provider: $e');

      // Si hay error pero tenemos datos locales, mantener la sesión
      final savedUser = await _storage.getUser();
      if (savedUser != null) {
        print('[WARN] Error en inicialización pero hay usuario guardado, manteniendo sesión');
        _user = savedUser;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } finally {
      _isLoading = false;
      print('[OK] AuthProvider inicializado: $_status');
      notifyListeners();
    }
  }

  /// Registro con email y contraseña
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? deviceId, // OPCIONAL
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        password: password,
        deviceId: deviceId,
      );

      if (response.success) {
        print('[OK] Registro exitoso: ${response.user?.email}');
        print('[TOKEN] Token recibido: ${response.token?.substring(0, 10) ?? "SIN TOKEN"}...');

        // Configurar token en ApiService
        if (response.token != null) {
          ApiService.setAuthToken(response.token);
          print('[OK] Token configurado en ApiService después de registro');
        } else {
          print('[ERROR] ERROR: Registro exitoso pero SIN token');
        }

        _user = response.user;
        _status = AuthStatus.authenticated;
        return true;
      }

      _errorMessage = response.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error al crear la cuenta: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con email y contraseña
  Future<bool> login({
    required String email,
    required String password,
    String? deviceId, // OPCIONAL
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
        deviceId: deviceId,
      );

      if (response.success) {
        print('[OK] Login con Email exitoso: ${response.user?.email}');
        print('[TOKEN] Token recibido: ${response.token?.substring(0, 10) ?? "SIN TOKEN"}...');

        // Configurar token en ApiService
        if (response.token != null) {
          ApiService.setAuthToken(response.token);
          print('[OK] Token configurado en ApiService después de Email login');
        } else {
          print('[ERROR] ERROR: Login Email exitoso pero SIN token');
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
      _errorMessage = 'Error al iniciar sesión: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login con Google
  Future<bool> loginWithGoogle(String deviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.loginWithGoogle(deviceId);

      if (response.success) {
        print('[OK] Login con Google exitoso: ${response.user?.email}');
        print('[TOKEN] Token recibido: ${response.token?.substring(0, 10) ?? "SIN TOKEN"}...');

        // Configurar token en ApiService
        if (response.token != null) {
          ApiService.setAuthToken(response.token);
          print('[OK] Token configurado en ApiService después de Google login');
        } else {
          print('[ERROR] ERROR: Login Google exitoso pero SIN token');
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
      print('[OK] Sesión cerrada y token limpiado');

      // Limpiar base de datos local
      try {
        await DatabaseService.instance.deleteAllOrders();
        print('[OK] Base de datos local limpiada');
      } catch (e) {
        print('[WARN] Error al limpiar base de datos local: $e');
      }
    } catch (e) {
      print('[WARN] Error al cerrar sesión en backend: $e');
      // Limpiar token de ApiService aunque falle el backend
      ApiService.setAuthToken(null);
      print('[OK] Token limpiado localmente');

      // Limpiar base de datos local incluso si falla el logout
      try {
        await DatabaseService.instance.deleteAllOrders();
        print('[OK] Base de datos local limpiada');
      } catch (e) {
        print('[WARN] Error al limpiar base de datos local: $e');
      }
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
