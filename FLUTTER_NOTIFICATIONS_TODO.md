# 🔔 Implementación de Notificaciones Push - TODO

## 📋 Estado Actual

✅ **Firebase Cloud Messaging (FCM) está configurado**
- El token FCM se genera correctamente
- Token actual: `eeNbEyYCQqCzZVfTL9j8zn:APA91bGVDsQD91sKUmdDTrCCNwbriollnuoLpk1qpzixXAZOqX3BuL1N5_0mFUdjYk6p1IHw-24hyCuBcy8y6WQcyKIvDLR162T6Dl0aIFDO2hPg2IayRFY`
- El servicio de background está funcionando
- Los permisos de notificación están concedidos

❌ **Lo que falta implementar:**
- Manejo de notificaciones en foreground
- Manejo de notificaciones en background
- Navegación cuando se toca una notificación
- Actualización automática de las órdenes cuando llega una notificación
- Sonido y vibración personalizada

---

## 🎯 Objetivos

### 1. **Notificaciones cuando una orden cambia de estado**
   - `pending` → `ready`: "¡Tu orden está lista para recoger!"
   - `ready` → `delivered`: "Orden entregada exitosamente"
   - Cualquier cambio: Actualizar la lista de órdenes automáticamente

### 2. **Comportamiento según el estado de la app**
   - **Foreground (app abierta)**: Mostrar notificación in-app + actualizar UI
   - **Background (app minimizada)**: Mostrar notificación del sistema
   - **Terminated (app cerrada)**: Mostrar notificación y abrir la app al tocarla

### 3. **Navegación inteligente**
   - Si el usuario toca la notificación, abrir directamente el detalle de la orden
   - Si está en otra pantalla, navegar automáticamente

---

## 📡 Estructura de Notificación del Backend

El backend Laravel enviará notificaciones con esta estructura:

```json
{
  "to": "FCM_TOKEN_DEL_DISPOSITIVO",
  "notification": {
    "title": "¡Tu orden está lista!",
    "body": "La orden ORD-2025-001 está lista para recoger",
    "sound": "default"
  },
  "data": {
    "type": "order_status_change",
    "order_id": "2",
    "order_number": "ORD-2025-001",
    "old_status": "pending",
    "new_status": "ready",
    "folio_number": "TEST-001",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  },
  "priority": "high"
}
```

### Tipos de notificaciones:
- `order_status_change`: Cambio de estado de orden
- `order_associated`: Nueva orden asociada al dispositivo
- `order_cancelled`: Orden cancelada
- `order_reminder`: Recordatorio de orden pendiente

---

## 🛠️ Implementación Paso a Paso

### **Paso 1: Actualizar `notification_service.dart`**

Archivo: `lib/services/notification_service.dart`

