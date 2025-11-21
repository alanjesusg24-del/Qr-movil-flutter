# Instrucciones para Implementar Chat en la App Móvil Flutter

## 📋 Resumen General

Este documento te guiará paso a paso para implementar el sistema de chat en la aplicación móvil Flutter que permite a los clientes comunicarse con los negocios sobre sus órdenes.

## 🎯 Características Implementadas en Laravel

### Backend Completado ✅
1. **Base de datos**: Tabla `chat_messages` para almacenar mensajes
2. **API Endpoints**: Rutas completas para enviar/recibir mensajes
3. **Notificaciones Push**: Sistema FCM integrado para notificar nuevos mensajes
4. **Vista Web**: Panel de chat funcional para negocios

### Lo que Necesitas Implementar en Flutter
1. Ícono de chat en la lista de órdenes
2. Pantalla de chat individual por orden
3. Envío y recepción de mensajes
4. Notificaciones push cuando llegan mensajes nuevos

---

## 🔧 Paso 1: Configurar Firebase Cloud Messaging (FCM)

### 1.1 Agregar Dependencias

En tu `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

Ejecuta:
```bash
flutter pub get
```

### 1.2 Configurar Firebase

**Android** (`android/app/build.gradle`):
```gradle
apply plugin: 'com.google.gms.google-services'

dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-messaging'
}
```

**Android** (`android/build.gradle`):
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## 📱 Paso 2: Actualizar el Modelo de Order

### 2.1 Modificar `Order` Model

Agrega campos para el chat:

```dart
class Order {
  final int orderId;
  final String folioNumber;
  final String pickupToken;
  final String? description;
  final String status;
  final DateTime createdAt;
  final Business business;
  final int unreadMessagesCount;  // NUEVO
  final bool hasUnreadMessages;    // NUEVO

  Order({
    required this.orderId,
    required this.folioNumber,
    required this.pickupToken,
    this.description,
    required this.status,
    required this.createdAt,
    required this.business,
    this.unreadMessagesCount = 0,     // NUEVO
    this.hasUnreadMessages = false,    // NUEVO
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      folioNumber: json['folio_number'],
      pickupToken: json['pickup_token'],
      description: json['description'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      business: Business.fromJson(json['business']),
      unreadMessagesCount: json['unread_messages_count'] ?? 0,  // NUEVO
      hasUnreadMessages: json['has_unread_messages'] ?? false,  // NUEVO
    );
  }
}
```

---

## 💬 Paso 3: Crear el Modelo de ChatMessage

### 3.1 Crear `models/chat_message.dart`

```dart
class ChatMessage {
  final int messageId;
  final String senderType; // 'business' o 'customer'
  final String message;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.messageId,
    required this.senderType,
    required this.message,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'],
      senderType: json['sender_type'],
      message: json['message'],
      attachmentUrl: json['attachment_url'],
      isRead: json['is_read'],
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  bool get isFromBusiness => senderType == 'business';
  bool get isFromCustomer => senderType == 'customer';
}
```

---

## 🌐 Paso 4: Crear el Servicio de Chat

### 4.1 Crear `services/chat_service.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../config/api_config.dart';

class ChatService {
  final String baseUrl = ApiConfig.baseUrl; // Tu URL base del API

  // Obtener mensajes de una orden
  Future<List<ChatMessage>> getMessages(int orderId, String deviceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/mobile/orders/$orderId/messages'),
      headers: {
        'X-Device-ID': deviceId,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success']) {
        return (data['data']['messages'] as List)
            .map((msg) => ChatMessage.fromJson(msg))
            .toList();
      }
    }

    throw Exception('Error al cargar mensajes');
  }

  // Enviar mensaje
  Future<ChatMessage> sendMessage({
    required int orderId,
    required String deviceId,
    required String message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/mobile/orders/$orderId/messages'),
      headers: {
        'X-Device-ID': deviceId,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'message': message}),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      if (data['success']) {
        return ChatMessage.fromJson(data['data']);
      }
    }

