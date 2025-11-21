# Order QR System - Mobile App

> Aplicación móvil Flutter para el sistema de gestión de órdenes con códigos QR y notificaciones en tiempo real.

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-2.19+-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud%20Messaging-FFCA28?logo=firebase)](https://firebase.google.com)

## 📱 Características

- ✅ **Autenticación con Google** - Inicio de sesión rápido y seguro
- ✅ **Escaneo de códigos QR** para asociar órdenes con tu dispositivo
- ✅ **Visualización en tiempo real** de tus órdenes activas
- ✅ **Notificaciones push** cuando tu orden está lista
- ✅ **Timeline de estados** para seguir el progreso de tu orden
- ✅ **Código QR para recolección** generado automáticamente
- ✅ **Autenticación biométrica** (huella digital/Face ID) disponible después del primer login
- ✅ **Modo offline** con base de datos local SQLite
- ✅ **Diseño coherente** con Volt Dashboard

## 🎯 Capturas de Pantalla

_Próximamente_

---

## 📋 Tabla de Contenidos

- [Requisitos Previos](#-requisitos-previos)
- [Instalación Paso a Paso](#-instalación-paso-a-paso)
- [Configuración del Backend](#-configuración-del-backend)
- [Configuración de Firebase](#-configuración-de-firebase)
- [Ejecutar la Aplicación](#-ejecutar-la-aplicación)
- [Estructura del Proyecto](#%EF%B8%8F-estructura-del-proyecto)
- [Build para Producción](#-build-para-producción)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado lo siguiente:

### 1. Flutter SDK

**Windows, macOS y Linux:**

```bash
# Verificar si Flutter está instalado
flutter --version

# Si no está instalado, descárgalo desde:
# https://docs.flutter.dev/get-started/install
```

**Versión requerida:** Flutter 3.0.0 o superior

### 2. Git

```bash
# Verificar instalación
git --version

# Descargar desde: https://git-scm.com/downloads
```

### 3. Editor de código

- **Recomendado:** [Visual Studio Code](https://code.visualstudio.com/) con extensiones de Flutter y Dart
- **Alternativa:** [Android Studio](https://developer.android.com/studio) con plugins de Flutter

### 4. Herramientas específicas por plataforma

#### Para Android:
- **Android Studio** o **Android SDK CLI tools**
- **Java Development Kit (JDK)** 11 o superior
- Emulador Android o dispositivo físico con **USB debugging** habilitado

#### Para iOS (solo macOS):
- **Xcode** 13.0 o superior
- **CocoaPods** instalado
- Simulador iOS o dispositivo físico

### 5. Verificar instalación de Flutter

```bash
flutter doctor
```

Este comando mostrará qué herramientas están instaladas correctamente y cuáles faltan.

**Ejemplo de salida correcta:**
```
[✓] Flutter (Channel stable, 3.24.0)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio (version 2023.1)
[✓] VS Code (version 1.90)
[✓] Connected device (1 available)
```

---

## 📦 Instalación Paso a Paso

### Paso 1: Clonar el repositorio

```bash
# Clonar el proyecto
git clone https://github.com/tu-usuario/order_qr_mobile.git

# Navegar al directorio
cd order_qr_mobile
```

### Paso 2: Instalar dependencias de Flutter

```bash
# Descargar todos los paquetes necesarios
flutter pub get
```

Este comando instalará las siguientes dependencias principales:
- `provider` - Gestión de estado
- `dio` - Cliente HTTP para API calls
- `sqflite` - Base de datos SQLite local
- `firebase_core` & `firebase_messaging` - Notificaciones push
- `qr_code_scanner` - Escaneo de códigos QR
- `qr_flutter` - Generación de códigos QR
- `device_info_plus` - Información del dispositivo
- Y más...

### Paso 3: Configurar permisos de Android

No es necesario hacer cambios manuales, los permisos ya están configurados en `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Paso 4: Configurar permisos de iOS (solo macOS)

Los permisos ya están configurados en `ios/Runner/Info.plist`, pero puedes verificar:

```bash
# Instalar dependencias de iOS
cd ios
pod install
cd ..
```

---

## 🔧 Configuración del Backend

Esta app requiere un backend Laravel que provea la API REST. Sigue estos pasos:

### Opción 1: Backend en servidor local (desarrollo)

Si tienes el backend corriendo en tu máquina local:

#### Para emulador Android:
```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
```
`10.0.2.2` es la IP especial que el emulador Android usa para acceder a `localhost` de la máquina host.

#### Para dispositivo físico Android:
```dart
// lib/config/api_config.dart
static const String baseUrl = 'http://192.168.1.100:8000/api/v1';
```
Reemplaza `192.168.1.100` con la IP de tu computadora en la red local.

**Obtener tu IP local:**

**Windows:**
```bash
ipconfig
# Buscar "Dirección IPv4"
```

**macOS/Linux:**
```bash
ifconfig
# o
ip addr show
```

### Opción 2: Backend con ngrok (acceso público temporal)

Si usas ngrok para exponer tu servidor local:

```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://tu-subdominio.ngrok-free.app/api/v1';
```

**Ejemplo:**
```dart
static const String baseUrl = 'https://gerald-ironical-contradictorily.ngrok-free.app/api/v1';
```

### Opción 3: Backend en producción

Si tienes el backend desplegado en un servidor:

```dart
// lib/config/api_config.dart
static const String baseUrl = 'https://api.tudominio.com/api/v1';
```

### Verificar conexión al backend

Antes de ejecutar la app, verifica que el backend esté corriendo:

```bash
# Prueba el endpoint de registro
curl -X POST https://tu-backend.com/api/v1/mobile/register \
  -H "Content-Type: application/json" \
  -d '{"device_id": "test-device", "device_name": "Test", "platform": "android"}'
```

Deberías recibir una respuesta JSON exitosa.

---

## 🔥 Configuración de Firebase

Firebase es necesario para las notificaciones push. Tienes dos opciones:

### Opción 1: Usando FlutterFire CLI (Recomendado - Más fácil)

```bash
# 1. Instalar FlutterFire CLI globalmente
dart pub global activate flutterfire_cli

# 2. Asegurarte de tener Firebase CLI instalado
npm install -g firebase-tools

# 3. Login en Firebase
firebase login

# 4. Configurar Firebase para el proyecto Flutter
flutterfire configure
```

El CLI te guiará para:
- Seleccionar o crear un proyecto Firebase
- Configurar apps para Android, iOS y Web
- Generar archivos de configuración automáticamente

### Opción 2: Configuración Manual

#### 1. Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Agregar proyecto"
3. Sigue el asistente de configuración

#### 2. Configurar Android

1. En Firebase Console, haz clic en el ícono de Android
2. **Nombre del paquete:** `com.orderqr.mobile` (debe coincidir con `applicationId` en `android/app/build.gradle`)
3. Descarga `google-services.json`
4. Coloca el archivo en: `android/app/google-services.json`

#### 3. Configurar iOS (opcional, solo macOS)

1. En Firebase Console, haz clic en el ícono de iOS
2. **Bundle ID:** `com.orderqr.mobile` (debe coincidir con el Bundle ID en Xcode)
3. Descarga `GoogleService-Info.plist`
4. Coloca el archivo en: `ios/Runner/GoogleService-Info.plist`

#### 4. Habilitar Cloud Messaging

1. En Firebase Console, ve a **Build** → **Cloud Messaging**
2. Habilita la API de Cloud Messaging
3. Para iOS, sube tu certificado APNs (Apple Push Notification service)

### Verificar configuración de Firebase

```bash
# Ejecutar el proyecto
flutter run

# En los logs deberías ver:
# ✅ Dispositivo inicializado: [device-id]
# ✅ Permisos de notificación concedidos
# 📱 FCM Token: [token]
```

---

## ▶️ Ejecutar la Aplicación

### 1. Conectar un dispositivo

#### Opción A: Dispositivo físico Android

1. **Habilitar modo desarrollador:**
   - Ir a **Configuración** → **Acerca del teléfono**
   - Tocar **Número de compilación** 7 veces

2. **Habilitar depuración USB:**
   - Ir a **Configuración** → **Opciones de desarrollador**
   - Activar **Depuración USB**

3. **Conectar vía USB** y verificar:
```bash
flutter devices
```

Deberías ver tu dispositivo listado.

#### Opción B: Emulador Android

```bash
# Ver emuladores disponibles
flutter emulators

# Iniciar un emulador
flutter emulators --launch Pixel_5_API_33

# O abrir desde Android Studio:
# Tools → Device Manager → Create Device
```

#### Opción C: Simulador iOS (solo macOS)

```bash
# Abrir simulador
open -a Simulator

# Verificar dispositivos
flutter devices
```

### 2. Ejecutar en modo debug

```bash
# Ejecutar en el dispositivo conectado
flutter run

# Ejecutar en un dispositivo específico
flutter run -d <device-id>

# Ejemplo:
flutter run -d emulator-5554
```

### 3. Hot Reload durante desarrollo

Mientras la app está corriendo:
- Presiona **`r`** para Hot Reload (recarga rápida)
- Presiona **`R`** para Hot Restart (reinicio completo)
- Presiona **`q`** para salir

### 4. Ejecutar en modo release (más rápido)

```bash
flutter run --release
```

---

## 🏗️ Estructura del Proyecto

```
order_qr_mobile/
├── android/                      # Configuración Android nativa
├── ios/                          # Configuración iOS nativa
├── lib/
│   ├── main.dart                 # Punto de entrada de la app
│   ├── config/                   # Configuraciones globales
│   │   ├── api_config.dart       # URLs y endpoints del backend
│   │   ├── firebase_config.dart  # Configuración de Firebase
│   │   └── theme.dart            # Tema y estilos (Volt design)
│   ├── models/                   # Modelos de datos
│   │   ├── order.dart            # Modelo de orden
│   │   ├── business.dart         # Modelo de negocio
│   │   └── mobile_user.dart      # Modelo de usuario móvil
│   ├── services/                 # Lógica de negocio y servicios
│   │   ├── api_service.dart      # Cliente HTTP (Dio)
│   │   ├── notification_service.dart  # Firebase Cloud Messaging
│   │   ├── database_service.dart # SQLite local
│   │   └── qr_service.dart       # Escaneo y generación de QR
│   ├── providers/                # Gestión de estado (Provider)
│   │   ├── orders_provider.dart  # Estado de órdenes
│   │   └── device_provider.dart  # Estado del dispositivo
│   ├── screens/                  # Pantallas de la app
│   │   ├── splash_screen.dart    # Pantalla de carga inicial
│   │   ├── home_screen.dart      # Pantalla principal (lista de órdenes)
│   │   ├── scan_qr_screen.dart   # Pantalla de escaneo QR
│   │   ├── order_detail_screen.dart  # Detalles de la orden
│   │   └── settings_screen.dart  # Configuraciones (próximamente)
│   ├── widgets/                  # Componentes reutilizables
│   │   ├── volt_card.dart        # Card estilo Volt
│   │   ├── volt_button.dart      # Botón estilo Volt
│   │   ├── volt_badge.dart       # Badge de estado
│   │   ├── order_card.dart       # Card de orden
│   │   ├── order_timeline.dart   # Timeline de estados
│   │   └── qr_display.dart       # Visualización de QR
│   └── utils/                    # Utilidades
│       ├── constants.dart        # Constantes
│       ├── helpers.dart          # Funciones helper
│       └── validators.dart       # Validadores
├── assets/                       # Recursos estáticos
│   ├── images/                   # Imágenes
│   └── fonts/                    # Fuentes personalizadas
├── test/                         # Tests unitarios
├── integration_test/             # Tests de integración
├── pubspec.yaml                  # Dependencias y metadatos
└── README.md                     # Esta guía
```

---

## 📦 Build para Producción

### Android

#### APK (para distribución directa)

```bash
# Build APK de release
flutter build apk --release

# El APK estará en:
# build/app/outputs/flutter-apk/app-release.apk
```

#### App Bundle (para Google Play Store)

```bash
# Build App Bundle
flutter build appbundle --release

# El AAB estará en:
# build/app/outputs/bundle/release/app-release.aab
```

**Nota:** Google Play requiere App Bundles (.aab) desde agosto 2021.

#### Firmar la app para producción

1. Crear un keystore:
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Crear `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<ruta-al-keystore>
```

3. El archivo `android/app/build.gradle` ya está configurado para usar el keystore.

### iOS (solo macOS)

```bash
# Build para iOS
flutter build ios --release
```

Luego:
1. Abrir `ios/Runner.xcworkspace` en Xcode
2. Seleccionar **Product** → **Archive**
3. Subir a App Store Connect

---

## 🐛 Troubleshooting

### Error: "Failed to load Firebase" o "FirebaseApp not initialized"

**Solución:**
```bash
# Reconfigurar Firebase
flutterfire configure

# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```

### Error: "Camera permission denied"

**Android:**
- Verifica que `AndroidManifest.xml` tenga `<uses-permission android:name="android.permission.CAMERA"/>`
- Desinstala y reinstala la app

**iOS:**
- Verifica que `Info.plist` tenga `NSCameraUsageDescription`
- Reinstala la app

### Error: "API connection failed" o timeout

**Causas comunes:**

1. **Backend no está corriendo**
   ```bash
   # Verificar que el backend esté activo
   curl https://tu-backend.com/api/v1/health
   ```

2. **URL incorrecta en `api_config.dart`**
   - Revisa que la URL sea correcta
   - Verifica que termine en `/api/v1`

3. **Firewall bloqueando conexión**
   - Si usas emulador con backend local, usa `http://10.0.2.2:8000`
   - Si usas dispositivo físico, asegúrate de estar en la misma red WiFi

4. **Problema con HTTPS/SSL**
   - Si usas ngrok, asegúrate de usar `https://`

### Error: type 'String' is not a subtype of type 'int'

Este error aparece cuando el backend devuelve datos en formato incorrecto.

**Solución:**
- Verifica que el backend esté actualizado con el schema correcto
- Revisa los logs del backend para ver qué está devolviendo
- Asegúrate de que el endpoint `/mobile/register` devuelva `device_id` como string

### Error de build en Android: "Kotlin version"

**Solución:**
```bash
# Actualizar Kotlin en android/settings.gradle
# Cambiar la versión a 2.1.0 o superior
```

O usar el flag:
```bash
flutter run --android-skip-build-dependency-validation
```

### QR Scanner no funciona en iOS

**Solución:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### App se cierra inmediatamente después de abrir

**Posibles causas:**
1. Firebase mal configurado
2. Permisos faltantes
3. Backend no disponible

**Ver logs:**
```bash
# Android
flutter logs

# O con adb
adb logcat | grep flutter
```

---

## 🧪 Testing

### Tests unitarios

```bash
# Ejecutar todos los tests
flutter test

# Ejecutar con cobertura
flutter test --coverage
```

### Tests de integración

```bash
# Ejecutar tests de integración
flutter test integration_test/

# En un dispositivo específico
flutter drive --target=integration_test/app_test.dart
```

### Análisis de código

```bash
# Análisis estático
flutter analyze

# Formatear código
dart format lib/
```

---

## 📚 Dependencias Principales

| Paquete | Versión | Descripción |
|---------|---------|-------------|
| `provider` | ^6.1.2 | Gestión de estado reactivo |
| `dio` | ^5.4.3+1 | Cliente HTTP con interceptores |
| `sqflite` | ^2.3.3+1 | Base de datos SQLite local |
| `firebase_core` | ^3.3.0 | Núcleo de Firebase |
| `firebase_messaging` | ^15.0.4 | Notificaciones push (FCM) |
| `qr_code_scanner` | ^1.0.1 | Escaneo de códigos QR |
| `qr_flutter` | ^4.1.0 | Generación de códigos QR |
| `device_info_plus` | ^10.1.0 | Información del dispositivo |
| `flutter_local_notifications` | ^18.0.1 | Notificaciones locales |
| `uuid` | ^4.4.0 | Generación de UUIDs |

Ver `pubspec.yaml` para la lista completa.

---

## 🔐 Seguridad

### Mejores prácticas implementadas:

- ✅ Tokens FCM actualizados automáticamente
- ✅ Identificadores de dispositivo únicos (UUID v4)
- ✅ Validación de datos antes de enviar al servidor
- ✅ Manejo seguro de errores sin exponer detalles internos
- ✅ Timeout en requests HTTP (30 segundos)

### Consideraciones para producción:

- 🔒 Implementar SSL pinning para mayor seguridad
- 🔒 Ofuscar el código con `--obfuscate`
- 🔒 Usar variables de entorno para URLs sensibles
- 🔒 Implementar autenticación de usuario (JWT)

---

## 🔐 Autenticación

La aplicación utiliza **Google Sign-In** como método único de autenticación, proporcionando:

- **Seguridad:** Autenticación OAuth 2.0 gestionada por Google
- **Simplicidad:** Un solo toque para iniciar sesión
- **Privacidad:** No se almacenan contraseñas en el dispositivo
- **Biometría:** Después del primer login, puedes usar huella digital o Face ID

### Flujo de autenticación:

1. Usuario presiona "Continuar con Google"
2. Se abre el selector de cuenta de Google
3. Usuario selecciona su cuenta
4. Se obtiene el token de Google y se envía al backend
5. Backend valida el token y devuelve un JWT
6. La sesión persiste en el dispositivo de forma segura
7. En siguientes inicios, puede usar biometría si está habilitada

## 🚀 Roadmap

Funcionalidades planificadas:

- [x] Autenticación con Google
- [x] Autenticación biométrica
- [ ] Chat en tiempo real con el negocio (WebSockets)
- [ ] Sistema de calificación del servicio
- [ ] Modo oscuro
- [ ] Soporte multi-idioma (i18n)
- [ ] Compartir órdenes con otros dispositivos
- [ ] Historial de órdenes completadas
- [ ] Wallet con cupones y descuentos
- [ ] Integración con Apple Wallet / Google Pay

---

## 📄 Licencia

© 2025 Order QR System. Todos los derechos reservados.

Este proyecto es de código privado. No está permitido el uso, copia o distribución sin autorización explícita.

---

## 👥 Contribuir

Si deseas contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -m 'Agregar nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

---

## 🆘 Soporte

¿Necesitas ayuda?

- 📧 **Email:** soporte@orderqr.com
- 🐛 **Reportar bug:** [Crear issue](https://github.com/tu-usuario/order_qr_mobile/issues)
- 💬 **Discusiones:** [GitHub Discussions](https://github.com/tu-usuario/order_qr_mobile/discussions)

---

## 📝 Changelog

### v1.0.0 (2025-11-14)
- ✨ Release inicial
- ✨ Escaneo de QR
- ✨ Notificaciones push
- ✨ Timeline de estados
- ✨ Modo offline

---

**Hecho con ❤️ usando Flutter**

**Versión actual:** 1.0.0
**Última actualización:** 2025-11-14
