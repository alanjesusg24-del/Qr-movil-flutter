# Debug: Órdenes Duplicadas Entre Usuarios

## Problema

Ambos usuarios (email y Google) ven las mismas órdenes en el mismo dispositivo.

## Cambios Realizados en Flutter

### 1. Sesión que se cierra ✅ RESUELTO

**Problema:** La sesión se cerraba al salir de la app.

**Solución:** Agregado `ApiService.setAuthToken(token)` en `AuthService.getCurrentUser()` (línea 350).

Ahora cuando la app se reinicia:
1. `SplashScreen` inicializa `AuthProvider`
2. `AuthProvider.initialize()` llama a `getCurrentUser()`
3. `getCurrentUser()` configura el token en **ambos** servicios (AuthService y ApiService)
4. La sesión se mantiene

### 2. Debug de peticiones ✅ AGREGADO

Se agregaron logs en `ApiService.getOrders()` para ver:
- Si está autenticado
- Si el token está presente
- El device_id
- La respuesta del servidor

## Cómo Verificar el Problema

### Paso 1: Ver los logs

1. Ejecuta la app:
```bash
flutter run
```

2. Inicia sesión con cualquier usuario

3. Observa los logs cuando cargue las órdenes. Deberías ver:
```
🔍 Obteniendo órdenes - Autenticado: true
🔍 Token presente: true
🔍 Device ID: xxxxxxxxx
📦 Respuesta del servidor: {success: true, data: {...}}
✅ 2 órdenes obtenidas del servidor
```

### Paso 2: Verificar que el token se envía

1. En los logs, verifica que diga `Autenticado: true` y `Token presente: true`

2. Si dice `false`, significa que el token no se está configurando correctamente

### Paso 3: Probar con usuarios diferentes

1. Cierra sesión
2. Inicia con Usuario A (email)
3. Observa cuántas órdenes aparecen
4. Cierra sesión
5. Inicia con Usuario B (Google)
6. Verifica si ves las mismas órdenes

## El Problema Real: Backend

Si después de los cambios sigues viendo las mismas órdenes, el problema está en el **backend**.

### ¿Por qué?

El backend **NO** está filtrando las órdenes por `user_id`, solo por `device_id`.

Esto significa que:
- Usuario A inicia sesión → Backend recibe token de A
- Backend **IGNORA** el token y solo filtra por device_id
- Usuario B inicia sesión → Backend recibe token de B
- Backend **IGNORA** el token y filtra por el mismo device_id
- Resultado: Ambos ven las mismas órdenes

### Solución

Debes implementar el código del archivo `SOLUCION_ORDENES_DUPLICADAS.md` en tu backend Laravel.

## Verificación del Backend

### Prueba 1: Ver si el backend recibe el token

En tu backend Laravel, agrega logs en el controlador de órdenes:

```php
// app/Http/Controllers/MobileController.php o similar

public function getOrders(Request $request)
{
    $user = $request->user('sanctum');
    $deviceId = $request->header('X-Device-ID');
    $authHeader = $request->header('Authorization');

    // DEBUG: Ver qué está recibiendo el backend
    \Log::info('=== DEBUG GET ORDERS ===', [
        'has_auth_header' => $authHeader !== null,
        'auth_header' => $authHeader,
        'user_authenticated' => $user !== null,
        'user_id' => $user?->id,
        'user_email' => $user?->email,
        'device_id' => $deviceId,
    ]);

    // Tu código actual...
}
```

Luego ejecuta:
```bash
tail -f storage/logs/laravel.log
```

Inicia sesión en la app y observa los logs. Deberías ver algo como:

```
=== DEBUG GET ORDERS ===
has_auth_header: true
auth_header: "Bearer eyJ0eXAiOiJKV1QiLCJhbGc..."
user_authenticated: true
user_id: 1
user_email: "usuario@test.com"
device_id: "abc-123-def"
```