#### 1.1. Agregar manejo de notificaciones en foreground

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ... código existente ...

  /// Inicializar notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificación para Android
    const androidChannel = AndroidNotificationChannel(
      'order_updates', // id
      'Actualizaciones de Órdenes', // nombre
      description: 'Notificaciones sobre cambios en tus órdenes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// Manejo cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notificación tocada: ${response.payload}');

    if (response.payload != null) {
      final data = json.decode(response.payload!);
      _handleNotificationNavigation(data);
    }
  }

  /// Navegar según el tipo de notificación
  static void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'order_status_change':
      case 'order_associated':
        final orderId = int.tryParse(data['order_id'].toString());
        if (orderId != null) {
          // Navegar a la pantalla de detalle de orden
          navigatorKey.currentState?.pushNamed(
            '/order-detail',
            arguments: {'orderId': orderId},
          );
        }
        break;

      case 'order_reminder':
        // Navegar a la pantalla de órdenes pendientes
        navigatorKey.currentState?.pushNamed('/home');
        break;
    }
  }

  /// Mostrar notificación local
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'order_updates',
      'Actualizaciones de Órdenes',
      channelDescription: 'Notificaciones sobre cambios en tus órdenes',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      data['order_id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: json.encode(data),
    );
  }
}
```

#### 1.2. Agregar listener para notificaciones en foreground

```dart
/// Configurar listeners de notificaciones
static Future<void> setupNotificationListeners(BuildContext context) async {
  // Notificaciones cuando la app está en foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('📩 Notificación recibida en foreground');
    print('   Título: ${message.notification?.title}');
    print('   Cuerpo: ${message.notification?.body}');
    print('   Data: ${message.data}');

    // Mostrar notificación local
    if (message.notification != null) {
      await _showLocalNotification(
        title: message.notification!.title ?? 'Nueva notificación',
        body: message.notification!.body ?? '',
        data: message.data,
      );
    }

    // Actualizar las órdenes en el provider
    _handleOrderUpdate(context, message.data);
  });

  // Cuando la app se abre desde una notificación (app en background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('📱 App abierta desde notificación (background)');
    print('   Data: ${message.data}');

    _handleNotificationNavigation(message.data);
    _handleOrderUpdate(context, message.data);
  });

  // Verificar si la app se abrió desde una notificación (app terminated)
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('📱 App abierta desde notificación (terminated)');
    print('   Data: ${initialMessage.data}');

    // Esperar a que la app esté completamente inicializada
    Future.delayed(Duration(seconds: 1), () {
      _handleNotificationNavigation(initialMessage.data);
      _handleOrderUpdate(context, initialMessage.data);
    });
  }
}

/// Actualizar órdenes cuando llega una notificación
static void _handleOrderUpdate(BuildContext context, Map<String, dynamic> data) {
  final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
  final type = data['type'] as String?;
  final orderId = int.tryParse(data['order_id']?.toString() ?? '');

  switch (type) {
    case 'order_status_change':
    case 'order_associated':
      if (orderId != null) {
        // Actualizar la orden específica
        ordersProvider.refreshOrder(orderId);
      }
      break;

    case 'order_cancelled':
      // Recargar todas las órdenes
      ordersProvider.fetchOrders();
      break;
  }
}
```

---

### **Paso 2: Configurar navegación global**

Archivo: `lib/main.dart`

```dart
import 'package:flutter/material.dart';

// Crear una GlobalKey para el navegador
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order QR Mobile',
      navigatorKey: navigatorKey, // ← Agregar esta línea
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/home': (context) => HomeScreen(),
        '/order-detail': (context) => OrderDetailScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
```

---

### **Paso 3: Inicializar listeners en la app**

Archivo: `lib/screens/home_screen.dart`

```dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Inicializar listeners de notificaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.setupNotificationListeners(context);
    });

    _refreshOrders();
  }

  // ... resto del código ...
}
```

---

### **Paso 4: Agregar dependencia de notificaciones locales**

Archivo: `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Existentes
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5

  # ← AGREGAR ESTA LÍNEA
  flutter_local_notifications: ^18.0.1
```

Después de agregar, ejecutar:
```bash
flutter pub get
```

---

### **Paso 5: Configurar permisos adicionales (Android)**

Archivo: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Permisos existentes -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- ← AGREGAR ESTOS PERMISOS -->
    <uses-permission android:name="android.permission.VIBRATE" />
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application
        android:label="Order QR"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- Activity existente -->
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme">
            <!-- ... -->
        </activity>

        <!-- ← AGREGAR ESTE RECEIVER -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
            </intent-filter>
        </receiver>

        <!-- ← AGREGAR ESTE RECEIVER -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
    </application>
</manifest>
```

---

## 🧪 Cómo Probar

### **Opción 1: Usando el backend Laravel**

1. Asegúrate de que el backend tenga el token FCM guardado
2. Cambia el estado de una orden desde el backend
3. El backend debería enviar automáticamente la notificación

### **Opción 2: Enviar notificación manualmente desde Firebase Console**

1. Ir a: https://console.firebase.google.com/
2. Seleccionar el proyecto
3. Ir a **Cloud Messaging** → **Send your first message**
4. Llenar:
   - **Título**: "¡Tu orden está lista!"
   - **Texto**: "La orden ORD-2025-001 está lista para recoger"
