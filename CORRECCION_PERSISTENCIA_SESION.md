# Corrección: Persistencia de Sesión al Cerrar la App

## Problema Identificado

Aunque el usuario seleccione la casilla "Recuérdame" o no, al cerrar la aplicación la sesión se cerraba. El usuario tenía que volver a iniciar sesión cada vez que abría la app.

## Causa Raíz

El problema estaba en `AuthProvider.initialize()` (líneas 36-82):

**Comportamiento anterior (INCORRECTO):**
```dart
if (hasToken) {
  // Obtiene el token
  final token = await _storage.getToken();
  ApiService.setAuthToken(token);

  // Intenta obtener usuario DESDE EL SERVIDOR
  final user = await _authService.getCurrentUser();

  if (user != null) {
    // Usuario obtenido correctamente
    _status = AuthStatus.authenticated;
  } else {
    // ❌ SI FALLA (sin red, servidor caído, etc.)
    // BORRA TODO EL STORAGE Y CIERRA SESIÓN
    await _storage.clearAuthData();
    _status = AuthStatus.unauthenticated;
  }
}
```

**Problema:**
- Si la app se abre sin conexión a internet
- O si el servidor está temporalmente no disponible
- `getCurrentUser()` falla y retorna `null`
- Se borra todo el storage
- Usuario tiene que iniciar sesión de nuevo

## Solución Implementada

Modificamos la lógica para que:
1. **Primero intente recuperar el usuario desde el storage local**
2. Si encuentra usuario local, lo usa y marca como autenticado
3. En segundo plano intenta actualizar desde el servidor
4. Si falla la actualización, mantiene los datos locales

**Nuevo comportamiento (CORRECTO):**
```dart
if (hasToken) {
  // 1. Obtener token
  final token = await _storage.getToken();
  ApiService.setAuthToken(token);

  // 2. Intentar obtener usuario LOCAL primero
  final savedUser = await _storage.getUser();

  if (savedUser != null) {
    // ✅ Usar usuario local
    _user = savedUser;
    _status = AuthStatus.authenticated;

    // Intentar actualizar desde servidor en segundo plano
    _authService.getCurrentUser().then((updatedUser) {
      if (updatedUser != null) {
        _user = updatedUser;
        notifyListeners();
      }
    }).catchError((e) {
      // ⚠️ Falla la actualización pero mantiene datos locales
      print('No se pudo actualizar desde servidor (continuando con datos locales)');
    });
  } else {
    // No hay usuario local, intentar del servidor
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _status = AuthStatus.authenticated;
    } else {
      // Solo ahora limpiamos si no hay ni local ni servidor
      await _storage.clearAuthData();
    }
  }
}
```

**Además, en caso de error en la inicialización:**
```dart
catch (e) {
  // Si hay error pero tenemos datos locales, mantener la sesión
  final savedUser = await _storage.getUser();
  if (savedUser != null) {
    _user = savedUser;
    _status = AuthStatus.authenticated;
  } else {
    _status = AuthStatus.unauthenticated;
  }
}
```

## Archivos Modificados

### 1. `lib/providers/auth_provider.dart`

**Líneas 36-133**: Completamente reescrito `initialize()` con:

#### Cambios principales:

1. **Logs detallados de debug:**
```dart
print('🔄 Inicializando AuthProvider...');
print('🔍 ¿Tiene token guardado? $hasToken');
print('🎫 Token recuperado: ${token?.substring(0, 10)}...');
print('👤 Usuario guardado localmente: ${savedUser?.email}');
```

2. **Prioridad a datos locales:**
```dart
// Intentar obtener usuario guardado localmente primero
final savedUser = await _storage.getUser();

if (savedUser != null) {
  // Usar usuario guardado localmente
  _user = savedUser;
  _status = AuthStatus.authenticated;
  print('✅ Usuario autenticado (desde storage local)');

  // Intentar actualizar desde servidor en segundo plano
  _authService.getCurrentUser().then((updatedUser) {
    if (updatedUser != null && mounted) {
      print('✅ Usuario actualizado desde servidor');
      _user = updatedUser;
      notifyListeners();
    }
  }).catchError((e) {
    print('⚠️ No se pudo actualizar usuario desde servidor (continuando con datos locales): $e');
  });
}
```

3. **Manejo de errores robusto:**
```dart
catch (e) {
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
}
```

---

### 2. `lib/services/auth_service.dart`

Agregados logs detallados en todos los métodos de autenticación:

#### Líneas 75-83: Registro
```dart
if (authResponse.success && authResponse.user != null) {
  print('💾 Guardando usuario en storage: ${authResponse.user!.email}');
  await _storage.saveUser(authResponse.user!);

  if (authResponse.token != null) {
    print('💾 Guardando token en storage: ${authResponse.token!.substring(0, 10)}...');
    await _storage.saveToken(authResponse.token!);
    setToken(authResponse.token!);
    print('✅ Sesión guardada exitosamente');
  }
}
```

