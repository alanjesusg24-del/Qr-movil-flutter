# Solución: Login con Email/Password NO persiste en Flutter

## Problema

✅ **Login con Google** → Funciona, la sesión persiste
❌ **Login con Email/Password** → NO funciona, pide login cada vez

## Causa

El método `login()` en `AuthProvider` NO está guardando el token persistentemente, mientras que `loginWithGoogle()` sí lo hace.

---

## Solución: Verificar y Corregir AuthProvider

### 1. Verificar que `login()` guarde el token

Abre el archivo `lib/providers/auth_provider.dart` y localiza el método `login()`.

**DEBE verse así:**

```dart
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

      // ✅ ESTAS DOS LÍNEAS SON CRÍTICAS - DEBEN ESTAR AQUÍ
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
```

---

### 2. Comparar con `loginWithGoogle()` (que SÍ funciona)

**Si Google funciona**, significa que `loginWithGoogle()` tiene estas líneas:

```dart
await _apiService.setAuthToken(token);
await StorageService.saveUserData(_user!);
```

**El método `login()` DEBE tener EXACTAMENTE las mismas líneas** después de obtener el token.

---

### 3. Verificar StorageService

Asegúrate de que `StorageService.saveToken()` esté funcionando correctamente:

```dart
// En lib/services/storage_service.dart

static Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
  print('✅ Token guardado: ${token.substring(0, 20)}...');
}
```

---

### 4. Verificar ApiService.setAuthToken()

Asegúrate de que este método esté guardando el token:

```dart
// En lib/services/api_service.dart

Future<void> setAuthToken(String token) async {
  _authToken = token;
  await StorageService.saveToken(token);
  print('✅ Token configurado en ApiService');
}
```

---

## Testing: Agregar Prints para Debugging

### En AuthProvider.login()

Agrega estos prints para debugging:

```dart
Future<bool> login(String email, String password) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final deviceId = await StorageService.getOrCreateDeviceId();
    print('🔑 Intentando login con device_id: $deviceId');

    final response = await _apiService.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
    });

    print('📥 Login response: ${response.statusCode}');
    print('📦 Response data: ${response.data}');

    if (response.statusCode == 200 && response.data['success'] == true) {
      _user = response.data['data'];
      final token = response.data['token'];

      print('🎟️  Token recibido: ${token.substring(0, 30)}...');

      // ✅ GUARDAR TOKEN
      await _apiService.setAuthToken(token);
      await StorageService.saveUserData(_user!);

      // ✅ VERIFICAR QUE SE GUARDÓ
      final savedToken = await StorageService.getToken();
      print('💾 Token guardado verificado: ${savedToken?.substring(0, 30)}...');

      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();

      print('✅ Login exitoso - sesión guardada');
      return true;
    }
  } catch (e) {
    print('❌ Error en login: $e');
    _errorMessage = 'Error en login: $e';
    _isAuthenticated = false;
  }

  _isLoading = false;
  notifyListeners();
  return false;
}
```

---

## Checklist de Verificación

### ✅ En el código de Flutter:

- [ ] `AuthProvider.login()` tiene `await _apiService.setAuthToken(token)`
- [ ] `AuthProvider.login()` tiene `await StorageService.saveUserData(_user!)`
- [ ] `StorageService.saveToken()` usa `SharedPreferences.setString()`
- [ ] `ApiService.setAuthToken()` llama a `StorageService.saveToken()`
- [ ] Los prints de debugging muestran que el token se está guardando

### ✅ Comportamiento esperado:

- [ ] Login con email/password → Muestra print "✅ Token guardado"
- [ ] Login con email/password → Muestra print "💾 Token guardado verificado"
- [ ] Cerrar app → Abrir app → SplashScreen muestra "📱 Token recuperado: ✅ Existe"
- [ ] SplashScreen llama `/auth/me` exitosamente
- [ ] Usuario entra directo al HomeScreen sin pedir login

---

## Comparación: Login vs LoginWithGoogle

Si `loginWithGoogle()` funciona pero `login()` no, la diferencia está en estas líneas:

### ✅ loginWithGoogle() (FUNCIONA)

```dart
if (response.statusCode == 200 && response.data['success'] == true) {
  _user = response.data['data'];
  final token = response.data['token'];

  // ✅ ESTAS LÍNEAS ESTÁN PRESENTES
  await _apiService.setAuthToken(token);
  await StorageService.saveUserData(_user!);

  _isAuthenticated = true;
  return true;
}
```

### ❌ login() (NO FUNCIONA - Ejemplo de código INCORRECTO)

```dart
if (response.statusCode == 200 && response.data['success'] == true) {
  _user = response.data['data'];
  final token = response.data['token'];

  // ❌ FALTAN ESTAS LÍNEAS (O ESTÁN COMENTADAS)
  // await _apiService.setAuthToken(token);
  // await StorageService.saveUserData(_user!);

  _isAuthenticated = true;
  return true;
}
```

**Solución**: Agregar las líneas faltantes en `login()` para que sea idéntico a `loginWithGoogle()`.

---

## Código Completo Correcto

### AuthProvider.login() - Versión Correcta

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

  // ✅ MÉTODO CORRECTO
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

        // ✅ CRÍTICO: GUARDAR TOKEN PERSISTENTEMENTE
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
}
```

---

## Prueba Final

### 1. Prueba con Email/Password

```
1. Abrir app Flutter
2. Hacer login con:
   - Email: test@test.com
   - Password: 12345678
3. ✅ Debería mostrar en consola:
   - "📥 Login response: 200"
   - "🎟️  Token recibido: ..."
   - "✅ Token guardado: ..."
   - "💾 Token guardado verificado: ..."
   - "✅ Login exitoso - sesión guardada"
4. Usuario entra al HomeScreen
5. CERRAR la app completamente (kill)
6. ABRIR la app nuevamente
7. ✅ Debería mostrar en consola:
   - "🔍 Verificando sesión guardada..."
   - "📱 Token recuperado: ✅ Existe"
   - "✅ Sesión restaurada exitosamente"
8. ✅ Usuario entra directo al HomeScreen SIN pedir login
```

### 2. Comparar con Google

```
1. Hacer logout
2. Hacer login con Google
3. Cerrar app
4. Abrir app
5. ✅ Debería entrar directo (ya funciona)

AMBOS MÉTODOS (email/password y Google) DEBEN tener el MISMO comportamiento
```

---

## Resumen

El problema es que `login()` en Flutter NO está guardando el token, mientras que `loginWithGoogle()` sí lo hace.

**Solución**: Agregar estas dos líneas en `AuthProvider.login()`:

```dart
await _apiService.setAuthToken(token);
await StorageService.saveUserData(_user!);
```

Justo después de obtener el token del backend:

```dart
final token = response.data['token'];
// ✅ AGREGAR AQUÍ
await _apiService.setAuthToken(token);
await StorageService.saveUserData(_user!);
```

Con esto, el login con email/password persistirá igual que el login con Google.
