# Instrucciones para Implementar Notificaciones Push en Flutter

## 📋 Resumen de Cambios Necesarios

Para que las notificaciones push funcionen correctamente, necesitas actualizar tu app Flutter para que envíe el **FCM Token** al backend en los siguientes momentos:

1. ✅ Durante el **registro** de nuevo usuario
2. ✅ Durante el **login**
3. ✅ Cuando el **token FCM se renueve**

---

## 🔧 Cambios Requeridos en Flutter

### 1. Actualizar el Endpoint de Registro

**Archivo:** `lib/services/api_service.dart` (o donde tengas tu lógica de registro)

**Antes:**
```dart
static Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  required String deviceId,
}) async {
  final response = await _dio.post(
    ApiConfig.register,
    data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
    },
  );
  return response.data;
}
```

**Después:**
```dart
static Future<Map<String, dynamic>> register({
  required String email,
  required String password,
  required String deviceId,
  String? fcmToken,  // ✅ NUEVO PARÁMETRO
}) async {
  // Obtener FCM token si no se proporcionó
  final token = fcmToken ?? await FirebaseMessaging.instance.getToken();

  final response = await _dio.post(
    ApiConfig.register,
    data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
      'fcm_token': token,                                    // ✅ AGREGAR
      'platform': Platform.isIOS ? 'ios' : 'android',        // ✅ AGREGAR
    },
  );
  return response.data;
}
```

---

### 2. Actualizar el Endpoint de Login

**Archivo:** `lib/services/api_service.dart`

**Antes:**
```dart
static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
  required String deviceId,
}) async {
  final response = await _dio.post(
    ApiConfig.login,
    data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
    },
  );
  return response.data;
}
```

**Después:**
```dart
static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
  required String deviceId,
  String? fcmToken,  // ✅ NUEVO PARÁMETRO
}) async {
  // Obtener FCM token si no se proporcionó
  final token = fcmToken ?? await FirebaseMessaging.instance.getToken();

  final response = await _dio.post(
    ApiConfig.login,
    data: {
      'email': email,
      'password': password,
      'device_id': deviceId,
      'fcm_token': token,                                    // ✅ AGREGAR
      'platform': Platform.isIOS ? 'ios' : 'android',        // ✅ AGREGAR
    },
  );
  return response.data;
}
```

---

### 3. Crear Método para Actualizar FCM Token

**Archivo:** `lib/services/api_service.dart`

**Nuevo método:**
```dart
/// Actualizar FCM token en el servidor
static Future<void> updateFcmToken(String fcmToken) async {
  try {
    await _dio.put(
      ApiConfig.updateFcmToken,  // '/api/v1/mobile/update-token'
      data: {
        'fcm_token': fcmToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      },
    );
    print('✅ FCM token actualizado en el servidor');
  } catch (e) {
    print('❌ Error al actualizar FCM token: $e');
  }
}
```

---

### 4. Actualizar ApiConfig con la Nueva Ruta

**Archivo:** `lib/config/api_config.dart`

```dart
class ApiConfig {
  // ... rutas existentes ...

  // Auth endpoints
  static const String register = '/api/v1/auth/register';
  static const String login = '/api/v1/auth/login';

  // Mobile endpoints
  static const String updateFcmToken = '/api/v1/mobile/update-token';  // ✅ AGREGAR

  // ... resto de rutas ...
}
```

---

### 5. Escuchar Renovación de FCM Token

**Archivo:** `lib/main.dart` o `lib/services/notification_service.dart`

