# Order QR System - Mobile App (Flutter)

Aplicación móvil Flutter para el sistema de gestión de órdenes con códigos QR.

## 📱 Características

- ✅ Escaneo de códigos QR para asociar órdenes
- ✅ Visualización de órdenes en tiempo real
- ✅ Notificaciones push cuando la orden está lista
- ✅ Timeline de estados de la orden
- ✅ Código QR para recolección
- ✅ Modo offline con base de datos local
- ✅ Diseño coherente con Volt Dashboard

## 🚀 Requisitos Previos

- Flutter SDK 3.0.0 o superior
- Dart SDK 2.19 o superior
- Android Studio / Xcode (para desarrollo móvil)
- Firebase project (para notificaciones push)

## 📦 Instalación

### 1. Clonar el repositorio

```bash
cd order_qr_mobile
```

### 2. Instalar dependencias

```bash
flutter pub get
```

### 3. Configurar Firebase

#### Opción 1: Usando FlutterFire CLI (Recomendado)

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar Firebase
flutterfire configure
```

#### Opción 2: Manual

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Agregar apps Android e iOS
3. Descargar archivos de configuración:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### 4. Configurar la URL del API

Editar `lib/config/api_config.dart`:

```dart
static const String baseUrl = 'https://tu-servidor.com/api/v1';
```

### 5. Ejecutar la app

```bash
# Android
flutter run

# iOS
flutter run

# Web (no soporta todas las funcionalidades)
flutter run -d chrome
```

## 🏗️ Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada
├── config/                   # Configuraciones
│   ├── api_config.dart
│   ├── firebase_config.dart
│   └── theme.dart
├── models/                   # Modelos de datos
│   ├── order.dart
│   ├── business.dart
│   └── mobile_user.dart
├── services/                 # Servicios
│   ├── api_service.dart
│   ├── notification_service.dart
│   ├── database_service.dart
│   └── qr_service.dart
├── providers/                # Gestión de estado
│   ├── orders_provider.dart
│   └── device_provider.dart
├── screens/                  # Pantallas
│   ├── splash_screen.dart
│   ├── home_screen.dart
│   ├── scan_qr_screen.dart
│   ├── order_detail_screen.dart
│   └── settings_screen.dart
├── widgets/                  # Widgets reutilizables
│   ├── volt_card.dart
│   ├── volt_button.dart
│   ├── volt_badge.dart
│   ├── order_card.dart
│   ├── order_timeline.dart
│   └── qr_display.dart
└── utils/                    # Utilidades
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

## 🔧 Configuración de Android

### Permisos necesarios

Editar `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### Versión mínima

Editar `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 24  // Android 7.0
        targetSdkVersion 33
    }
}
```

## 🍎 Configuración de iOS

### Permisos necesarios

Editar `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para escanear códigos QR</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Necesitamos acceso a la galería</string>
```

### Versión mínima

Editar `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

## 🔔 Configurar Notificaciones Push

### Android

1. Agregar `google-services.json` en `android/app/`
2. Las notificaciones ya están configuradas en el código

### iOS

1. Agregar `GoogleService-Info.plist` en `ios/Runner/`
2. Habilitar Push Notifications en Xcode
3. Subir certificado APNs a Firebase Console

## 🧪 Testing

```bash
# Ejecutar tests unitarios
flutter test

# Ejecutar tests de integración
flutter test integration_test/

# Análisis de código
flutter analyze
```

## 📱 Build para Producción

### Android (APK)

```bash
flutter build apk --release
```

### Android (AAB - Google Play)

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

Luego abrir en Xcode para archivar y subir a App Store.

## 🎨 Personalización del Tema

Editar `lib/config/theme.dart` para cambiar colores, fuentes y estilos.

## 🐛 Troubleshooting

### Error: "Failed to load Firebase"

- Verificar que los archivos de configuración estén en las carpetas correctas
- Ejecutar `flutterfire configure` nuevamente

### Error: "Camera permission denied"

- Verificar permisos en AndroidManifest.xml e Info.plist
- Reinstalar la app después de agregar permisos

### Error: "API connection failed"

- Verificar la URL en `api_config.dart`
- Verificar que el servidor esté corriendo
- Verificar conexión a internet

### Error de QR Scanner en iOS

```bash
cd ios
pod install
cd ..
flutter clean
flutter run
```

## 📚 Dependencias Principales

- `provider` - Gestión de estado
- `dio` - Cliente HTTP
- `sqflite` - Base de datos local
- `firebase_messaging` - Notificaciones push
- `qr_code_scanner` - Escaneo de QR
- `qr_flutter` - Generación de QR
- `device_info_plus` - Información del dispositivo

## 🔄 Actualizaciones Futuras

- [ ] Chat en tiempo real (WebSockets)
- [ ] Calificación del servicio
- [ ] Modo oscuro
- [ ] Multi-idioma (i18n)
- [ ] Compartir órdenes
- [ ] Historial extendido

## 📄 Licencia

© 2025 Order QR System. Todos los derechos reservados.

## 👥 Soporte

Para reportar bugs o solicitar features, crear un issue en el repositorio.

---

**Versión:** 1.0.0
**Última actualización:** 2025-11-05
