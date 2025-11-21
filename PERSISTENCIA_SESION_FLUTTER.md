# Solución: Persistencia de Sesión en Flutter

## Problema Actual

1. ❌ Al cerrar la app, la sesión se pierde y pide login nuevamente
2. ❌ Al volver a iniciar sesión, pide un código de verificación por email (NO DEBE HACER ESTO)

## Causa del Problema

La app Flutter **NO está guardando el token de autenticación** de forma persistente. Cuando el usuario cierra la app:
- El token se pierde de la memoria
- La app lo trata como un dispositivo nuevo
- El backend detecta un `device_id` diferente y pide verificación

## Solución Completa

### 1. Instalar Dependencias

Agrega al archivo `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2  # Para guardar token persistentemente
  provider: ^6.1.1              # Para manejo de estado
  dio: ^5.4.0                   # Cliente HTTP
```

Ejecutar:
```bash
flutter pub get
```

---

### 2. Crear Servicio de Almacenamiento Seguro

Crea el archivo `lib/services/storage_service.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _deviceIdKey = 'device_id';
  static const String _userKey = 'user_data';

  // Guardar token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('✅ Token guardado: ${token.substring(0, 20)}...');
  }

  // Obtener token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    print('📱 Token recuperado: ${token != null ? "✅ Existe" : "❌ No existe"}');
    return token;
  }

  // Eliminar token (logout)
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🗑️ Token eliminado');
  }

  // Guardar device_id (generado una sola vez)
  static Future<void> saveDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceIdKey, deviceId);
    print('✅ Device ID guardado: $deviceId');
  }

  // Obtener o generar device_id
  static Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      // Generar device_id único la primera vez
      deviceId = 'flutter_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
      await saveDeviceId(deviceId);
      print('🆕 Device ID generado: $deviceId');
    } else {
      print('📱 Device ID existente: $deviceId');
    }

    return deviceId;
  }

  // Guardar datos del usuario
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Obtener datos del usuario
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Limpiar todo (logout completo)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    // NO eliminar device_id - debe persistir
    print('🗑️ Datos de sesión limpiados');
  }

  // Verificar si hay sesión activa
  static Future<bool> hasActiveSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

---

### 3. Actualizar ApiService

Actualiza `lib/services/api_service.dart`:

```dart
import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  String? _authToken;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://tu-dominio.com/api/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor para agregar token automáticamente
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Obtener token del storage si no está en memoria
        if (_authToken == null) {
          _authToken = await StorageService.getToken();
        }

        // Agregar token si existe
        if (_authToken != null && _authToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_authToken';
          print('📤 Request con token: ${options.path}');
        }

        // Agregar device_id SIEMPRE
        final deviceId = await StorageService.getOrCreateDeviceId();
        options.headers['X-Device-ID'] = deviceId;

        return handler.next(options);
      },
      onError: (error, handler) async {
        // Si el token expiró (401), limpiar sesión
        if (error.response?.statusCode == 401) {
          print('❌ Token expirado - limpiando sesión');
          await StorageService.clearAll();
          _authToken = null;
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // Establecer token (llamar después del login)
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    await StorageService.saveToken(token);
    print('✅ Token configurado en ApiService');
  }

  // Cargar token guardado (llamar al iniciar app)
  Future<void> loadSavedToken() async {
    _authToken = await StorageService.getToken();
    if (_authToken != null) {
      print('✅ Token cargado desde storage');
    } else {
      print('⚠️ No hay token guardado');
    }
  }

  // Limpiar token (logout)
  Future<void> clearToken() async {
    _authToken = null;
    await StorageService.clearAll();
    print('🗑️ Token limpiado');
  }
}
```

---

### 4. Actualizar AuthProvider

Actualiza `lib/providers/auth_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;

  // Verificar sesión al iniciar la app
  Future<void> checkSession() async {
    print('🔍 Verificando sesión guardada...');
    _isLoading = true;
    notifyListeners();

    try {
      // Cargar token guardado
      await _apiService.loadSavedToken();

      // Verificar si hay token
      final hasSession = await StorageService.hasActiveSession();

      if (hasSession) {
        // Verificar que el token sea válido llamando /me
        final response = await _apiService.dio.get('/auth/me');

        if (response.statusCode == 200 && response.data['success'] == true) {
          _user = response.data['data'];
          _isAuthenticated = true;
          await StorageService.saveUserData(_user!);
          print('✅ Sesión restaurada exitosamente');
        }
      } else {
        print('⚠️ No hay sesión guardada');
        _isAuthenticated = false;
      }
    } catch (e) {
      print('❌ Error verificando sesión: $e');
      // Si falla, limpiar sesión corrupta
      await logout();
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login con email/password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceId = await StorageService.getOrCreateDeviceId();

      final response = await _apiService.dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
      });

      print('📥 Login response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = response.data['data'];
        final token = response.data['token'];

        // ✅ GUARDAR TOKEN PERSISTENTEMENTE
        await _apiService.setAuthToken(token);
        await StorageService.saveUserData(_user!);

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        print('✅ Login exitoso - sesión guardada');
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Error en login';
        _isAuthenticated = false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 &&
          e.response?.data['requires_device_change'] == true) {
        _errorMessage = 'Este usuario está registrado en otro dispositivo';
      } else if (e.response?.statusCode == 401) {
        _errorMessage = 'Credenciales incorrectas';
      } else {
        _errorMessage = 'Error de conexión: ${e.message}';
      }
      _isAuthenticated = false;
      print('❌ Error en login: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login con Google
  Future<bool> loginWithGoogle(Map<String, dynamic> googleData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceId = await StorageService.getOrCreateDeviceId();

      final response = await _apiService.dio.post('/auth/login/google', data: {
        ...googleData,
        'device_id': deviceId,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = response.data['data'];
        final token = response.data['token'];

        // ✅ GUARDAR TOKEN PERSISTENTEMENTE
        await _apiService.setAuthToken(token);
        await StorageService.saveUserData(_user!);

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        print('✅ Login con Google exitoso - sesión guardada');
        return true;
      }
    } catch (e) {
      _errorMessage = 'Error en login con Google: $e';
      _isAuthenticated = false;
      print('❌ Error en login con Google: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Llamar endpoint de logout
      await _apiService.dio.post('/auth/logout');
    } catch (e) {
      print('⚠️ Error en logout: $e');
    }

    // Limpiar datos locales
    await _apiService.clearToken();
    _user = null;
    _isAuthenticated = false;
    _isLoading = false;
    notifyListeners();

    print('✅ Logout exitoso');
  }

  // Registro
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final deviceId = await StorageService.getOrCreateDeviceId();

      final response = await _apiService.dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
        'device_id': deviceId,
      });

      if (response.statusCode == 201 && response.data['success'] == true) {
        _user = response.data['data'];
        final token = response.data['token'];

        // ✅ GUARDAR TOKEN PERSISTENTEMENTE
        await _apiService.setAuthToken(token);
        await StorageService.saveUserData(_user!);

        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();

        print('✅ Registro exitoso - sesión guardada');
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Error en registro';
      }
    } catch (e) {
      _errorMessage = 'Error en registro: $e';
      print('❌ Error en registro: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

---

### 5. Actualizar main.dart

Actualiza `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tu App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(), // ✅ Iniciar con splash que verifica sesión
      debugShowCheckedModeBanner: false,
    );
  }
}
```

---

### 6. Crear Splash Screen (Verificación de Sesión)

Crea `lib/screens/splash_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Esperar 1 segundo para mostrar logo
    await Future.delayed(const Duration(seconds: 1));

    // Verificar si hay sesión guardada
    await authProvider.checkSession();

    if (!mounted) return;

    // Navegar según resultado
    if (authProvider.isAuthenticated) {
      print('✅ Sesión activa - ir a home');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      print('❌ No hay sesión - ir a login');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tu logo aquí
            Icon(
              Icons.restaurant,
              size: 100,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Verificando sesión...'),
          ],
        ),
      ),
    );
  }
}
```

---

## Flujo Completo

### Primera Vez (Sin Sesión)
```
1. Usuario abre app
2. SplashScreen verifica sesión → No existe
3. Navega a LoginScreen
4. Usuario ingresa credenciales
5. AuthProvider.login() → Guarda token + user data
6. Navega a HomeScreen
```

### Segunda Vez (Con Sesión Guardada)
```
1. Usuario abre app
2. SplashScreen verifica sesión → ✅ Token existe
3. Llama /api/v1/auth/me para validar token
4. Si es válido → Navega directo a HomeScreen
5. Si expiró → Limpia sesión y navega a LoginScreen
```

### Logout
```
1. Usuario presiona "Cerrar sesión"
2. AuthProvider.logout() → Limpia token (NO device_id)
3. Navega a LoginScreen
```

---

## Puntos Importantes

### ✅ LO QUE SÍ DEBE PERSISTIR:
- `auth_token` - Token de autenticación
- `device_id` - Identificador único del dispositivo (NUNCA cambiar)
- `user_data` - Datos del usuario

### ❌ LO QUE NO DEBE PASAR:
- ❌ NO pedir código de verificación en login normal
- ❌ NO generar nuevo `device_id` cada vez
- ❌ NO perder el token al cerrar la app

### 🔐 Seguridad:
- El token se guarda en `SharedPreferences` (seguro en iOS/Android)
- El `device_id` se genera UNA SOLA VEZ y persiste
- Si el token expira (401), se limpia automáticamente

---

## Testing

### Prueba 1: Primera Sesión
```
1. Desinstalar app (limpiar datos)
2. Instalar app
3. Hacer login
4. ✅ Debe entrar sin pedir código
5. ✅ Cerrar app completamente
6. ✅ Abrir app → Debe seguir logueado (SIN pedir login)
```

### Prueba 2: Logout y Re-login
```
1. Estando logueado, hacer logout
2. Hacer login nuevamente
3. ✅ Debe entrar sin pedir código (mismo device_id)
4. ✅ Cerrar y abrir app → Sigue logueado
```

### Prueba 3: Dispositivo Diferente
```
1. Loguearse en dispositivo A
2. Intentar login en dispositivo B con misma cuenta
3. ❌ Backend debe retornar requires_device_change: true
4. ✅ App debe mostrar pantalla de "Dispositivo diferente"
```

---

## Debug Tips

Agrega prints para debugging:

```dart
// En auth_provider.dart
print('🔐 Estado de autenticación:');
print('  - Token guardado: ${await StorageService.getToken() != null}');
print('  - Device ID: ${await StorageService.getOrCreateDeviceId()}');
print('  - Usuario: ${_user?['email']}');
print('  - Autenticado: $_isAuthenticated');
```

---

## Resumen de Cambios

| Archivo | Acción |
|---------|--------|
| `pubspec.yaml` | Agregar shared_preferences |
| `lib/services/storage_service.dart` | **CREAR** - Manejo de persistencia |
| `lib/services/api_service.dart` | **ACTUALIZAR** - Interceptor con token |
| `lib/providers/auth_provider.dart` | **ACTUALIZAR** - Guardar/cargar sesión |
| `lib/screens/splash_screen.dart` | **CREAR** - Verificar sesión al inicio |
| `lib/main.dart` | **ACTUALIZAR** - Iniciar con SplashScreen |

---

## Resultado Final

✅ Usuario abre la app → Si hay sesión, entra directo al home
✅ Usuario cierra la app → Sesión persiste
✅ Usuario hace logout → Puede volver a loguearse sin código
✅ Usuario cambia de dispositivo → Backend pide verificación
❌ NUNCA pide código en login normal del mismo dispositivo
