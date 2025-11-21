# Cambios Realizados para Corregir Órdenes Duplicadas

## Resumen

Se han implementado correcciones en la app Flutter para asegurar que el token de autenticación se envíe correctamente en todas las peticiones al backend, resolviendo el problema de órdenes duplicadas entre usuarios.

## Archivos Modificados

### 1. `lib/services/api_service.dart`

#### Cambios realizados:

**Líneas 24-44**: Mejorado método `setAuthToken()` con logs de debug:
```dart
/// Configurar token de autenticación
static void setAuthToken(String? token) {
  _authToken = token;
  if (token != null) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    print('🔐 Token configurado en ApiService: ${token.substring(0, 10)}...');
    print('📋 Headers actuales: ${_dio.options.headers}');
  } else {
    _dio.options.headers.remove('Authorization');
    print('🔓 Token removido de ApiService');
  }
}
```

**Línea 40-44**: Agregados getters útiles:
```dart
/// Obtener el token actual
static String? get authToken => _authToken;

/// Exponer instancia de Dio para otros servicios
static Dio get dio => _dio;
```

**Líneas 119-135**: Logs de debug detallados en `getOrders()`:
```dart
print('📡 ========== OBTENIENDO ÓRDENES ==========');
print('🔍 Autenticado: $isAuthenticated');
print('🔍 Token presente: ${_authToken != null}');
if (_authToken != null) {
  print('🎫 Token actual: ${_authToken!.substring(0, 20)}...');
}
print('🔍 Device ID: $_deviceId');
print('📋 Headers que se enviarán: ${_dio.options.headers}');
```

**Propósito**: Permitir debug completo del flujo de autenticación y confirmar que el token se envía en cada petición.

---

### 2. `lib/services/auth_service.dart`

#### Cambios realizados:

**Línea 9**: Agregado import de ApiService:
```dart
import 'api_service.dart';
```

**Línea 350**: Configurar token en ApiService al obtener usuario actual:
```dart
setToken(token);
// IMPORTANTE: También configurar en ApiService para las peticiones de órdenes
ApiService.setAuthToken(token);
```

**Propósito**: Asegurar que cuando la app se reinicia y recupera el usuario guardado, el token también se configure en ApiService.

---

### 3. `lib/providers/auth_provider.dart`

#### Cambios realizados:

**Línea 6**: Agregado import de ApiService:
```dart
import '../services/api_service.dart';
```

**Líneas 48-49**: Configurar token al inicializar app:
```dart
final token = await _storage.getToken();
if (token != null) {
  ApiService.setAuthToken(token);
}
```

**Líneas 103-113**: Logs y configuración de token en registro:
```dart
if (response.success) {
  print('✅ Registro exitoso: ${response.user?.email}');
  print('🎫 Token recibido: ${response.token?.substring(0, 10) ?? "SIN TOKEN"}...');

  // Configurar token en ApiService
  if (response.token != null) {
    ApiService.setAuthToken(response.token);
    print('✅ Token configurado en ApiService después de registro');
  } else {
    print('❌ ERROR: Registro exitoso pero SIN token');
  }
  // ...
}
```

**Líneas 156-166**: Logs y configuración de token en login con email:
```dart
if (response.success) {
  print('✅ Login exitoso: ${response.user?.email}');
  print('🎫 Token recibido: ${response.token?.substring(0, 10) ?? "SIN TOKEN"}...');

  // Configurar token en ApiService
  if (response.token != null) {
    ApiService.setAuthToken(response.token);
    print('✅ Token configurado en ApiService después de login');
  } else {
    print('❌ ERROR: Login exitoso pero SIN token');
  }
  // ...
}
```

**Líneas 205-215**: Logs y configuración de token en login con Google:
```dart
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
  // ...
}
```

**Líneas 378-384**: Limpieza de token al cerrar sesión:
```dart
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
}
```

**Propósito**: Asegurar que el token se configure en TODOS los flujos de autenticación (registro, login, Google, inicialización) y se limpie al cerrar sesión.

---

## Flujo de Autenticación Corregido

### 1. Al Iniciar la App (Primera vez o reinicio)
```
SplashScreen → AuthProvider.initialize()
  → SecureStorage.getToken()
  → ApiService.setAuthToken(token) ✅
  → AuthService.getCurrentUser()
    → ApiService.setAuthToken(token) ✅ (doble verificación)
  → Navegar a /home
```

### 2. Al Hacer Login con Email
```
LoginScreen → AuthProvider.login()
  → AuthService.login()
  → Backend retorna {success: true, token: "...", user: {...}}
  → ApiService.setAuthToken(token) ✅
  → Logs: "✅ Token configurado en ApiService"
  → Navegar a /home
```

### 3. Al Hacer Login con Google
```
LoginScreen → AuthProvider.loginWithGoogle()
  → AuthService.loginWithGoogle()
  → Google Sign-In → Firebase Auth
  → Backend retorna {success: true, token: "...", user: {...}}
  → ApiService.setAuthToken(token) ✅
  → Logs: "✅ Token configurado en ApiService"
  → Navegar a /home
```

