# Configuración de Firebase para Order QR Mobile

## ✅ Estado Actual

Tu proyecto **YA ESTÁ CONFIGURADO** para Firebase. Estos elementos ya están en su lugar:

### Android
- ✅ `firebase_options.dart` generado con credenciales
- ✅ `google-services.json` en `android/app/`
- ✅ Plugin de Google Services en `android/build.gradle`
- ✅ Dependencias de Firebase en `android/app/build.gradle`
- ✅ Firebase Messaging Service en `AndroidManifest.xml`
- ✅ Permisos de notificaciones configurados

### iOS
- ✅ Configuración de Firebase en `firebase_options.dart`
- ⚠️ Necesitas agregar `GoogleService-Info.plist` (ver abajo)

### Flutter
- ✅ Dependencias instaladas (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`)
- ✅ Inicialización de Firebase en `main.dart`
- ✅ NotificationService implementado
- ✅ Background message handler configurado

## 🔧 Lo que NECESITAS Hacer Ahora

### 1. Configurar la Clave del Servidor en el Backend Laravel

Tu backend Laravel necesita la **Server Key** de Firebase para enviar notificaciones push.

#### Pasos:

1. **Ve a Firebase Console**
   - Abre https://console.firebase.google.com/
   - Selecciona tu proyecto: `focus-qr`

2. **Obtener la Server Key (Legacy)**
   - En la barra lateral, haz clic en el ícono de engranaje ⚙️
   - Selecciona "Project Settings" (Configuración del proyecto)
   - Ve a la pestaña "Cloud Messaging"
   - Busca "Cloud Messaging API (Legacy)"
   - **IMPORTANTE**: Si dice "Disabled", necesitas habilitarlo:
     - Haz clic en el menú de 3 puntos (⋮)
     - Selecciona "Manage API in Google Cloud Console"
     - Habilita "Firebase Cloud Messaging API"
   - Copia la **Server Key** (una clave larga que empieza con `AAAA...`)

3. **Configurar en Laravel**

   En tu archivo `.env` del backend:
   ```env
   FIREBASE_SERVER_KEY=AAAA... (tu clave del paso anterior)
   ```

   En `config/services.php`:
   ```php
   'fcm' => [
       'server_key' => env('FIREBASE_SERVER_KEY'),
   ],
   ```

4. **Reiniciar el servidor Laravel**
   ```bash
   php artisan config:cache
   ```

### 2. Configurar iOS (Si vas a usar iOS)

Si planeas compilar para iOS, necesitas:

1. **Descargar GoogleService-Info.plist**
   - En Firebase Console → Project Settings
   - Pestaña "General"
   - En la sección de apps, encuentra tu app iOS
   - Descarga `GoogleService-Info.plist`

2. **Agregar al proyecto**
   - Copia `GoogleService-Info.plist` a `ios/Runner/`
   - Abre el proyecto en Xcode: `open ios/Runner.xcworkspace`
   - Arrastra `GoogleService-Info.plist` al proyecto Runner en Xcode
   - Asegúrate de marcar "Copy items if needed"

3. **Actualizar AppDelegate.swift**

   El archivo `ios/Runner/AppDelegate.swift` debería verse así:
   ```swift
   import UIKit
   import Flutter
   import Firebase
   import FirebaseMessaging

   @UIApplicationMain
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       FirebaseApp.configure()

       if #available(iOS 10.0, *) {
         UNUserNotificationCenter.current().delegate = self
       }

       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

4. **Configurar capacidades en Xcode**
   - En Xcode, selecciona el proyecto Runner
   - Ve a "Signing & Capabilities"
   - Agrega las capacidades:
     - Push Notifications
     - Background Modes (marca "Remote notifications")

### 3. Probar las Notificaciones

#### Opción 1: Desde Firebase Console (Rápido)