    throw Exception('Error al enviar mensaje');
  }

  // Marcar mensajes como leídos
  Future<void> markAsRead(int orderId, String deviceId) async {
    await http.put(
      Uri.parse('$baseUrl/api/v1/mobile/orders/$orderId/messages/mark-read'),
      headers: {
        'X-Device-ID': deviceId,
        'Accept': 'application/json',
      },
    );
  }
}
```

---

## 🎨 Paso 5: Modificar la Lista de Órdenes

### 5.1 Actualizar `OrderListScreen` para Mostrar Ícono de Chat

```dart
class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Orden #${order.folioNumber}'),
        subtitle: Text(order.business.businessName),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // NUEVO: Ícono de chat con badge de mensajes no leídos
            if (order.hasUnreadMessages)
              Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.chat_bubble, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(order: order),
                        ),
                      );
                    },
                  ),
                  if (order.unreadMessagesCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${order.unreadMessagesCount}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )
            else
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.grey),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(order: order),
                    ),
                  );
                },
              ),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          // Navegar a detalles de la orden
        },
      ),
    );
  }
}
```

---

## 💬 Paso 6: Crear la Pantalla de Chat

### 6.1 Crear `screens/chat_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  final Order order;

  const ChatScreen({Key? key, required this.order}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final StorageService _storageService = StorageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  Timer? _pollingTimer;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    _deviceId = await _storageService.getDeviceId();
    await _loadMessages();
    await _chatService.markAsRead(widget.order.orderId, _deviceId!);

    // Polling cada 3 segundos para nuevos mensajes
    _pollingTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      _loadMessages(showLoading: false);
    });
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => _isLoading = true);
    }

    try {
      final messages = await _chatService.getMessages(
        widget.order.orderId,
        _deviceId!,
      );

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (showLoading) {
        setState(() => _isLoading = false);
      }
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _chatService.sendMessage(
        orderId: widget.order.orderId,
        deviceId: _deviceId!,
        message: text,
      );

      _messageController.clear();
      await _loadMessages(showLoading: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar mensaje')),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat - Orden #${widget.order.folioNumber}'),
            Text(
              widget.order.business.businessName,
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(child: Text('No hay mensajes'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Input de mensaje
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromCustomer = message.isFromCustomer;

    return Align(
      alignment: isFromCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isFromCustomer ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isFromCustomer ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isFromCustomer
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
```

---

## 🔔 Paso 7: Configurar Notificaciones Push

### 7.1 Crear `services/firebase_service.dart`

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './storage_service.dart';
import './api_service.dart';

class FirebaseService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StorageService _storageService = StorageService();
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    // Solicitar permisos
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configurar notificaciones locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);

    // Obtener FCM token
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _updateTokenOnServer(token);
    }

    // Escuchar cuando el token cambie
    _firebaseMessaging.onTokenRefresh.listen(_updateTokenOnServer);

    // Manejar mensajes en primer plano
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Manejar cuando se toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  Future<void> _updateTokenOnServer(String token) async {
    final deviceId = await _storageService.getDeviceId();
    if (deviceId != null) {
      await _apiService.updateFcmToken(deviceId, token);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Nuevo mensaje',
        body: notification.body ?? '',
        payload: data['order_id'],
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    // Navegar a la pantalla de chat de la orden
    final orderId = message.data['order_id'];
    if (orderId != null) {
      // Implementar navegación usando NavigatorKey
      print('Navigate to chat for order: $orderId');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Chat Notifications',
      channelDescription: 'Notificaciones de mensajes de chat',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
```

### 7.2 Inicializar en `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import './services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp();

  // Inicializar servicio de notificaciones
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  runApp(MyApp());
}
```

---

## ✅ Resumen de Endpoints de API

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/v1/mobile/orders/{orderId}/messages` | Obtener mensajes de una orden |
| POST | `/api/v1/mobile/orders/{orderId}/messages` | Enviar mensaje desde la app |
| PUT | `/api/v1/mobile/orders/{orderId}/messages/mark-read` | Marcar mensajes como leídos |

**Headers Requeridos:**
- `X-Device-ID`: UUID del dispositivo
- `Content-Type`: `application/json`
- `Accept`: `application/json`

---

## 🎯 Checklist de Implementación

- [ ] Agregar dependencias de Firebase y HTTP
- [ ] Configurar Firebase en Android e iOS
- [ ] Actualizar modelo `Order` con campos de chat
- [ ] Crear modelo `ChatMessage`
- [ ] Crear `ChatService` para comunicación con API
- [ ] Modificar lista de órdenes para mostrar ícono de chat
- [ ] Crear pantalla `ChatScreen`
- [ ] Implementar servicio de notificaciones push
- [ ] Probar envío y recepción de mensajes
- [ ] Probar notificaciones push

---

## 🐛 Troubleshooting

### Error: "Device ID not found"
- Asegúrate de que el dispositivo esté registrado con el endpoint `/api/v1/mobile/register`

### No llegan notificaciones push
- Verifica que FCM esté configurado correctamente
- Revisa que el token FCM se esté actualizando en el servidor
- Asegúrate de que las credenciales de Firebase estén en el servidor Laravel

### Mensajes no se actualizan
- Verifica que el polling esté activo
- Revisa los logs de la consola para errores de API

---

## 📞 Soporte

Si tienes problemas, revisa:
1. Los logs del servidor Laravel en `storage/logs/laravel.log`
2. Los logs de Flutter en la consola
3. Las respuestas de la API en las DevTools del navegador

**¡Éxito con la implementación!** 🚀
