# Correcciones Necesarias en la App Flutter

## Diagnóstico del Problema

✅ **Backend Laravel**: Funcionando CORRECTAMENTE
❌ **App Flutter**: NO está enviando el token de autenticación

### Evidencia del Problema

Cuando dos usuarios inician sesión en la app Flutter:
- Ambos VEN las mismas órdenes
- El backend recibe peticiones SIN token de autenticación
- El sistema usa `mobile_user_id` (sistema antiguo) en lugar de `user_id`

### Logs del Backend
```
[2025-11-19 23:35:32] local.INFO: Fetching orders for device {"mobile_user_id":3}
[2025-11-19 23:36:01] local.INFO: Fetching orders for device {"mobile_user_id":3}
```

**Nota**: Dice "Fetching orders for device" cuando DEBERÍA decir "Fetching orders for authenticated user"

## Archivos a Corregir en Flutter

### 1. `lib/services/api_service.dart`

**Problema**: El token NO se está configurando en los headers de Dio

**Solución**: Verifica que el código tenga EXACTAMENTE esto:

```dart
import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio();
  static String? _authToken;

  /// Configurar token de autenticación
  static void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      print('🔐 Token configurado en ApiService: ${token.substring(0, 10)}...');
    } else {
      _dio.options.headers.remove('Authorization');
      print('🔓 Token removido de ApiService');
    }
  }

  /// Verificar si el usuario está autenticado
  static bool get isAuthenticated => _authToken != null;

  /// Obtener el token actual
  static String? get authToken => _authToken;
}
```

**⚠️ IMPORTANTE**: Agrega los `print()` para debuguear que el token se esté configurando

---

### 2. `lib/providers/auth_provider.dart`

**Problema**: Después del login exitoso, NO se está llamando a `ApiService.setAuthToken()`

**Solución**: En el método de login, INMEDIATAMENTE después de recibir el token:

```dart
Future<bool> login(String email, String password) async {
  try {
    final response = await _authService.login(email, password);

    if (response.success) {
      print('✅ Login exitoso: ${response.user?.email}');
      print('🎫 Token recibido: ${response.token?.substring(0, 10)}...');

      // ⚠️ CRÍTICO: Configurar token en ApiService
      if (response.token != null) {
        ApiService.setAuthToken(response.token);
        print('✅ Token configurado en ApiService');
      } else {
        print('❌ ERROR: Login exitoso pero sin token');
      }

      _user = response.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    return false;
  } catch (e) {
    print('❌ Error en login: $e');
    return false;
  }
}
```

**También en `loginWithGoogle()`**:
```dart
Future<bool> loginWithGoogle() async {
  try {
    final response = await _authService.loginWithGoogle();

    if (response.success) {
      print('✅ Login Google exitoso: ${response.user?.email}');
      print('🎫 Token recibido: ${response.token?.substring(0, 10)}...');

      // ⚠️ CRÍTICO: Configurar token
      if (response.token != null) {
        ApiService.setAuthToken(response.token);
        print('✅ Token configurado en ApiService');
      }

      _user = response.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    }

    return false;
  } catch (e) {
    print('❌ Error en Google login: $e');
    return false;
  }
}
```

**Y en `logout()`**:
```dart
Future<void> logout() async {
  try {
    await _authService.logout();
  } catch (e) {
    print('⚠️ Error al hacer logout en backend: $e');
  } finally {
    _user = null;
    _status = AuthStatus.unauthenticated;

    // ⚠️ CRÍTICO: Limpiar token
    ApiService.setAuthToken(null);
    print('✅ Token limpiado de ApiService');

    notifyListeners();
  }
}
```

---

### 3. `lib/services/order_service.dart` (o similar)

**Problema**: Las peticiones de órdenes NO están usando ApiService._dio

**Solución**: Verifica que TODAS las peticiones HTTP usen `ApiService._dio`:

```dart
class OrderService {
  // ❌ MAL - Crea nueva instancia de Dio sin el token
  // final Dio _dio = Dio();

  // ✅ BIEN - Usa la instancia compartida con el token
  Future<List<Order>> getOrders() async {
    try {
      print('📡 Obteniendo órdenes...');
      print('🔑 Token actual: ${ApiService.authToken?.substring(0, 10) ?? "SIN TOKEN"}');

      final response = await ApiService._dio.get('/api/v1/mobile/orders');

      print('✅ Respuesta recibida: ${response.data}');

      // Procesar respuesta...
    } catch (e) {
      print('❌ Error obteniendo órdenes: $e');
      rethrow;
    }
  }
}
```

**⚠️ CRÍTICO**: NO crees nuevas instancias de Dio en otros servicios. SIEMPRE usa `ApiService._dio`

---

### 4. `lib/main.dart` o punto de entrada

**Problema**: Al iniciar la app, no se restaura el token guardado