1. Ve a Firebase Console → Cloud Messaging
2. Haz clic en "Send your first message"
3. Escribe un mensaje de prueba
4. Selecciona tu app
5. Envía la notificación

#### Opción 2: Desde tu Backend Laravel (Producción)

1. Asegúrate de que el backend tenga la Server Key configurada
2. El dispositivo móvil debe enviar su FCM token al backend:
   - Esto ya está implementado en `NotificationService.initialize()`
   - El token se envía automáticamente a `/api/v1/mobile/update-token`

3. Cuando el negocio envíe un mensaje desde el panel web:
   - El backend enviará una notificación push automáticamente
   - El tipo será `'new_message'`
   - La app abrirá el chat automáticamente

## 📋 Verificación del Sistema

### Checklist de Funcionalidad

Verifica que todo funcione:

- [ ] **Registro de dispositivo**: Al abrir la app por primera vez, se registra el dispositivo
- [ ] **Token FCM**: Se envía el token FCM al backend
- [ ] **Actualización de token**: Si el token cambia, se actualiza automáticamente
- [ ] **Notificaciones en foreground**: Recibes notificaciones cuando la app está abierta
- [ ] **Notificaciones en background**: Recibes notificaciones cuando la app está cerrada
- [ ] **Navegación**: Al tocar una notificación, abre la pantalla correcta (chat, orden, etc.)
- [ ] **Badge de mensajes**: El contador de mensajes no leídos se actualiza

### Comandos para Testing

```bash
# Ver logs en Android
flutter run
# o
adb logcat | grep -i firebase

# Ver logs en iOS
flutter run
# Luego en Xcode: Window → Devices and Simulators → Ver logs
```

## 🔍 Troubleshooting

### Problema: No llegan notificaciones

**Soluciones:**
1. Verifica que la Server Key esté configurada en Laravel
2. Revisa los logs del backend Laravel: `storage/logs/laravel.log`
3. Verifica que el token FCM se esté enviando correctamente
4. En Firebase Console, ve a Cloud Messaging → envía una notificación de prueba

### Problema: Token FCM es null

**Soluciones:**
1. Asegúrate de que `google-services.json` esté en `android/app/`
2. Ejecuta `flutter clean && flutter pub get`
3. Reconstruye la app: `flutter run`
4. Verifica los logs: debe aparecer "📱 FCM Token: ..."

### Problema: La app crashea al recibir notificación

**Soluciones:**
1. Verifica que el formato del payload sea correcto
2. El payload debe incluir:
   ```json
   {
     "type": "new_message",
     "order_id": "123"
   }
   ```
3. Revisa los logs de Dart/Flutter para ver el error exacto

## 📱 Estructura del Payload para Notificaciones

### Para Mensajes de Chat

Desde el backend Laravel, envía:

```json
{
  "notification": {
    "title": "Nuevo mensaje",
    "body": "Mensaje del negocio..."
  },
  "data": {
    "type": "new_message",
    "order_id": "123",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "priority": "high",
  "android": {
    "notification": {
      "channel_id": "order_updates",
      "sound": "default"
    }
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "default",
        "badge": 1
      }
    }
  }
}
```

### Otros Tipos de Notificaciones Soportadas

- `order_status_change`: Cuando cambia el estado de la orden
- `order_associated`: Cuando se asocia una orden
- `order_reminder`: Recordatorio de orden pendiente
- `order_cancelled`: Cuando se cancela una orden

## 🚀 Siguientes Pasos

1. **Configurar la Server Key en Laravel** (CRÍTICO)
2. Probar envío de notificaciones desde Firebase Console
3. Probar envío de mensajes desde el panel web
4. Verificar navegación automática al chat
5. (Opcional) Configurar iOS si es necesario

## 📚 Recursos Adicionales

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Laravel FCM Integration](https://github.com/brozot/Laravel-FCM)

---

**Tu proyecto ya está 90% configurado**. Solo necesitas agregar la Server Key en el backend y ¡estás listo! 🎉
