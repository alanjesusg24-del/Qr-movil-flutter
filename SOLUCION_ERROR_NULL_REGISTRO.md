# Solución - Error "type 'null' is not a subtype of type 'String'"

## 🔴 Problema Original

Al intentar crear una cuenta en Flutter, aparecían dos errores:

1. **Primer intento:** `type 'null' is not a subtype of type 'String'`
2. **Segundo intento:** `the email has already been taken`

---

## 🔍 Causa del Problema

### El flujo del error:

```
1. Usuario llena formulario de registro
2. Flutter envía: { email, password } (SIN name)
3. Laravel crea usuario exitosamente
4. Laravel responde: { success: true, token: "...", user: { id, email, device_id, email_verified } }
5. Flutter intenta parsear user con AuthUser.fromJson()
6. ❌ ERROR: AuthUser.name es REQUERIDO pero Laravel NO lo envía
7. App crashea ANTES de guardar el token
8. Usuario intenta de nuevo
9. Laravel responde: "Email ya registrado" (porque el primer intento SÍ se guardó en la BD)
```

**Resumen:** El usuario se creaba en Laravel, pero Flutter crasheaba al parsear la respuesta porque esperaba un campo `name` que no existe.

---

## ✅ Solución Implementada

### Cambios en `lib/models/auth_user.dart`

#### 1. **Campo `name` ahora es opcional**

**Antes:**
```dart
class AuthUser {
  final String name; // ❌ Requerido
  // ...
}
```

**Ahora:**
```dart
class AuthUser {
  final String? name; // ✅ Opcional
  // ...
}
```

#### 2. **Campo `createdAt` también es opcional**

Laravel puede no enviar este campo en algunas respuestas.

**Antes:**
```dart
final DateTime createdAt; // ❌ Requerido
```

**Ahora:**
```dart
final DateTime? createdAt; // ✅ Opcional
```

#### 3. **Nuevo getter `displayName`**

Para tener siempre un nombre para mostrar:

```dart
/// Obtener nombre para mostrar (email si no hay nombre)
String get displayName => name ?? email.split('@')[0];
```

**Uso:**
- Si `name = "Juan Pérez"` → `displayName = "Juan Pérez"`
- Si `name = null` y `email = "juan@test.com"` → `displayName = "juan"`

#### 4. **fromJson mejorado**

```dart
factory AuthUser.fromJson(Map<String, dynamic> json) {
  return AuthUser(
    userId: json['user_id'] ?? json['id'],
    name: json['name'], // ✅ Puede ser null
    email: json['email'] ?? '',
    profilePhotoUrl: json['profile_photo_url'],
    googleId: json['google_id'],
    emailVerified: json['email_verified'] ?? (json['email_verified_at'] != null),
    currentDeviceId: json['current_device_id'] ?? json['device_id'], // ✅ Fallback
    deviceLinkedAt: json['device_linked_at'] != null
        ? DateTime.parse(json['device_linked_at'])
        : null,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null, // ✅ Puede ser null
  );
}
```

#### 5. **toJson corregido**

```dart
Map<String, dynamic> toJson() {
  return {
    'user_id': userId,
    'name': name, // ✅ Puede ser null
    'email': email,
    'profile_photo_url': profilePhotoUrl,
    'google_id': googleId,
    'email_verified': emailVerified,
    'current_device_id': currentDeviceId,
    'device_linked_at': deviceLinkedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(), // ✅ Safe call
  };
}
```

---

### Cambios en `lib/widgets/app_drawer.dart`

**Antes:**
```dart
accountName: Text(
  user?.name ?? 'Usuario',
  // ...
),
```

**Ahora:**
```dart
accountName: Text(
  user?.displayName ?? 'Usuario', // ✅ Usa displayName
  // ...
),
```

---

## 📊 Respuesta de Laravel vs Modelo Flutter

### Respuesta de Laravel (Registro):