**Solución**: Al inicializar la app, restaura el token desde SharedPreferences:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restaurar token guardado
  final prefs = await SharedPreferences.getInstance();
  final savedToken = prefs.getString('auth_token');

  if (savedToken != null) {
    ApiService.setAuthToken(savedToken);
    print('🔄 Token restaurado desde storage: ${savedToken.substring(0, 10)}...');
  } else {
    print('ℹ️ No hay token guardado');
  }

  runApp(MyApp());
}
```

**Y guarda el token cuando se obtiene**:
```dart
// En auth_provider.dart después de login exitoso
final prefs = await SharedPreferences.getInstance();
await prefs.setString('auth_token', response.token!);
print('💾 Token guardado en storage');
```

---

## Checklist de Verificación

Antes de probar, verifica que TODOS estos puntos estén implementados:

### ApiService
- [ ] Tiene variable estática `_authToken`
- [ ] Tiene método `setAuthToken(String? token)`
- [ ] El método configura el header `Authorization: Bearer {token}`
- [ ] Tiene prints para debug

### AuthProvider
- [ ] En `login()` llama a `ApiService.setAuthToken(response.token)`
- [ ] En `loginWithGoogle()` llama a `ApiService.setAuthToken(response.token)`
- [ ] En `logout()` llama a `ApiService.setAuthToken(null)`
- [ ] Tiene prints para debug

### Servicios (OrderService, etc.)
- [ ] TODOS los servicios usan `ApiService._dio` en lugar de crear nuevas instancias
- [ ] NO hay `final Dio _dio = Dio()` en ningún servicio
- [ ] Tienen prints para ver si el token se está enviando

### Persistencia
- [ ] El token se guarda en SharedPreferences después del login
- [ ] El token se restaura al iniciar la app
- [ ] El token se elimina al hacer logout

---

## Cómo Probar que Funciona

### Paso 1: Ver los Logs
Ejecuta la app y observa los logs en la consola:

```
✅ Login exitoso: user1@test.com
🎫 Token recibido: 12|7eV6mxN...
✅ Token configurado en ApiService
📡 Obteniendo órdenes...
🔑 Token actual: 12|7eV6mxN
✅ Respuesta recibida: {...}
```

### Paso 2: Verificar en el Backend
En los logs de Laravel (`storage/logs/laravel.log`) deberías ver:

```
[2025-11-20 05:50:00] local.INFO: Fetching orders for authenticated user {"user_id":7,"email":"user1@test.com"}
```

**NO debería decir**: "Fetching orders for device"

### Paso 3: Probar con Dos Usuarios

1. **Usuario 1**:
   - Inicia sesión con `user1@test.com`
   - Verifica en logs que el token se configuró
   - Ve las órdenes (debería estar vacío)

2. **Cierra sesión**:
   - Verifica en logs que el token se limpió

3. **Usuario 2**:
   - Inicia sesión con `user2@test.com`
   - Verifica en logs que el token se configuró
   - Ve las órdenes (debería estar vacío)

4. **Verifica**:
   - Ambos usuarios ven listas VACÍAS (correcto)
   - NO ven las mismas órdenes (correcto)
   - Los logs del backend muestran diferentes `user_id` (correcto)

---

## Errores Comunes

### Error 1: "Unauthenticated"
**Causa**: El token no se está enviando en el header
**Solución**: Verifica que `ApiService.setAuthToken()` se esté llamando después del login

### Error 2: Ambos usuarios ven las mismas órdenes
**Causa**: El token NO se está enviando, usando sistema antiguo (mobile_user_id)
**Solución**: Verifica los logs - si dice "Fetching orders for device", el token NO se está enviando

### Error 3: "Token is invalid"
**Causa**: El token expiró o es inválido
**Solución**: Haz logout y vuelve a iniciar sesión para obtener un token nuevo

### Error 4: Después de cerrar la app, pierde la sesión
**Causa**: El token no se está guardando en SharedPreferences
**Solución**: Implementa la persistencia del token como se indica arriba

---

## Código de Ejemplo Completo

### api_service.dart
```dart
import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://tu-servidor.com', // Cambia esto
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      print('🔐 Token configurado: ${token.substring(0, 10)}...');
    } else {
      _dio.options.headers.remove('Authorization');
      print('🔓 Token removido');
    }
  }

  static bool get isAuthenticated => _authToken != null;
  static String? get authToken => _authToken;

  // Exponer dio para otros servicios
  static Dio get dio => _dio;
}
```

### order_service.dart
```dart
import 'package:dio/dio.dart';
import 'api_service.dart';

class OrderService {
  Future<List<Order>> getOrders() async {
    print('📡 Obteniendo órdenes...');
    print('🔑 Token: ${ApiService.authToken?.substring(0, 10) ?? "SIN TOKEN"}');

    final response = await ApiService.dio.get('/api/v1/mobile/orders');

    if (response.data['success'] == true) {
      print('✅ Órdenes obtenidas: ${response.data['data']['orders'].length}');
      // Procesar...
    }

    // ...
  }
}
```

---

## Resumen

**El backend está 100% funcional**. El problema está en que la app Flutter NO está enviando el token de autenticación.

**Solución**: Implementar los cambios anteriores para que:
1. El token se configure en ApiService después del login
2. El token se envíe en TODAS las peticiones HTTP
3. El token se guarde y restaure correctamente

**Una vez implementado**, cada usuario verá SOLO sus órdenes, eliminando completamente el problema de órdenes duplicadas.
