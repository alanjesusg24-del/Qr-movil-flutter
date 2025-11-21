# Sistema de Autenticación con Vinculación de Dispositivo

## 🎯 Objetivos

1. **Autenticación múltiple**: Email/Contraseña y Google Sign-In
2. **Vinculación de dispositivo**: Una cuenta = Un dispositivo activo
3. **Seguridad robusta**: Verificación por email para cambios críticos
4. **Recuperación de dispositivo**: En caso de robo/pérdida

## 🏗️ Arquitectura del Sistema

### Base de Datos (Laravel)

#### Tabla `users`
```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255), -- Nullable para Google Sign-In
    google_id VARCHAR(255) UNIQUE NULLABLE,
    profile_photo_url TEXT NULLABLE,
    email_verified_at TIMESTAMP NULLABLE,
    current_device_id VARCHAR(255) NULLABLE, -- Device ID actualmente vinculado
    device_linked_at TIMESTAMP NULLABLE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX(email),
    INDEX(google_id),
    INDEX(current_device_id)
);
```

#### Tabla `device_change_requests`
```sql
CREATE TABLE device_change_requests (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    old_device_id VARCHAR(255) NULLABLE,
    new_device_id VARCHAR(255) NOT NULL,
    verification_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    verified_at TIMESTAMP NULLABLE,
    status ENUM('pending', 'verified', 'expired', 'cancelled') DEFAULT 'pending',
    ip_address VARCHAR(45) NULLABLE,
    user_agent TEXT NULLABLE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX(user_id),
    INDEX(verification_code),
    INDEX(status)
);
```

#### Tabla `login_attempts`
```sql
CREATE TABLE login_attempts (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    success BOOLEAN DEFAULT FALSE,
    failure_reason VARCHAR(255) NULLABLE,
    ip_address VARCHAR(45) NULLABLE,
    user_agent TEXT NULLABLE,
    created_at TIMESTAMP,
    INDEX(email),
    INDEX(device_id),
    INDEX(created_at)
);
```

#### Actualizar tabla `mobile_users`
```sql
ALTER TABLE mobile_users ADD COLUMN user_id BIGINT NULLABLE;
ALTER TABLE mobile_users ADD FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE mobile_users ADD COLUMN is_active BOOLEAN DEFAULT TRUE;
```

## 🔐 Flujos de Autenticación

### Flujo 1: Registro con Email/Contraseña

```
1. Usuario ingresa: nombre, email, contraseña
2. Backend valida datos
3. Backend crea usuario (email_verified_at = null)
4. Backend envía email con código de verificación (6 dígitos)
5. Usuario ingresa código
6. Backend verifica código
7. Backend vincula device_id al usuario
8. Backend retorna token de sesión
9. Usuario accede a la app
```

### Flujo 2: Login con Email/Contraseña (Primera vez en dispositivo)

```
1. Usuario ingresa: email, contraseña
2. Backend valida credenciales
3. Backend verifica si current_device_id == null
   - Si null: Vincula nuevo device_id y permite login
   - Si diferente: Rechaza y ofrece cambio de dispositivo
4. Backend retorna token de sesión
```

### Flujo 3: Login con Google (Primera vez)

```
1. Usuario toca "Continuar con Google"
2. Flutter inicia Google Sign-In
3. Usuario autoriza en Google
4. Flutter obtiene: google_id, name, email, photo
5. Flutter envía datos al backend + device_id
6. Backend verifica si existe usuario con ese google_id
   - Si no existe: Crea usuario nuevo
   - Si existe: Verifica device_id
7. Backend vincula device_id si es necesario
8. Backend retorna token de sesión
```

### Flujo 4: Cambio de Dispositivo (Dispositivo Perdido/Robado)

```
1. Usuario intenta login en nuevo dispositivo
2. Backend detecta: current_device_id != nuevo device_id
3. Backend ofrece: "¿Cambiar de dispositivo?"
4. Usuario confirma
5. Backend genera código de verificación (6 dígitos)
6. Backend envía email con código
7. Usuario ingresa código + contraseña
8. Backend valida código y contraseña
9. Backend actualiza:
   - current_device_id = nuevo device_id
   - device_linked_at = now()
10. Backend invalida sesiones del dispositivo anterior
11. Backend retorna token de sesión
```