```json
{
  "success": true,
  "message": "Usuario registrado exitosamente",
  "token": "40|W9fXg14mWBSLWV98SM3gyo1vILGis8qYswZKj0TR",
  "user": {
    "id": 9,
    "email": "usuario@example.com",
    "device_id": "abc-123",
    "email_verified": true
    // ← NO hay "name"
    // ← NO hay "created_at"
  }
}
```

### Modelo Flutter (AuthUser):

```dart
AuthUser(
  userId: 9,
  name: null,              // ✅ Ahora acepta null
  email: "usuario@example.com",
  profilePhotoUrl: null,
  googleId: null,
  emailVerified: true,
  currentDeviceId: "abc-123",
  deviceLinkedAt: null,
  createdAt: null,         // ✅ Ahora acepta null
)
```

---

## 🎯 Casos de Uso

### Caso 1: Usuario con Google (tiene name)

```dart
AuthUser(
  name: "Juan Pérez",
  email: "juan@gmail.com",
)

user.displayName // → "Juan Pérez"
```

### Caso 2: Usuario con Email/Password (sin name)

```dart
AuthUser(
  name: null,
  email: "maria@test.com",
)

user.displayName // → "maria"
```

---

## 🔧 Otros Archivos Modificados

### `lib/services/auth_service.dart`
- ✅ `deviceId` es opcional
- ✅ Solo se envía si no es null

### `lib/providers/auth_provider.dart`
- ✅ `deviceId` es opcional
- ✅ Compatible con respuestas sin `name`

### `lib/screens/auth/login_screen_cetam.dart`
- ✅ Maneja `deviceId` opcional
- ✅ No falla si DeviceProvider no está disponible

### `lib/screens/auth/register_screen_cetam.dart`
- ✅ Maneja `deviceId` opcional
- ✅ No falla si DeviceProvider no está disponible

---

## ✅ Pruebas Realizadas

### Escenario 1: Registro exitoso
```
1. Usuario ingresa: email="test@test.com", password="123456"
2. Flutter envía: { email, password }
3. Laravel responde: { success: true, token, user: { id, email, email_verified } }
4. ✅ Flutter parsea correctamente (name=null, createdAt=null)
5. ✅ Token guardado
6. ✅ Usuario autenticado
7. ✅ Navegación a /home
```

### Escenario 2: Email duplicado
```
1. Usuario intenta registrar email existente
2. Laravel responde: { success: false, errors: { email: ["ya registrado"] } }
3. ✅ Flutter muestra error correcto
4. ✅ No crashea
```

---

## 📝 Resumen de Cambios

| Archivo | Cambio | Razón |
|---------|--------|-------|
| `auth_user.dart` | `name` opcional | Laravel no envía `name` en registro |
| `auth_user.dart` | `createdAt` opcional | Laravel puede no enviarlo |
| `auth_user.dart` | Nuevo `displayName` | Fallback cuando `name` es null |
| `auth_user.dart` | `fromJson` mejorado | Parsea responses sin `name` |
| `auth_user.dart` | `toJson` corregido | Safe call en nullables |
| `app_drawer.dart` | Usa `displayName` | Evita mostrar null |

---

## 🚀 Estado Actual

✅ **Registro funciona correctamente**
- Con o sin `name`
- Con o sin `device_id`
- Con o sin `created_at`

✅ **Login funciona correctamente**
- Con credenciales válidas
- Muestra errores claros

✅ **UI funciona correctamente**
- Muestra email si no hay nombre
- No crashea con campos null

---

## 🐛 Si el Error Persiste

### Verificar en Laravel:

```bash
php artisan tinker

# Ver último usuario creado
>>> App\Models\MobileUser::latest()->first()

# Ver respuesta exacta de registro
>>> $response = App\Http\Controllers\Api\V1\Auth\AuthController@register(...)
```

### Verificar en Flutter:

```dart
// Agregar log temporal
print('JSON recibido: ${response.body}');
final data = jsonDecode(response.body);
print('User data: ${data['user']}');
```

---

**Versión:** 1.0.0
**Fecha:** 2025-11-27
**Estado:** ✅ Resuelto