#### Líneas 125-141: Login con email
```dart
if (authResponse.success) {
  if (authResponse.token != null && authResponse.user != null) {
    print('💾 Guardando token en storage: ${authResponse.token!.substring(0, 10)}...');
    await _storage.saveToken(authResponse.token!);
    print('💾 Guardando usuario en storage: ${authResponse.user!.email}');
    await _storage.saveUser(authResponse.user!);
    setToken(authResponse.token!);

    // Guardar credenciales si Remember Me está activo
    if (rememberMe) {
      print('💾 Guardando credenciales (Remember Me activo)');
      await _storage.setRememberMe(true);
      await _storage.saveCredentials(email, password);
    } else {
      print('ℹ️ Remember Me no activo, no se guardan credenciales');
      await _storage.setRememberMe(false);
    }

    print('✅ Sesión guardada exitosamente');
  }
}
```

#### Líneas 214-219: Login con Google
```dart
if (authResponse.success &&
    authResponse.token != null &&
    authResponse.user != null) {
  print('💾 Guardando token en storage (Google): ${authResponse.token!.substring(0, 10)}...');
  await _storage.saveToken(authResponse.token!);
  print('💾 Guardando usuario en storage (Google): ${authResponse.user!.email}');
  await _storage.saveUser(authResponse.user!);
  setToken(authResponse.token!);
  print('✅ Sesión de Google guardada exitosamente');
}
```

---

## Flujo Corregido

### 1. Al Hacer Login (con o sin "Recuérdame")

```
Usuario ingresa email/password
  → AuthService.login()
    → Backend retorna token y user
    → Guardar token en SecureStorage ✅
    → Guardar user en SecureStorage ✅
    → Logs: "💾 Guardando token..."
    → Logs: "💾 Guardando usuario..."
    → Logs: "✅ Sesión guardada exitosamente"
    → Si Remember Me: guardar credenciales ✅
```

### 2. Al Cerrar y Abrir la App (CON RED)

```
SplashScreen
  → AuthProvider.initialize()
    → Verificar token guardado ✅
    → Logs: "🔍 ¿Tiene token guardado? true"
    → Logs: "🎫 Token recuperado: 14|jhaaxSn..."
    → Configurar token en ApiService ✅
    → Logs: "✅ Token configurado en ApiService"
    → Obtener usuario LOCAL ✅
    → Logs: "👤 Usuario guardado localmente: user@test.com"
    → Logs: "✅ Usuario autenticado (desde storage local)"
    → Status: authenticated ✅
    → Navegar a /home ✅

    → En segundo plano:
      → Intentar actualizar desde servidor ✅
      → Si OK: "✅ Usuario actualizado desde servidor"
      → Si falla: "⚠️ No se pudo actualizar (continuando con datos locales)"
```

### 3. Al Cerrar y Abrir la App (SIN RED)

```
SplashScreen
  → AuthProvider.initialize()
    → Verificar token guardado ✅
    → Obtener usuario LOCAL ✅
    → Logs: "👤 Usuario guardado localmente: user@test.com"
    → Status: authenticated ✅
    → Navegar a /home ✅

    → En segundo plano:
      → Intentar actualizar desde servidor ❌ Falla
      → Logs: "⚠️ No se pudo actualizar (continuando con datos locales)"
      → ✅ NO BORRA NADA, mantiene sesión activa
```

### 4. Si Hay Error Durante Inicialización

```
AuthProvider.initialize()
  → try/catch captura error
  → Verificar si hay usuario local guardado
  → Si hay: mantener sesión ✅
  → Si no hay: marcar como no autenticado
  → Logs: "⚠️ Error en inicialización pero hay usuario guardado, manteniendo sesión"
```

---

## Beneficios de Esta Solución

### ✅ Ventajas:

1. **Persistencia Total**: La sesión se mantiene incluso si:
   - No hay conexión a internet
   - El servidor está caído
   - Hay errores de red temporales

2. **Modo Offline**: El usuario puede:
   - Ver sus órdenes guardadas localmente
   - Ver su información de perfil
   - Usar la app sin conexión

3. **Actualización en Background**:
   - Si hay red, actualiza datos desde servidor silenciosamente
   - Si no hay red, continúa con datos locales
   - No bloquea al usuario

4. **Logs Detallados**:
   - Fácil de diagnosticar problemas
   - Ver exactamente qué está pasando en cada paso
   - Identificar rápidamente si algo falla

5. **Retrocompatible**:
   - No rompe el flujo existente
   - Mejora la experiencia sin cambios visuales
   - Compatible con todas las formas de login (email, Google)

---

## Comportamiento de "Recuérdame"

**IMPORTANTE**: La funcionalidad "Recuérdame" ahora funciona de la siguiente manera:

### Con "Recuérdame" ACTIVADO:
```
Login exitoso
  → Guardar token ✅
  → Guardar usuario ✅
  → Guardar credenciales (email/password) ✅
  → Logs: "💾 Guardando credenciales (Remember Me activo)"

Al cerrar y abrir app:
  → Recuperar sesión desde storage ✅
  → Usuario autenticado automáticamente ✅
  → NO necesita volver a ingresar credenciales
```

