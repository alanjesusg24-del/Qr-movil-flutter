import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../config/firebase_config.dart';
import '../providers/orders_provider.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._privateConstructor();
  NotificationService._privateConstructor();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Callback para navegación
  Function(Map<String, dynamic> data)? onNotificationNavigate;

  /// Inicializar el servicio de notificaciones
  Future<void> initialize() async {
    // Solicitar permisos
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificación concedidos');

      // Configurar notificaciones locales
      await _initializeLocalNotifications();

      // Obtener y enviar token al backend
      String? token = await _fcm.getToken();
      if (token != null) {
        print('📱 FCM Token: $token');
        try {
          await ApiService.updateFcmToken(token);
        } catch (e) {
          print('❌ Error al actualizar FCM token: $e');
        }
      }

      // Escuchar cambios de token
      _fcm.onTokenRefresh.listen((newToken) async {
        print('🔄 Token actualizado: $newToken');
        try {
          await ApiService.updateFcmToken(newToken);
        } catch (e) {
          print('❌ Error al actualizar token: $e');
        }
      });
    } else {
      print('⚠️ Permisos de notificación denegados');
    }
  }

  /// Inicializar notificaciones locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      FirebaseConfig.orderUpdatesChannelId,
      FirebaseConfig.orderUpdatesChannelName,
      description: FirebaseConfig.orderUpdatesChannelDescription,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Manejo cuando se toca una notificación local
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notificación tocada: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _handleNotificationNavigation(data);
      } catch (e) {
        print('❌ Error al parsear payload: $e');
      }
    }
  }

  /// Configurar listeners de notificaciones
  Future<void> setupNotificationListeners(BuildContext context) async {
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
      if (context.mounted) {
        _handleOrderUpdate(context, message.data);
      }
    });

    // Cuando la app se abre desde una notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App abierta desde notificación (background)');
      print('   Data: ${message.data}');

      _handleNotificationNavigation(message.data);
      if (context.mounted) {
        _handleOrderUpdate(context, message.data);
      }
    });

    // Verificar si la app se abrió desde una notificación (app terminated)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('📱 App abierta desde notificación (terminated)');
      print('   Data: ${initialMessage.data}');

      // Esperar a que la app esté completamente inicializada
      Future.delayed(const Duration(seconds: 1), () {
        _handleNotificationNavigation(initialMessage.data);
        if (context.mounted) {
          _handleOrderUpdate(context, initialMessage.data);
        }
      });
    }
  }

  /// Navegar según el tipo de notificación
  void _handleNotificationNavigation(Map<String, dynamic> data) {
    if (onNotificationNavigate != null) {
      onNotificationNavigate!(data);
    }
  }

  /// Actualizar órdenes cuando llega una notificación
  void _handleOrderUpdate(BuildContext context, Map<String, dynamic> data) {
    try {
      final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
      final type = data['type'] as String?;
      final orderId = int.tryParse(data['order_id']?.toString() ?? '');

      print('🔄 Actualizando órdenes por notificación tipo: $type');

      switch (type) {
        case 'order_status_change':
        case 'order_associated':
          if (orderId != null) {
            // Actualizar la orden específica
            ordersProvider.refreshOrder(orderId);
            print('   → Orden $orderId actualizada');
          }
          break;

        case 'order_cancelled':
          // Recargar todas las órdenes
          ordersProvider.fetchOrders();
          print('   → Todas las órdenes recargadas');
          break;

        case 'order_reminder':
          // Recargar órdenes pendientes
          ordersProvider.fetchOrders();
          print('   → Órdenes recargadas (recordatorio)');
          break;

        case 'new_message':
          // Actualizar la orden para reflejar nuevos mensajes
          if (orderId != null) {
            ordersProvider.refreshOrder(orderId);
            print('   → Orden $orderId actualizada (nuevo mensaje)');
          }
          break;

        default:
          print('   ⚠️ Tipo de notificación desconocido: $type');
      }
    } catch (e) {
      print('❌ Error al actualizar órdenes: $e');
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      FirebaseConfig.orderUpdatesChannelId,
      FirebaseConfig.orderUpdatesChannelName,
      channelDescription: FirebaseConfig.orderUpdatesChannelDescription,
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

    // Usar order_id como ID de notificación o generar uno único
    final notificationId = int.tryParse(data['order_id']?.toString() ?? '') ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: json.encode(data),
    );
  }

  /// Obtener token FCM actual
  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  /// Eliminar token FCM
  Future<void> deleteToken() async {
    await _fcm.deleteToken();
  }
}

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Mensaje recibido en background: ${message.notification?.title}');
  print('   Data: ${message.data}');
}
