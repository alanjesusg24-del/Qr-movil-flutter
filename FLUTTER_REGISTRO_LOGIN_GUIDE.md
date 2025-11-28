# Guía de Integración Flutter - Registro y Login

## 📋 Resumen de Cambios en Laravel

### ✅ Cambios Realizados

1. **Validación de `device_id` REMOVIDA**
   - Ya NO se valida que el device_id sea único
   - Un mismo dispositivo puede tener múltiples cuentas
   - El campo `device_id` es **OPCIONAL** en registro y login

2. **Campos Requeridos**
   - **Registro**: Solo `email` y `password` (mínimo 6 caracteres)
   - **Login**: Solo `email` y `password`
   - **device_id**: Completamente opcional

3. **Comportamiento**
   - Puedes registrar múltiples cuentas desde el mismo dispositivo
   - Puedes hacer login desde cualquier dispositivo
   - Si envías `device_id` en el login, se actualiza automáticamente

---

## 🔧 Configuración en Flutter

### 1. **Generar Device ID (Opcional)**

Si quieres enviar un `device_id`, puedes generarlo de estas formas:

#### Opción A: Usar `device_info_plus` (Recomendado)

```yaml
# pubspec.yaml
dependencies:
  device_info_plus: ^10.1.2
  uuid: ^4.5.1
```

```dart
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  // Verificar si ya existe un device_id guardado
  String? deviceId = prefs.getString('device_id');

  if (deviceId != null && deviceId.isNotEmpty) {
    return deviceId;
  }

  // Generar nuevo device_id
  final deviceInfo = DeviceInfoPlugin();
  String newDeviceId;

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    // Usar UUID basado en información del dispositivo
    newDeviceId = const Uuid().v5(
      Uuid.NAMESPACE_URL,
      '${androidInfo.id}-${androidInfo.model}-${androidInfo.device}',
    );
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    newDeviceId = const Uuid().v5(
      Uuid.NAMESPACE_URL,
      '${iosInfo.identifierForVendor}-${iosInfo.model}',
    );
  } else {
    // Fallback: UUID aleatorio
    newDeviceId = const Uuid().v4();
  }

  // Guardar para futuros usos
  await prefs.setString('device_id', newDeviceId);

  return newDeviceId;
}
```

#### Opción B: UUID Simple (Más fácil)

```yaml
# pubspec.yaml
dependencies:
  uuid: ^4.5.1
  shared_preferences: ^2.3.3
```

```dart
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  String? deviceId = prefs.getString('device_id');

  if (deviceId == null || deviceId.isEmpty) {
    deviceId = const Uuid().v4();
    await prefs.setString('device_id', deviceId);
  }

  return deviceId;
}
```

#### Opción C: No enviar device_id (Más simple)

Si no necesitas rastrear dispositivos, simplemente **NO envíes el campo**:

```dart
// En el registro y login, omite el campo device_id
final response = await http.post(
  Uri.parse('$baseUrl/api/v1/auth/register'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'password': password,
    // NO incluir device_id
  }),
);
```

---

## 📡 Endpoints API

### **Base URL**
```
https://tu-ngrok-url.ngrok-free.app/api/v1/auth
```

### **Headers Requeridos**
```dart
final headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'ngrok-skip-browser-warning': 'true', // Solo para ngrok
};
```

---

## 🔐 1. Registro de Usuario

### **Endpoint**
```
POST /api/v1/auth/register
```

### **Request Body**

```json
{
  "email": "usuario@example.com",
  "password": "123456",
  "device_id": "optional-uuid-here" // OPCIONAL
}
```

### **Validaciones**
- `email`: Requerido, formato email válido, debe ser único
- `password`: Requerido, mínimo 6 caracteres
- `device_id`: **OPCIONAL**, puede omitirse

### **Respuesta Exitosa (201)**

```json
{
  "success": true,
  "message": "Usuario registrado exitosamente",
  "token": "40|W9fXg14mWBSLWV98SM3gyo1vILGis8qYswZKj0TR...",
  "user": {
    "id": 9,
    "email": "usuario@example.com",
    "device_id": "optional-uuid-here",
    "email_verified": true
  }
}
```

### **Respuesta de Error (422)**

```json
{
  "success": false,
  "message": "Error de validación",
  "errors": {
    "email": ["El correo electrónico ya está registrado"]
  }
}
```