Agrega un listener para cuando Firebase renueve el token:

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Inicializar notificaciones y escuchar cambios de token
  static Future<void> initialize() async {
    // Solicitar permisos
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificación concedidos');

      // Obtener token inicial
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        // Enviar al servidor (solo si ya está autenticado)
        await _sendTokenToServer(token);
      }

      // ✅ IMPORTANTE: Escuchar cuando el token se renueve
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        print('🔄 FCM Token renovado: $newToken');
        await _sendTokenToServer(newToken);
      });
    } else {
      print('❌ Permisos de notificación denegados');
    }
  }

  /// Enviar token al servidor
  static Future<void> _sendTokenToServer(String token) async {
    try {
      // Solo enviar si el usuario está autenticado
      final authToken = await SecureStorage.getToken(); // Tu método de storage
      if (authToken != null && authToken.isNotEmpty) {
        await ApiService.updateFcmToken(token);
      }
    } catch (e) {
      print('❌ Error al enviar token al servidor: $e');
    }
  }

  /// Obtener token FCM actual
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
```

---

### 6. Inicializar en main.dart

**Archivo:** `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Inicializar servicio de notificaciones
  await NotificationService.initialize();

  runApp(MyApp());
}
```

---

## 📦 Dependencias Necesarias

Asegúrate de tener estas dependencias en tu `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  flutter_local_notifications: ^16.1.0  # Para notificaciones locales
```

Ejecuta:
```bash
flutter pub get
```

---

## 🧪 Cómo Probar

### Paso 1: Verificar que el Token se Envía

1. Cierra sesión en la app si estás logueado
2. Inicia sesión nuevamente
3. Revisa los logs de Laravel en el servidor:

```bash
tail -f storage/logs/laravel.log
```

Deberías ver:
```
[INFO] FCM token registrado en login
  user_id: 14
  email: si@gmail.com
```

### Paso 2: Verificar en Base de Datos

Ejecuta en MySQL:
```sql
SELECT mobile_device_id, mobile_user_id, platform, is_active,
       SUBSTRING(fcm_token, 1, 30) as token_preview
FROM mobile_devices
WHERE mobile_user_id = 14;  -- Tu user ID
```

Deberías ver un registro con tu FCM token.

### Paso 3: Probar Notificación

1. Asocia una orden escaneando el QR
2. Desde el dashboard web, marca la orden como "Lista"
3. Deberías recibir una notificación push en tu dispositivo:
   - **Título:** "Tu pedido está listo"
   - **Mensaje:** "El pedido TAC-0001 está listo para recoger. ¡Te esperamos!"

---

## 🐛 Solución de Problemas

### No recibo notificaciones

**1. Verificar que el token se guardó:**
```sql
SELECT COUNT(*) FROM mobile_devices WHERE mobile_user_id = [TU_USER_ID];
```
Debe retornar al menos 1.

**2. Verificar logs del servidor:**
```bash
tail -f storage/logs/laravel.log | grep "Notification"
```

**3. Verificar que tienes FIREBASE_SERVER_KEY configurado:**

En tu archivo `.env`:
```env
FIREBASE_SERVER_KEY=tu_server_key_aqui
```

Para obtener el Server Key:
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Project Settings** (⚙️) > **Cloud Messaging**
4. Copia el **Server key** (bajo "Cloud Messaging API (Legacy)")

**4. Verificar permisos en el dispositivo:**
```dart
NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Autorización: ${settings.authorizationStatus}');
```

### El token no se actualiza

Asegúrate de que `NotificationService.initialize()` se llama ANTES de `runApp()` en `main.dart`.

### Error "Platform is not defined"

Agrega al inicio del archivo:
```dart
import 'dart:io' show Platform;
```

---

## 📝 Checklist de Implementación

- [ ] Actualizar método `register()` para enviar `fcm_token` y `platform`
- [ ] Actualizar método `login()` para enviar `fcm_token` y `platform`
- [ ] Crear método `updateFcmToken()` en ApiService
- [ ] Agregar ruta `updateFcmToken` en ApiConfig
- [ ] Crear `NotificationService` con listener de renovación de token
- [ ] Inicializar `NotificationService` en `main.dart`
- [ ] Verificar dependencias en `pubspec.yaml`
- [ ] Configurar `FIREBASE_SERVER_KEY` en backend (.env)
- [ ] Probar login y verificar que se guarda el token
- [ ] Probar recepción de notificación

---

## 🎯 Resultado Esperado

Después de implementar estos cambios:

✅ Cuando el usuario se registre → Se guarda su FCM token
✅ Cuando el usuario haga login → Se actualiza su FCM token
✅ Cuando Firebase renueve el token → Se actualiza automáticamente
✅ Cuando marques una orden como "lista" → El usuario recibe notificación push
✅ Cuando canceles una orden → El usuario recibe notificación de cancelación

---

## 📞 Soporte

Si encuentras algún problema:

1. Revisa los logs de Laravel: `tail -f storage/logs/laravel.log`
2. Revisa la base de datos: `SELECT * FROM mobile_devices`
3. Verifica que el FCM token no sea null en la app
4. Asegúrate de que `FIREBASE_SERVER_KEY` esté configurado

---

**Fecha de actualización:** 2025-11-28
**Versión:** 1.0.0