### Flujo 5: Login Normal (Mismo Dispositivo)

```
1. Usuario abre app
2. App verifica token guardado localmente
3. Si token válido: Auto-login
4. Si token expirado: Solicita credenciales
```

## 📱 Estructura en Flutter

### Modelos

```dart
// lib/models/user.dart
class User {
  final int userId;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final String? googleId;
  final bool emailVerified;
  final String? currentDeviceId;
  final DateTime? deviceLinkedAt;
  final DateTime createdAt;
}

// lib/models/auth_response.dart
class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? message;
  final bool requiresDeviceChange;
  final bool requiresEmailVerification;
}

// lib/models/device_change_request.dart
class DeviceChangeRequest {
  final int requestId;
  final String oldDeviceId;
  final String newDeviceId;
  final DateTime expiresAt;
  final String status;
}
```

### Servicios

```dart
// lib/services/auth_service.dart
class AuthService {
  // Email/Password
  Future<AuthResponse> register({name, email, password, deviceId});
  Future<AuthResponse> login({email, password, deviceId});
  Future<bool> verifyEmail(String code);

  // Google Sign-In
  Future<AuthResponse> signInWithGoogle(String deviceId);

  // Device Management
  Future<DeviceChangeRequest> requestDeviceChange({email, password, newDeviceId});
  Future<bool> verifyDeviceChange({requestId, code, password});
  Future<bool> cancelDeviceChange(int requestId);

  // Session
  Future<bool> logout();
  Future<User?> getCurrentUser();
  Future<bool> isAuthenticated();
}
```

### Pantallas

```dart
// lib/screens/auth/login_screen.dart
// lib/screens/auth/register_screen.dart
// lib/screens/auth/verify_email_screen.dart
// lib/screens/auth/device_change_screen.dart
// lib/screens/auth/verify_device_change_screen.dart
```

## 🔒 Seguridad

### Medidas Implementadas

1. **Rate Limiting**
   - Máximo 5 intentos de login por hora por device_id
   - Máximo 3 intentos de verificación de código
   - Bloqueo temporal después de intentos fallidos

2. **Tokens de Sesión**
   - JWT con expiración de 30 días
   - Refresh tokens para renovación
   - Invalidación automática al cambiar dispositivo

3. **Códigos de Verificación**
   - 6 dígitos aleatorios
   - Expiración en 15 minutos
   - Un solo uso

4. **Validaciones**
   - Contraseña mínimo 8 caracteres
   - Email válido y único
   - Device ID único por usuario

5. **Logs de Auditoría**
   - Registro de todos los intentos de login
   - Registro de cambios de dispositivo
   - Registro de accesos sospechosos

## 📧 Emails del Sistema

### 1. Verificación de Email (Registro)
```
Asunto: Verifica tu cuenta - Order QR

Hola [Nombre],

Tu código de verificación es:

[123456]

Este código expira en 15 minutos.

Si no solicitaste este código, ignora este email.
```

### 2. Cambio de Dispositivo
```
Asunto: Solicitud de cambio de dispositivo - Order QR

Hola [Nombre],

Se ha solicitado vincular tu cuenta a un nuevo dispositivo.

Tu código de verificación es:

[123456]

Información del dispositivo:
- Modelo: [Samsung Galaxy S21]
- Sistema: [Android 12]
- IP: [192.168.1.100]
- Fecha: [19 Nov 2025, 10:30 AM]

Si no fuiste tú, cambia tu contraseña inmediatamente.

Este código expira en 15 minutos.
```

### 3. Dispositivo Cambiado (Confirmación)
```
Asunto: Tu cuenta ahora está vinculada a un nuevo dispositivo

Hola [Nombre],

Tu cuenta ha sido vinculada exitosamente a un nuevo dispositivo.

Detalles:
- Dispositivo anterior: [iPhone 12 Pro]
- Dispositivo nuevo: [Samsung Galaxy S21]
- Fecha: [19 Nov 2025, 10:35 AM]

Si no reconoces esta actividad, contacta soporte inmediatamente.
```