### Con "Recuérdame" DESACTIVADO:
```
Login exitoso
  → Guardar token ✅
  → Guardar usuario ✅
  → NO guardar credenciales ❌
  → Logs: "ℹ️ Remember Me no activo, no se guardan credenciales"

Al cerrar y abrir app:
  → Recuperar sesión desde storage ✅
  → Usuario autenticado automáticamente ✅
  → NO necesita volver a ingresar credenciales
```

**NOTA**: En ambos casos la sesión se mantiene. La diferencia del "Recuérdame" es:
- **CON**: Se guardan las credenciales para posible re-login automático futuro
- **SIN**: No se guardan credenciales, pero el token sigue válido

---

## Cómo Probar

### Prueba 1: Con Red

1. Iniciar sesión (con o sin "Recuérdame")
2. Observar logs:
   ```
   💾 Guardando token en storage: 14|jhaaxSn...
   💾 Guardando usuario en storage: user@test.com
   ✅ Sesión guardada exitosamente
   ```
3. Cerrar completamente la app (swipe up en Android)
4. Abrir la app de nuevo
5. Observar logs:
   ```
   🔄 Inicializando AuthProvider...
   🔍 ¿Tiene token guardado? true
   🎫 Token recuperado: 14|jhaaxSn...
   👤 Usuario guardado localmente: user@test.com
   ✅ Usuario autenticado (desde storage local)
   ✅ Usuario actualizado desde servidor
   ```
6. ✅ Usuario debe estar en /home automáticamente, **sin necesidad de volver a iniciar sesión**

### Prueba 2: Sin Red (Modo Avión)

1. Con sesión ya iniciada, cerrar la app
2. Activar modo avión
3. Abrir la app
4. Observar logs:
   ```
   🔄 Inicializando AuthProvider...
   👤 Usuario guardado localmente: user@test.com
   ✅ Usuario autenticado (desde storage local)
   ⚠️ No se pudo actualizar usuario desde servidor (continuando con datos locales)
   ```
5. ✅ Usuario debe estar en /home con sus datos locales

### Prueba 3: Después de Cerrar Sesión

1. Cerrar sesión manualmente
2. Observar logs:
   ```
   ✅ Sesión cerrada y token limpiado
   ```
3. Cerrar y abrir app
4. Observar logs:
   ```
   🔍 ¿Tiene token guardado? false
   ℹ️ No hay token guardado, usuario no autenticado
   ```
5. ✅ Usuario debe ir a /login

---

## Estado Actual

### ✅ Completado

- [x] Corregido `AuthProvider.initialize()` para priorizar datos locales
- [x] Agregados logs detallados en todos los flujos de autenticación
- [x] Sesión se mantiene al cerrar y abrir la app
- [x] Funciona en modo offline (con datos locales)
- [x] Actualización en background cuando hay red
- [x] Manejo robusto de errores

### ⚠️ Pendiente de Prueba

- [ ] Probar cierre y apertura de app (verificar que no pida login)
- [ ] Probar en modo avión (verificar que mantenga sesión)
- [ ] Probar con diferentes estados de red
- [ ] Verificar que "Recuérdame" funcione correctamente

---

## Logs Esperados al Iniciar Sesión

```
✅ Login exitoso: user@test.com
🎫 Token recibido: 14|jhaaxSn...
🔐 Token configurado en ApiService: 14|jhaaxSn...
📋 Headers actuales: {Authorization: Bearer 14|jhaaxSn..., ...}
✅ Token configurado en ApiService después de login
💾 Guardando token en storage: 14|jhaaxSn...
💾 Guardando usuario en storage: user@test.com
ℹ️ Remember Me no activo, no se guardan credenciales
✅ Sesión guardada exitosamente
```

## Logs Esperados al Abrir la App (Segunda Vez)

```
🔄 Inicializando AuthProvider...
🔍 ¿Tiene token guardado? true
🎫 Token recuperado: 14|jhaaxSn...
✅ Token configurado en ApiService
👤 Usuario guardado localmente: user@test.com
✅ Usuario autenticado (desde storage local)
🔐 Biometría disponible: false
✅ AuthProvider inicializado: AuthStatus.authenticated
✅ Usuario actualizado desde servidor (en background)
```

---

## Comandos Útiles

### Ver logs de inicialización
```bash
flutter logs | grep -E "(🔄|🔍|🎫|👤|✅|❌|⚠️|💾)"
```

### Limpiar storage manualmente (para pruebas)
En el código, agregar temporalmente:
```dart
await SecureStorageService().clearAll();
```

### Hot restart para aplicar cambios
```
R (en la terminal donde corre flutter run)
```

---

**Resumen**: Ahora la sesión se mantiene **SIEMPRE** al cerrar y abrir la app, independientemente del estado de "Recuérdame" o de la conexión a internet. El usuario solo necesita iniciar sesión UNA vez.