5. **Next** → **Seleccionar la app** → **Next**
6. En **Additional options** → **Custom data**, agregar:
   ```
   type: order_status_change
   order_id: 2
   order_number: ORD-2025-001
   old_status: pending
   new_status: ready
   ```
7. **Review** → **Publish**

### **Opción 3: Usando cURL (recomendado para testing)**

Crear un archivo `test_notification.sh`:

```bash
#!/bin/bash

# Token FCM del dispositivo
FCM_TOKEN="eeNbEyYCQqCzZVfTL9j8zn:APA91bGVDsQD91sKUmdDTrCCNwbriollnuoLpk1qpzixXAZOqX3BuL1N5_0mFUdjYk6p1IHw-24hyCuBcy8y6WQcyKIvDLR162T6Dl0aIFDO2hPg2IayRFY"

# Server Key de Firebase (obtener de Firebase Console > Project Settings > Cloud Messaging)
SERVER_KEY="TU_SERVER_KEY_AQUI"

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=$SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"to\": \"$FCM_TOKEN\",
    \"notification\": {
      \"title\": \"¡Tu orden está lista!\",
      \"body\": \"La orden ORD-2025-001 está lista para recoger\",
      \"sound\": \"default\"
    },
    \"data\": {
      \"type\": \"order_status_change\",
      \"order_id\": \"2\",
      \"order_number\": \"ORD-2025-001\",
      \"old_status\": \"pending\",
      \"new_status\": \"ready\",
      \"folio_number\": \"TEST-001\"
    },
    \"priority\": \"high\"
  }"
```

---

## 🔍 Debugging

### Ver logs de notificaciones:

```bash
# Android
flutter run -d <device-id>

# En la consola aparecerán:
# 📩 Notificación recibida en foreground
# 📱 App abierta desde notificación
```

### Verificar permisos:

```dart
final status = await FirebaseMessaging.instance.getNotificationSettings();
print('Permisos: ${status.authorizationStatus}');
```

---

## 📚 Referencias

- [Firebase Cloud Messaging - Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Testing FCM](https://firebase.google.com/docs/cloud-messaging/flutter/first-message)

---

## ✅ Checklist de Implementación

### Backend (Laravel)
- [ ] Verificar que `mobile_users` tenga la columna `fcm_token`
- [ ] Implementar método para enviar notificaciones FCM
- [ ] Enviar notificación cuando cambia el estado de una orden
- [ ] Enviar notificación cuando se asocia una orden
- [ ] Probar con token de prueba

### Frontend (Flutter)
- [ ] Agregar `flutter_local_notifications` a `pubspec.yaml`
- [ ] Actualizar `notification_service.dart` con los listeners
- [ ] Configurar `navigatorKey` en `main.dart`
- [ ] Agregar permisos en `AndroidManifest.xml`
- [ ] Inicializar listeners en `home_screen.dart`
- [ ] Probar notificaciones en foreground
- [ ] Probar notificaciones en background
- [ ] Probar notificaciones con app cerrada
- [ ] Verificar navegación al tocar notificación
- [ ] Verificar actualización automática de órdenes

---

## 🐛 Problemas Comunes

### 1. **Notificaciones no llegan**
- Verificar que el token FCM esté actualizado en el backend
- Verificar permisos de notificación
- Revisar logs de Firebase Console

### 2. **App no navega al tocar notificación**
- Verificar que `navigatorKey` esté configurado
- Revisar el payload de la notificación
- Verificar que las rutas existan en `main.dart`

### 3. **Notificaciones no se muestran en foreground**
- Verificar que `flutter_local_notifications` esté instalado
- Verificar que el canal de Android esté creado
- Revisar permisos de notificación

---

**Creado:** 2025-11-06
**Para implementar:** Mañana o más tarde
**Prioridad:** Media
**Tiempo estimado:** 1-2 horas
