# Sistema de Autenticación Completo en Flutter

## 🎯 Características

- ✅ Login con Email y Contraseña
- ✅ Login con Google Sign-In
- ✅ Registro de nuevos usuarios
- ✅ Vinculación única de dispositivo
- ✅ Sistema de recuperación de dispositivo
- ✅ Tokens seguros con Flutter Secure Storage
- ✅ Auto-login con tokens guardados
- ✅ Biometría opcional (huella/Face ID)

## 📦 Paso 1: Instalar Dependencias

Ya agregué las dependencias al `pubspec.yaml`. Ejecuta:

```bash
flutter pub get
```

## 🔧 Paso 2: Configurar Google Sign-In

### Android

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona el proyecto `focus-qr`
3. Ve a **APIs & Services** → **Credentials**
4. Crea un **OAuth 2.0 Client ID** para Android:
   - Application type: **Android**
   - Package name: `com.orderqr.mobile`
   - SHA-1: Obtén tu SHA-1 con:
     ```bash
     cd android
     ./gradlew signingReport
     ```
   - Copia el SHA-1 que aparece en `Variant: debug, Config: debug`

### iOS

1. En Google Cloud Console, crea un **OAuth 2.0 Client ID** para iOS:
   - Application type: **iOS**
   - Bundle ID: `com.orderqr.mobile`

2. Descarga el archivo `GoogleService-Info.plist`

3. En `ios/Runner/Info.plist`, agrega:

```xml
<key>GIDClientID</key>
<string>TU_CLIENT_ID_AQUI.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.TU_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 📁 Estructura de Archivos a Crear

```
lib/
├── models/
│   ├── auth_user.dart                    # Modelo de usuario autenticado
│   ├── auth_response.dart                # Respuesta de autenticación
│   └── device_change_request.dart        # Solicitud de cambio de dispositivo
├── services/
│   ├── auth_service.dart                 # Servicio principal de autenticación
│   ├── secure_storage_service.dart       # Almacenamiento seguro de tokens
│   └── biometric_service.dart            # Servicio de biometría
├── providers/
│   └── auth_provider.dart                # Provider de estado de autenticación
├── screens/auth/
│   ├── login_screen.dart                 # Pantalla de login
│   ├── register_screen.dart              # Pantalla de registro
│   ├── verify_email_screen.dart          # Verificación de email
│   └── device_change_screen.dart         # Cambio de dispositivo
└── widgets/auth/
    ├── email_password_form.dart          # Formulario email/contraseña
    ├── google_sign_in_button.dart        # Botón de Google
    └── biometric_prompt.dart             # Prompt de biometría
```

Voy a crear cada archivo completo. Empiezo con los modelos:

## 📄 Modelos

### `lib/models/auth_user.dart`

```dart
class AuthUser {
  final int userId;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final String? googleId;
  final bool emailVerified;
  final String? currentDeviceId;
  final DateTime? deviceLinkedAt;
  final DateTime createdAt;

  AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    this.googleId,
    required this.emailVerified,
    this.currentDeviceId,
    this.deviceLinkedAt,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      profilePhotoUrl: json['profile_photo_url'],
      googleId: json['google_id'],
      emailVerified: json['email_verified'] ?? (json['email_verified_at'] != null),
      currentDeviceId: json['current_device_id'],
      deviceLinkedAt: json['device_linked_at'] != null
          ? DateTime.parse(json['device_linked_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'profile_photo_url': profilePhotoUrl,
      'google_id': googleId,
      'email_verified': emailVerified,
      'current_device_id': currentDeviceId,
      'device_linked_at': deviceLinkedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isDeviceLinked => currentDeviceId != null;
  bool get isGoogleUser => googleId != null;
}
```

### `lib/models/auth_response.dart`

```dart
class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final AuthUser? user;
  final bool requiresEmailVerification;
  final bool requiresDeviceChange;
  final int? userId;
  final int? requestId;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.requiresEmailVerification = false,
    this.requiresDeviceChange = false,
    this.userId,
    this.requestId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
      requiresEmailVerification: json['requires_email_verification'] ?? false,
      requiresDeviceChange: json['requires_device_change'] ?? false,
      userId: json['user_id'],
      requestId: json['request_id'],
    );
  }
}
```

### `lib/models/device_change_request.dart`

```dart
class DeviceChangeRequest {
  final int requestId;
  final String? oldDeviceId;
  final String newDeviceId;
  final DateTime expiresAt;
  final String status;

  DeviceChangeRequest({
    required this.requestId,
    this.oldDeviceId,
    required this.newDeviceId,
    required this.expiresAt,
    required this.status,
  });

  factory DeviceChangeRequest.fromJson(Map<String, dynamic> json) {
    return DeviceChangeRequest(
      requestId: json['request_id'] ?? json['id'],
      oldDeviceId: json['old_device_id'],
      newDeviceId: json['new_device_id'],
      expiresAt: DateTime.parse(json['expires_at']),
      status: json['status'] ?? 'pending',
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isPending => status == 'pending';
}
```

## 🔐 Servicios

### `lib/services/secure_storage_service.dart`

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyRememberMe = 'remember_me';

  // Token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // User
  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _keyUser, value: userJson);
  }

  Future<String?> getUser() async {
    return await _storage.read(key: _keyUser);
  }

  Future<void> deleteUser() async {
    await _storage.delete(key: _keyUser);
  }

  // Biometric
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // Remember Me
  Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: _keyRememberMe, value: remember.toString());
  }

  Future<bool> isRememberMe() async {
    final value = await _storage.read(key: _keyRememberMe);
    return value == 'true';
  }

  // Clear all
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
```

Continúo con el resto de servicios en el siguiente mensaje...

Por ahora, **¿quieres que:**
1. Continue creando todos los archivos uno por uno aquí?
2. Cree un documento completo con TODO el código?
3. Me enfoque solo en las partes más importantes primero?