### **Código Flutter**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  String? deviceId, // OPCIONAL
}) async {
  final url = Uri.parse('https://tu-ngrok-url.ngrok-free.app/api/v1/auth/register');

  final body = <String, dynamic>{
    'email': email,
    'password': password,
  };

  // Solo agregar device_id si se proporciona
  if (deviceId != null && deviceId.isNotEmpty) {
    body['device_id'] = deviceId;
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      // Registro exitoso
      print('Token: ${data['token']}');
      print('User ID: ${data['user']['id']}');

      // Guardar token en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setInt('user_id', data['user']['id']);
      await prefs.setString('user_email', data['user']['email']);

      return data;
    } else {
      // Error de validación o servidor
      throw Exception(data['message'] ?? 'Error al registrar');
    }
  } catch (e) {
    print('Error en registro: $e');
    rethrow;
  }
}
```

---

## 🔑 2. Login de Usuario

### **Endpoint**
```
POST /api/v1/auth/login
```

### **Request Body**

```json
{
  "email": "usuario@example.com",
  "password": "123456",
  "device_id": "optional-uuid-here" // OPCIONAL
}
```

### **Validaciones**
- `email`: Requerido
- `password`: Requerido
- `device_id`: **OPCIONAL**

### **Respuesta Exitosa (200)**

```json
{
  "success": true,
  "message": "Login exitoso",
  "token": "41|7LnJJ0kZ3ZAYrC5hfSsdSts1laij2kGtFNwOw2Z...",
  "user": {
    "id": 9,
    "email": "usuario@example.com",
    "device_id": "optional-uuid-here",
    "email_verified": true
  }
}
```

### **Respuesta de Error (401)**

```json
{
  "success": false,
  "message": "Credenciales incorrectas"
}
```

### **Código Flutter**

```dart
Future<Map<String, dynamic>> login({
  required String email,
  required String password,
  String? deviceId, // OPCIONAL
}) async {
  final url = Uri.parse('https://tu-ngrok-url.ngrok-free.app/api/v1/auth/login');

  final body = <String, dynamic>{
    'email': email,
    'password': password,
  };

  // Solo agregar device_id si se proporciona
  if (deviceId != null && deviceId.isNotEmpty) {
    body['device_id'] = deviceId;
  }

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Login exitoso
      print('Token: ${data['token']}');

      // Guardar token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', data['token']);
      await prefs.setInt('user_id', data['user']['id']);
      await prefs.setString('user_email', data['user']['email']);

      return data;
    } else {
      // Credenciales incorrectas
      throw Exception(data['message'] ?? 'Error al hacer login');
    }
  } catch (e) {
    print('Error en login: $e');
    rethrow;
  }
}
```

---

## 👤 3. Obtener Usuario Actual

### **Endpoint**
```
GET /api/v1/auth/me
```

### **Headers**
```dart
{
  'Authorization': 'Bearer TU_TOKEN_AQUI',
  'Accept': 'application/json',
}
```

### **Respuesta Exitosa (200)**

```json
{
  "success": true,
  "user": {
    "id": 9,
    "email": "usuario@example.com",
    "device_id": "optional-uuid-here",
    "email_verified": true
  }
}
```

### **Código Flutter**

```dart
Future<Map<String, dynamic>> getCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    throw Exception('No hay sesión activa');
  }

  final url = Uri.parse('https://tu-ngrok-url.ngrok-free.app/api/v1/auth/me');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  } else {
    throw Exception('Error al obtener usuario');
  }
}
```

---

## 🚪 4. Logout

### **Endpoint**
```
POST /api/v1/auth/logout
```

### **Headers**
```dart
{
  'Authorization': 'Bearer TU_TOKEN_AQUI',
  'Accept': 'application/json',
}
```

### **Respuesta Exitosa (200)**

```json
{
  "success": true,
  "message": "Sesión cerrada exitosamente"
}
```

### **Código Flutter**

```dart
Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token != null) {
    final url = Uri.parse('https://tu-ngrok-url.ngrok-free.app/api/v1/auth/logout');

    await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    );
  }

  // Limpiar datos locales
  await prefs.remove('auth_token');
  await prefs.remove('user_id');
  await prefs.remove('user_email');
  await prefs.remove('device_id'); // Si lo usaste
}
```

---

## 📦 Dependencias Flutter Recomendadas

```yaml
dependencies:
  http: ^1.2.2
  shared_preferences: ^2.3.3
  uuid: ^4.5.1 # Solo si usas device_id
  device_info_plus: ^10.1.2 # Solo si usas device_id avanzado
```

---

## 🎯 Resumen de Campos

| Campo | Registro | Login | Requerido |
|-------|----------|-------|-----------|
| `email` | ✅ | ✅ | SÍ |
| `password` | ✅ | ✅ | SÍ |
| `device_id` | ✅ | ✅ | **NO** (Opcional) |

---

## ✅ Checklist de Implementación

- [ ] Instalar dependencias: `http`, `shared_preferences`
- [ ] Decidir si usar `device_id` o no
- [ ] Si usas `device_id`: Implementar función `getDeviceId()`
- [ ] Implementar función `register()`
- [ ] Implementar función `login()`
- [ ] Implementar función `getCurrentUser()`
- [ ] Implementar función `logout()`
- [ ] Guardar token en `SharedPreferences` después del login/registro
- [ ] Agregar header `ngrok-skip-browser-warning: true` para ngrok
- [ ] Probar registro con email único
- [ ] Probar login con credenciales correctas
- [ ] Probar obtener usuario actual
- [ ] Probar logout

---

## 🐛 Troubleshooting

### Error: "El correo electrónico ya está registrado"

**Solución**: Usa un email diferente o elimina el usuario existente de la base de datos.

### Error: "Credenciales incorrectas"

**Solución**: Verifica que el email y password sean correctos.

### Error: "Unauthenticated" al llamar `/me`

**Solución**: Verifica que estés enviando el token en el header `Authorization: Bearer TOKEN`.

### Error 500 en el servidor

**Solución**: Revisa los logs de Laravel en `storage/logs/laravel.log` para ver el error específico.

---

**Versión:** 2.0.0
**Fecha:** 2025-11-27
**Cambios principales:** Device ID completamente opcional, sin validaciones de dispositivo único