### Prueba 2: Verificar el endpoint

Si `user_authenticated: false`, el problema puede ser:

1. **Sanctum no está configurado correctamente**
2. **La ruta no tiene el middleware de Sanctum**
3. **El token es inválido**

#### Verificar middleware en routes/api.php:

```php
// INCORRECTO (no autentica)
Route::get('/mobile/orders', [MobileController::class, 'getOrders']);

// CORRECTO (permite autenticación opcional)
Route::middleware(['auth:sanctum,optional'])->group(function () {
    Route::get('/mobile/orders', [MobileController::class, 'getOrders']);
});
```

## Solución Temporal (Solo para Testing)

Si no puedes actualizar el backend ahora mismo, puedes implementar un filtro temporal en Flutter:

### Opción A: Filtrar por user_id en Flutter

Edita `lib/providers/orders_provider.dart`:

```dart
// Obtener órdenes desde el servidor
Future<void> fetchOrders({String? status}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final fetchedOrders = await ApiService.getOrders(status: status);

    // TEMPORAL: Filtrar por user_id en Flutter si está autenticado
    final authProvider = /* obtener authProvider del contexto */;
    if (authProvider.isAuthenticated && authProvider.user != null) {
      final userId = authProvider.user!.userId;
      _orders = fetchedOrders.where((order) {
        // Asumiendo que el Order tiene un campo userId
        return order.userId == userId;
      }).toList();

      print('⚠️ FILTRADO TEMPORAL: ${_orders.length} órdenes del usuario $userId');
    } else {
      _orders = fetchedOrders;
    }

    // Guardar en base de datos local
    await DatabaseService.instance.syncOrders(_orders);

    _isLoading = false;
    notifyListeners();
    print('✅ ${_orders.length} órdenes obtenidas');
  } catch (e) {
    // ...
  }
}
```

**NOTA:** Esto es solo temporal. El backend **DEBE** filtrar las órdenes correctamente.

### Opción B: Limpiar órdenes al cambiar de usuario

Edita `lib/providers/auth_provider.dart`:

```dart
// En el método login exitoso
if (response.success) {
  // Configurar token en ApiService
  if (response.token != null) {
    ApiService.setAuthToken(response.token);
  }

  _user = response.user;
  _status = AuthStatus.authenticated;

  // TEMPORAL: Limpiar órdenes al cambiar de usuario
  // (necesitarías acceso al OrdersProvider)

  return true;
}
```

## Checklist de Verificación

### En Flutter:
- [ ] Los logs muestran `Autenticado: true`
- [ ] Los logs muestran `Token presente: true`
- [ ] La sesión se mantiene al reiniciar la app
- [ ] El token se envía en el header Authorization

### En Backend:
- [ ] El backend recibe el header Authorization
- [ ] `$request->user('sanctum')` retorna el usuario
- [ ] El endpoint filtra por `user_id` cuando está autenticado
- [ ] El endpoint filtra por `device_id` cuando NO está autenticado
- [ ] La tabla orders tiene el campo `user_id`

## Próximos Pasos

1. **Ejecuta la app y revisa los logs** para confirmar que el token se envía
2. **Agrega logs en el backend** para ver si el token llega
3. **Implementa el código de `SOLUCION_ORDENES_DUPLICADAS.md`** en el backend
4. **Prueba con dos usuarios diferentes** para verificar que cada uno ve solo sus órdenes

## Ayuda Adicional

Si después de implementar los cambios del backend sigues teniendo problemas, verifica:

1. **Cache del backend:** `php artisan cache:clear && php artisan config:clear`
2. **Migración de user_id:** `php artisan migrate`
3. **Tokens anteriores:** Cierra sesión y vuelve a iniciar
4. **CORS:** Verifica que permita el header Authorization

---

**Recuerda:** El filtrado de órdenes **DEBE** hacerse en el backend por seguridad. El filtrado en Flutter es solo temporal para testing.
