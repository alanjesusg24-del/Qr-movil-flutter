# 🚀 Guía de Configuración Completa - Order QR Mobile

Esta guía te llevará paso a paso para configurar la aplicación Flutter desde cero.

---

## 📋 Tabla de Contenidos

1. [Requisitos Previos](#requisitos-previos)
2. [Instalación de Dependencias](#instalación-de-dependencias)
3. [Configuración de Firebase](#configuración-de-firebase)
4. [Configuración de la API](#configuración-de-la-api)
5. [Configuración de Android](#configuración-de-android)
6. [Configuración de iOS](#configuración-de-ios)
7. [Ejecutar la Aplicación](#ejecutar-la-aplicación)
8. [Troubleshooting](#troubleshooting)

---

## 1. Requisitos Previos

### ✅ Verificar Flutter

```bash
flutter --version
```

Debes tener Flutter 3.0.0 o superior. Si no lo tienes:
- Descarga desde: https://flutter.dev/docs/get-started/install

### ✅ Verificar Dart

```bash
dart --version
```

Debe ser 2.19 o superior (viene con Flutter).

### ✅ Verificar Android Studio / Xcode

```bash
# Para Android
flutter doctor

# Debe mostrar:
# ✓ Flutter
# ✓ Android toolchain
# ✓ Android Studio
```

---

## 2. Instalación de Dependencias

### Paso 1: Navegar al proyecto

```bash
cd C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile
```

### Paso 2: Instalar paquetes de Flutter

```bash
flutter pub get
```

Esto descargará todas las dependencias listadas en `pubspec.yaml`.

### Paso 3: Verificar instalación

```bash
flutter pub deps
```

Deberías ver una lista de todas las dependencias instaladas.

---

## 3. Configuración de Firebase

Firebase es necesario para las **notificaciones push**. Sigue estos pasos:

### 🔥 Opción A: Configuración Automática (RECOMENDADA)

#### Paso 1: Instalar FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

#### Paso 2: Agregar al PATH (si es necesario)

**Windows:**
Agrega esta ruta al PATH:
```
C:\Users\TU_USUARIO\AppData\Local\Pub\Cache\bin
```

**Verificar:**
```bash
flutterfire --version
```

#### Paso 3: Login en Firebase

```bash
firebase login
```

Esto abrirá tu navegador para iniciar sesión con Google.

#### Paso 4: Configurar Firebase en el proyecto

```bash
# Desde la raíz del proyecto
cd C:\Users\alanG\Documentos\VSC\Flutter\order_qr_mobile

flutterfire configure
```

Esto te preguntará:

1. **"Select a Firebase project"**
   - Si ya tienes un proyecto: Selecciónalo
   - Si no: Crea uno nuevo con un nombre como `order-qr-system`

2. **"Which platforms should your configuration support?"**
   - Selecciona: `android` y `ios` (usa espacio para seleccionar)

3. Esto generará automáticamente:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

#### Paso 5: Habilitar Cloud Messaging en Firebase Console

1. Ve a https://console.firebase.google.com/
2. Selecciona tu proyecto
3. Ve a **Build → Cloud Messaging**
4. Habilita **Firebase Cloud Messaging API (V1)**

---

### 🔥 Opción B: Configuración Manual

Si prefieres configurar manualmente:

#### Para Android:

1. Ve a https://console.firebase.google.com/
2. Crea un nuevo proyecto o selecciona uno existente
3. Haz clic en el ícono de Android
4. Ingresa el **package name**: `com.orderqr.mobile` (o el que prefieras)
5. Descarga `google-services.json`
6. Coloca el archivo en: `android/app/google-services.json`

#### Para iOS:

1. En Firebase Console, haz clic en el ícono de iOS
2. Ingresa el **bundle ID**: `com.orderqr.mobile` (debe coincidir con Android)
3. Descarga `GoogleService-Info.plist`
4. Coloca el archivo en: `ios/Runner/GoogleService-Info.plist`

#### Crear firebase_options.dart manualmente:

Crea el archivo `lib/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Unsupported platform');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_ANDROID',
    appId: 'TU_APP_ID_ANDROID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_STORAGE_BUCKET',
    iosBundleId: 'com.orderqr.mobile',
  );
}
```

**¿Dónde encuentro estos valores?**
- Ve a Firebase Console → Project Settings → General
- Busca tu app Android/iOS y copia los valores

---

## 4. Configuración de la API

### Paso 1: Ubicar el archivo de configuración

El archivo está en: `lib/config/api_config.dart`

### Paso 2: Editar la URL base

Abre el archivo y cambia:

```dart
class ApiConfig {
  // Cambiar esta URL por la URL de tu servidor Laravel
  static const String baseUrl = 'https://api.orderqrsystem.com/api/v1';

  // Si estás probando en local, usa una de estas:
  // Para Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  // Para dispositivo físico en la misma red WiFi:
  // static const String baseUrl = 'http://192.168.1.100:8000/api/v1';

  // Para servidor remoto:
  // static const String baseUrl = 'https://tuservidor.com/api/v1';
```

### Ejemplos según tu entorno:

#### A) Servidor Local (Laravel en tu PC)

**Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```

**Dispositivo físico (mismo WiFi):**
```dart
// Reemplaza 192.168.1.100 con la IP de tu PC
static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
```

**¿Cómo obtener la IP de tu PC?**
```bash
# Windows
ipconfig
# Busca "Dirección IPv4" en tu adaptador WiFi

# macOS/Linux
ifconfig
```

#### B) Servidor de Producción

```dart
static const String baseUrl = 'https://api.tudominio.com/api/v1';
```

### Paso 3: Configurar HTTPS (Producción)

Si tu servidor usa HTTPS con certificado autofirmado, puede fallar. Para desarrollo:

**NO RECOMENDADO PARA PRODUCCIÓN:**
Puedes desactivar la verificación SSL (solo para desarrollo):

```dart
// En api_service.dart, dentro de la configuración de Dio:
static final Dio _dio = Dio(
  BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectionTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    headers: ApiConfig.headers,
    // Solo para desarrollo con certificados autofirmados:
    validateStatus: (status) => true,
  ),
)..httpClientAdapter = IOHttpClientAdapter()
    ..options.extra['withCredentials'] = false;
```

---

## 5. Configuración de Android

### Paso 1: Editar AndroidManifest.xml

Archivo: `android/app/src/main/AndroidManifest.xml`

Agrega estos permisos dentro de `<manifest>`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permisos necesarios -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.VIBRATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="Order QR"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Tu código existente -->

    </application>
</manifest>
```

### Paso 2: Configurar versión mínima de Android

Archivo: `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 33

    defaultConfig {
        applicationId "com.orderqr.mobile"
        minSdkVersion 24  // Android 7.0
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }
}
```

### Paso 3: Agregar Google Services

Archivo: `android/build.gradle`

```gradle
buildscript {
    dependencies {
        classpath 'com.android.tools.build:gradle:7.3.0'
        classpath 'com.google.gms:google-services:4.3.15'  // Agregar esta línea
    }
}
```

Archivo: `android/app/build.gradle` (al final del archivo)

```gradle
apply plugin: 'com.google.gms.google-services'  // Agregar esta línea
```

---

## 6. Configuración de iOS

### Paso 1: Editar Info.plist

Archivo: `ios/Runner/Info.plist`

Agrega estos permisos antes de `</dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a la galería para guardar códigos QR</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### Paso 2: Configurar versión mínima

Archivo: `ios/Podfile`

Descomenta y edita:

```ruby
platform :ios, '12.0'
```

### Paso 3: Instalar Pods

```bash
cd ios
pod install
cd ..
```

### Paso 4: Configurar notificaciones en Xcode (iOS)

1. Abre el proyecto en Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. Selecciona el proyecto "Runner"
3. Ve a "Signing & Capabilities"
4. Haz clic en "+ Capability"
5. Agrega "Push Notifications"
6. Agrega "Background Modes" y marca "Remote notifications"

---

## 7. Ejecutar la Aplicación

### Paso 1: Limpiar proyecto

```bash
flutter clean
flutter pub get
```

### Paso 2: Verificar dispositivos disponibles

```bash
flutter devices
```

### Paso 3: Ejecutar en Android

```bash
# Emulador o dispositivo conectado
flutter run

# Especificar dispositivo
flutter run -d <device_id>
```

### Paso 4: Ejecutar en iOS

```bash
# Simulador o dispositivo conectado
flutter run

# Abrir simulador iOS
open -a Simulator
flutter run
```

### Paso 5: Ejecutar con logs

```bash
flutter run --verbose
```

---

## 8. Troubleshooting

### ❌ Error: "Failed to load Firebase"

**Solución:**
```bash
flutter clean
flutterfire configure
flutter pub get
flutter run
```

### ❌ Error: "Camera permission denied"

**Solución:**
- Desinstala la app del dispositivo
- Vuelve a ejecutar `flutter run`
- Acepta los permisos cuando se soliciten

### ❌ Error: "Could not resolve com.google.firebase"

**Solución:**
En `android/build.gradle`, agrega:
```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### ❌ Error: "API connection failed"

**Solución:**
1. Verifica que tu servidor Laravel esté corriendo
2. Verifica la URL en `api_config.dart`
3. Si estás en emulador, usa `http://10.0.2.2:8000`
4. Si estás en dispositivo físico, usa la IP de tu PC

### ❌ Error: "QR Scanner not working on iOS"

**Solución:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### ❌ Error: "Gradle build failed"

**Solución:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## ✅ Checklist Final

Antes de ejecutar, verifica:

- [ ] Flutter instalado (`flutter --version`)
- [ ] Dependencias instaladas (`flutter pub get`)
- [ ] Firebase configurado (`firebase_options.dart` existe)
- [ ] API URL configurada en `api_config.dart`
- [ ] Permisos en AndroidManifest.xml
- [ ] Permisos en Info.plist (iOS)
- [ ] Google Services agregado en Android
- [ ] Pods instalados (iOS)
- [ ] Dispositivo/emulador conectado (`flutter devices`)

---

## 📞 Necesitas Ayuda?

Si tienes problemas:

1. **Ejecuta:**
   ```bash
   flutter doctor -v
   ```
   Esto mostrará todos los problemas de configuración.

2. **Revisa los logs:**
   ```bash
   flutter run --verbose
   ```

3. **Limpia y reconstruye:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## 🎉 ¡Todo Listo!

Una vez configurado todo, la aplicación debería funcionar correctamente.

**Prueba estas funcionalidades:**
1. Abrir la app (debería mostrar splash screen)
2. Ver lista de órdenes (vacía al inicio)
3. Escanear un QR (requiere una orden creada en el backend)
4. Ver detalle de orden
5. Recibir notificaciones push

---

**Fecha de creación:** 2025-11-05
**Versión:** 1.0.0