### 4. Intento de Acceso Sospechoso
```
Asunto: ⚠️ Intento de acceso desde dispositivo no autorizado

Hola [Nombre],

Detectamos un intento de acceso a tu cuenta desde un dispositivo no autorizado:

- Dispositivo: [Unknown]
- Ubicación: [Ciudad, País]
- IP: [192.168.1.200]
- Fecha: [19 Nov 2025, 11:00 AM]

El acceso fue bloqueado automáticamente.

Si fuiste tú, inicia el proceso de cambio de dispositivo.
Si no fuiste tú, cambia tu contraseña inmediatamente.
```

## 🚀 Endpoints de API

### Autenticación

```
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/login/google
POST /api/v1/auth/logout
POST /api/v1/auth/verify-email
POST /api/v1/auth/resend-verification
GET  /api/v1/auth/me
```

### Gestión de Dispositivos

```
POST /api/v1/auth/device/change-request
POST /api/v1/auth/device/verify-change
POST /api/v1/auth/device/cancel-request
GET  /api/v1/auth/device/current
```

### Recuperación

```
POST /api/v1/auth/password/forgot
POST /api/v1/auth/password/reset
POST /api/v1/auth/password/change
```

## 📊 Estados de la Cuenta

```dart
enum AccountStatus {
  active,              // Cuenta activa, puede usar la app
  emailNotVerified,    // Debe verificar email
  deviceNotLinked,     // Debe vincular dispositivo
  deviceChangePending, // Solicitud de cambio pendiente
  suspended,           // Cuenta suspendida
  deleted,             // Cuenta eliminada
}
```

## 🔄 Migración de Usuarios Existentes

Para usuarios que ya están usando la app sin autenticación:

```
1. Al actualizar la app, mostrar mensaje:
   "Nueva versión disponible con autenticación"

2. Ofrecer dos opciones:
   a) Crear cuenta nueva (vincula las órdenes existentes)
   b) Continuar sin cuenta (modo limitado, próximamente obligatorio)

3. Si crea cuenta:
   - Vincular device_id actual con nuevo usuario
   - Asociar todas las órdenes del mobile_user al nuevo user
   - Mantener historial
```

## ⚡ Optimizaciones

1. **Cache Local**
   - Guardar token en SecureStorage
   - Guardar datos de usuario en cache
   - Refresh automático de token

2. **Offline First**
   - Permitir acceso con token cacheado
   - Sincronizar al recuperar conexión

3. **UX Mejorada**
   - Auto-login si token válido
   - Biometría (huella/face ID) opcional
   - Remember me opcional

## 🧪 Casos de Prueba

### Escenarios a Probar

1. ✅ Registro nuevo usuario
2. ✅ Login usuario existente (mismo dispositivo)
3. ✅ Login usuario existente (dispositivo diferente) → Rechazado
4. ✅ Cambio de dispositivo con código
5. ✅ Cambio de dispositivo con código incorrecto → Rechazado
6. ✅ Código de verificación expirado → Rechazado
7. ✅ Múltiples intentos fallidos → Rate limit
8. ✅ Login con Google (nuevo usuario)
9. ✅ Login con Google (usuario existente)
10. ✅ Logout y reintentar login
11. ✅ Token expirado → Renovar
12. ✅ Recuperación de contraseña

## 📱 Dependencias Adicionales para Flutter

```yaml
dependencies:
  # Autenticación
  google_sign_in: ^6.2.1
  flutter_secure_storage: ^9.0.0

  # Biometría (opcional)
  local_auth: ^2.1.8

  # Estado
  flutter_bloc: ^8.1.3  # o riverpod
```

---

**Siguiente Paso:** Implementar la estructura en Laravel y Flutter

¿Quieres que comience con la implementación del backend (Laravel) o del frontend (Flutter) primero?