### 4. Al Obtener Órdenes
```
HomeScreen → OrdersProvider.fetchOrders()
  → ApiService.getOrders()
  → Logs: "📡 ========== OBTENIENDO ÓRDENES =========="
  → Logs: "🔍 Autenticado: true"
  → Logs: "🎫 Token actual: 12|7eV6mxN..."
  → Logs: "📋 Headers que se enviarán: {Authorization: Bearer ...}"
  → Dio.get('/api/v1/mobile/orders') con header Authorization ✅
  → Backend recibe token → Filtra por user_id ✅
```

### 5. Al Cerrar Sesión
```
SettingsScreen → AuthProvider.logout()
  → AuthService.logout()
  → Backend invalida token
  → ApiService.setAuthToken(null) ✅
  → Logs: "✅ Token limpiado de ApiService"
  → Navegar a /login
```

---

## Cómo Verificar que Funciona

### 1. Ejecutar la app en modo debug

```bash
flutter run
```

### 2. Observar los logs durante el login

Deberías ver:

```
✅ Login exitoso: user1@test.com
🎫 Token recibido: 12|7eV6mxN...
🔐 Token configurado en ApiService: 12|7eV6mxN...
📋 Headers actuales: {Authorization: Bearer 12|7eV6mxN..., X-Device-ID: ...}
✅ Token configurado en ApiService después de login
```

### 3. Observar los logs al obtener órdenes

Deberías ver:

```
📡 ========== OBTENIENDO ÓRDENES ==========
🔍 Autenticado: true
🔍 Token presente: true
🎫 Token actual: 12|7eV6mxNOi3HQLl8...
🔍 Device ID: abc-123-def
📋 Headers que se enviarán: {Authorization: Bearer 12|7eV6mxN..., X-Device-ID: ...}
📦 Respuesta del servidor recibida
✅ Status code: 200
✅ 0 órdenes obtenidas del servidor
```

### 4. Verificar en el backend (Laravel logs)

En `storage/logs/laravel.log` deberías ver:

```
[2025-11-20 06:00:00] local.INFO: Fetching orders for authenticated user {"user_id":7,"email":"user1@test.com"}
```

**NO debería decir**: "Fetching orders for device"

### 5. Probar con dos usuarios diferentes

1. **Usuario A**: Login → Ver órdenes (vacío)
2. **Cerrar sesión** → Ver logs: "✅ Token limpiado"
3. **Usuario B**: Login → Ver órdenes (vacío)
4. **Verificar**: Cada usuario ve su propia lista, NO la misma

---

## Problemas Conocidos y Soluciones

### ❌ Si ves "SIN TOKEN" en los logs

**Causa**: El backend no está retornando el token en la respuesta

**Solución**: Verifica que el backend Laravel esté retornando:
```json
{
  "success": true,
  "token": "12|abc123...",
  "data": {...}
}
```

### ❌ Si ves "Autenticado: false"

**Causa**: El token no se configuró en ApiService

**Solución**: Verifica que veas los logs:
```
🔐 Token configurado en ApiService: ...
```

Si no aparece, hay un problema en el flujo de autenticación.

### ❌ Si el backend dice "Fetching orders for device"

**Causa**: El token NO se está enviando en el header Authorization

**Solución**:
1. Verifica que los logs muestren: `📋 Headers que se enviarán: {Authorization: Bearer ...}`
2. Si el header NO aparece, el token no se configuró correctamente
3. Reinicia la app y observa los logs desde el inicio

### ❌ Si ambos usuarios ven las mismas órdenes

**Causa**: El backend NO está filtrando por `user_id`

**Solución**:
1. Verifica en los logs de Laravel que diga "authenticated user" y no "device"
2. Si dice "device", el backend está ignorando el token
3. Implementa el código de `SOLUCION_ORDENES_DUPLICADAS.md` en el backend

---

## Estado Actual

### ✅ Completado en Flutter

- [x] Token se configura al hacer login con email
- [x] Token se configura al hacer login con Google
- [x] Token se configura al hacer registro
- [x] Token se configura al iniciar la app (recuperar sesión)
- [x] Token se limpia al cerrar sesión
- [x] Token se envía en header Authorization en todas las peticiones
- [x] Logs de debug implementados en todos los flujos
- [x] Sesión se mantiene al cerrar y abrir la app

### ⚠️ Pendiente en Backend

- [ ] Verificar que el backend filtre por `user_id` cuando recibe token
- [ ] Verificar que el backend filtre por `device_id` cuando NO hay token
- [ ] Confirmar que cada usuario ve solo sus órdenes

---

## Próximos Pasos

1. **Ejecutar la app** y verificar los logs
2. **Confirmar** que el token se envía en todas las peticiones
3. **Probar** con dos usuarios diferentes
4. **Verificar en el backend** que filtra correctamente por user_id
5. Si el problema persiste, compartir los logs completos para análisis

---

## Comandos Útiles

### Ver logs de Flutter en tiempo real
```bash
flutter run -v
```

### Ver solo logs de autenticación
```bash
flutter logs | grep -E "(✅|🔐|🎫|📡|❌)"
```

### Limpiar y reconstruir (si hay problemas)
```bash
flutter clean
flutter pub get
flutter run
```

---

**Nota**: Todos los cambios son retrocompatibles. La app seguirá funcionando con el sistema antiguo (device_id) para usuarios no autenticados.
