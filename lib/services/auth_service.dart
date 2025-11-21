import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../config/api_config.dart';
import '../models/auth_user.dart';
import '../models/auth_response.dart';
import '../models/device_change_request.dart';
import 'secure_storage_service.dart';
import 'api_service.dart';

class AuthService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.headers,
    ),
  );

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web Client ID de Google Cloud Console (client_type: 3)
    serverClientId: '473319249019-qcf7ichcssu7p1m0ckbtu954eoop57ss.apps.googleusercontent.com',
  );

  static final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  final SecureStorageService _storage = SecureStorageService();

  static String? _currentToken;
  static String? _deviceId;

  /// Configurar device ID
  static void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// Configurar token en headers
  static void setToken(String token) {
    _currentToken = token;
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remover token
  static void removeToken() {
    _currentToken = null;
    _dio.options.headers.remove('Authorization');
  }

  // MÉTODOS DE EMAIL/PASSWORD DESHABILITADOS - Solo usamos Google Sign-In
  // Si necesitas reactivarlos en el futuro, descomenta estos métodos
  // y restaura los endpoints en ApiConfig

  /*
  /// Registro con email y contraseña (DESHABILITADO)
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String deviceId,
  }) async {
    return AuthResponse(
      success: false,
      message: 'Registro con email/password no disponible. Usa Google Sign-In.',
    );
  }

  /// Login con email y contraseña (DESHABILITADO)
  Future<AuthResponse> login({
    required String email,
    required String password,
    required String deviceId,
    bool rememberMe = false,
  }) async {
    return AuthResponse(
      success: false,
      message: 'Login con email/password no disponible. Usa Google Sign-In.',
    );
  }
  */

  /// Login con Google
  Future<AuthResponse> loginWithGoogle(String deviceId) async {
    try {
      // 1. Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResponse(
          success: false,
          message: 'Inicio de sesión cancelado',
        );
      }

      // 2. Obtener autenticación de Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear credenciales de Firebase (opcional, para verificación)
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in con Firebase
      final firebase_auth.UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('No se pudo autenticar con Firebase');
      }

      // 5. Enviar al backend
      final response = await _dio.post(
        ApiConfig.authLoginGoogle,
        data: {
          'google_id': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? 'Usuario',
          'profile_photo_url': firebaseUser.photoURL,
          'device_id': deviceId,
          'id_token': googleAuth.idToken,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        if (authResponse.success && authResponse.token != null) {
          print('💾 Guardando token en storage (Google): ${authResponse.token!.substring(0, 10)}...');
          await _storage.saveToken(authResponse.token!);
          setToken(authResponse.token!);

          // Si el backend no devuelve el usuario, obtenerlo del servidor
          AuthUser? user = authResponse.user;
          if (user == null) {
            print('⚠️ Usuario no incluido en respuesta Google, obteniendo del servidor...');
            user = await getCurrentUser();
          }

          if (user != null) {
            print('💾 Guardando usuario en storage (Google): ${user.email}');
            await _storage.saveUser(user);
            print('✅ Sesión de Google guardada exitosamente');

            // Actualizar la respuesta con el usuario obtenido
            return AuthResponse(
              success: true,
              message: authResponse.message,
              token: authResponse.token,
              user: user,
            );
          } else {
            print('❌ No se pudo obtener el usuario del servidor (Google)');
          }
        }

        return authResponse;
      }

      throw Exception(response.data['message'] ?? 'Error en el login con Google');
    } on DioException catch (e) {
      // Cerrar sesión de Google si falla
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      return AuthResponse(
        success: false,
        message: _handleError(e),
      );
    } catch (e) {
      // Cerrar sesión de Google si falla
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();

      return AuthResponse(
        success: false,
        message: 'Error con Google Sign-In: ${e.toString()}',
      );
    }
  }

  // MÉTODOS DE VERIFICACIÓN DE EMAIL DESHABILITADOS
  // Google Sign-In no requiere verificación de email

  /*
  /// Verificar email (DESHABILITADO)
  Future<AuthResponse> verifyEmail(int userId, String code) async {
    return AuthResponse(
      success: false,
      message: 'Verificación de email no necesaria con Google Sign-In.',
    );
  }

  /// Reenviar código de verificación (DESHABILITADO)
  Future<AuthResponse> resendVerificationCode(int userId) async {
    return AuthResponse(
      success: false,
      message: 'Verificación de email no necesaria con Google Sign-In.',
    );
  }
  */

  /// Solicitar cambio de dispositivo
  Future<AuthResponse> requestDeviceChange({
    required int userId,
    required String newDeviceId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.deviceChangeRequest,
        data: {
          'user_id': userId,
          'new_device_id': newDeviceId,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: _handleError(e),
      );
    }
  }

  /// Verificar cambio de dispositivo
  Future<AuthResponse> verifyDeviceChange({
    required int requestId,
    required String code,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.deviceVerifyChange,
        data: {
          'request_id': requestId,
          'code': code,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(response.data);

        if (authResponse.success &&
            authResponse.token != null &&
            authResponse.user != null) {
          await _storage.saveToken(authResponse.token!);
          await _storage.saveUser(authResponse.user!);
          setToken(authResponse.token!);
        }

        return authResponse;
      }

      throw Exception(response.data['message'] ?? 'Error al verificar cambio');
    } on DioException catch (e) {
      return AuthResponse(
        success: false,
        message: _handleError(e),
      );
    }
  }

  /// Obtener usuario actual
  Future<AuthUser?> getCurrentUser() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return null;

      setToken(token);
      // IMPORTANTE: También configurar en ApiService para las peticiones de órdenes
      ApiService.setAuthToken(token);

      final response = await _dio.get(ApiConfig.authMe);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = AuthUser.fromJson(response.data['data']);
        await _storage.saveUser(user);
        return user;
      }

      return null;
    } catch (e) {
      print('Error al obtener usuario actual: $e');
      return null;
    }
  }

  /// Verificar si está autenticado
  Future<bool> isAuthenticated() async {
    final token = await _storage.getToken();
    if (token == null) return false;

    try {
      setToken(token);
      final user = await getCurrentUser();
      return user != null;
    } catch (e) {
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Intentar cerrar sesión en el servidor
      final token = await _storage.getToken();
      if (token != null) {
        setToken(token);
        await _dio.post(ApiConfig.authLogout);
      }
    } catch (e) {
      print('Error al cerrar sesión en el servidor: $e');
    } finally {
      // Limpiar datos locales
      await _storage.clearAuthData();
      removeToken();

      // Cerrar sesión de Google si existe
      try {
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }
        await _firebaseAuth.signOut();
      } catch (e) {
        print('Error al cerrar sesión de Google: $e');
      }
    }
  }

  // MÉTODOS DE CONTRASEÑA DESHABILITADOS
  // Google Sign-In gestiona las contraseñas de forma externa

  /*
  /// Cambiar contraseña (DESHABILITADO)
  Future<AuthResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return AuthResponse(
      success: false,
      message: 'Gestión de contraseñas no disponible. Google maneja tu seguridad.',
    );
  }

  /// Recuperar contraseña (DESHABILITADO)
  Future<AuthResponse> forgotPassword(String email) async {
    return AuthResponse(
      success: false,
      message: 'Recuperación de contraseña no disponible. Usa Google Sign-In.',
    );
  }

  /// Resetear contraseña (DESHABILITADO)
  Future<AuthResponse> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    return AuthResponse(
      success: false,
      message: 'Reseteo de contraseña no disponible. Usa Google Sign-In.',
    );
  }
  */

  /// Manejo de errores
  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado';

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (data != null && data['message'] != null) {
          return data['message'];
        }

        switch (statusCode) {
          case 401:
            return 'Credenciales inválidas';
          case 403:
            return 'Acceso denegado';
          case 404:
            return 'Recurso no encontrado';
          case 422:
            return 'Datos inválidos';
          case 429:
            return 'Demasiados intentos, intenta más tarde';
          case 500:
            return 'Error del servidor';
          default:
            return 'Error: $statusCode';
        }

      case DioExceptionType.cancel:
        return 'Petición cancelada';

      case DioExceptionType.unknown:
        return 'Sin conexión a internet';

      default:
        return 'Error desconocido';
    }
  }
}
