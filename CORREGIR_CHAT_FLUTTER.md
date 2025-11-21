# Corrección: Chat en Flutter No Muestra Mensajes ni Envía

## Problema Identificado

✅ **Backend Laravel**: Enviando notificaciones correctamente
✅ **Backend Laravel**: Guardando mensajes en base de datos
❌ **App Flutter**: NO muestra mensajes existentes
❌ **App Flutter**: Marca error al intentar enviar mensajes

## Endpoints del Backend (Para Referencia)

### 1. Obtener Mensajes de una Orden
```
GET /api/v1/mobile/orders/{orderId}/messages
Headers:
  - X-Device-ID: {device_id}
  - Accept: application/json

Response:
{
  "success": true,
  "data": {
    "order_id": 123,
    "folio_number": "ORD-001",
    "messages": [
      {
        "message_id": 1,
        "sender_type": "business" | "customer",
        "message": "Hola, tu orden está lista",
        "attachment_url": null,
        "is_read": false,
        "created_at": "2025-11-20T10:30:00.000000Z",
        "read_at": null
      }
    ],
    "total_messages": 5
  }
}
```

### 2. Enviar Mensaje desde la App
```
POST /api/v1/mobile/orders/{orderId}/messages
Headers:
  - X-Device-ID: {device_id}
  - Content-Type: application/json
  - Accept: application/json

Body:
{
  "message": "Gracias, voy en camino"
}

Response:
{
  "success": true,
  "message": "Mensaje enviado exitosamente",
  "data": {
    "message_id": 2,
    "sender_type": "customer",
    "message": "Gracias, voy en camino",
    "attachment_url": null,
    "created_at": "2025-11-20T10:35:00.000000Z"
  }
}
```

### 3. Marcar Mensajes como Leídos
```
PUT /api/v1/mobile/orders/{orderId}/messages/mark-read
Headers:
  - X-Device-ID: {device_id}
  - Accept: application/json

Response:
{
  "success": true,
  "message": "Mensajes marcados como leídos",
  "data": {
    "messages_marked": 3
  }
}
```

---

## Archivos a Crear/Corregir en Flutter

### 1. Crear Modelo de Mensaje: `lib/models/chat_message.dart`

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
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
    );
  }

  bool get isFromBusiness => senderType == 'business';
  bool get isFromCustomer => senderType == 'customer';
}
```

---

### 2. Crear Servicio de Chat: `lib/services/chat_service.dart`

```dart
import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import 'api_service.dart';

class ChatService {
  /// Obtener mensajes de una orden
  Future<List<ChatMessage>> getMessages(int orderId) async {
    try {
      print('📨 Obteniendo mensajes de orden $orderId...');

      final response = await ApiService.dio.get(
        '/api/v1/mobile/orders/$orderId/messages',
      );

      print('✅ Respuesta recibida: ${response.data}');

      if (response.data['success'] == true) {
        final messagesJson = response.data['data']['messages'] as List;
        final messages = messagesJson
            .map((json) => ChatMessage.fromJson(json))
            .toList();

        print('✅ ${messages.length} mensajes cargados');
        return messages;
      } else {
        print('❌ Error: ${response.data['message']}');
        throw Exception(response.data['message'] ?? 'Error al obtener mensajes');
      }
    } on DioException catch (e) {
      print('❌ DioException: ${e.response?.data ?? e.message}');
      throw Exception(_parseDioError(e));
    } catch (e) {
      print('❌ Error inesperado: $e');
      rethrow;
    }
  }

  /// Enviar un mensaje
  Future<ChatMessage> sendMessage(int orderId, String message) async {
    try {
      print('📤 Enviando mensaje a orden $orderId...');
      print('📝 Mensaje: $message');

      final response = await ApiService.dio.post(
        '/api/v1/mobile/orders/$orderId/messages',
        data: {
          'message': message,
        },
      );

      print('✅ Respuesta: ${response.data}');

      if (response.data['success'] == true) {
        final messageData = response.data['data'];
        final sentMessage = ChatMessage.fromJson(messageData);

        print('✅ Mensaje enviado exitosamente');
        return sentMessage;
      } else {
        print('❌ Error: ${response.data['message']}');
        throw Exception(response.data['message'] ?? 'Error al enviar mensaje');
      }
    } on DioException catch (e) {
      print('❌ DioException al enviar: ${e.response?.data ?? e.message}');
      print('❌ Status code: ${e.response?.statusCode}');
      throw Exception(_parseDioError(e));
    } catch (e) {
      print('❌ Error inesperado al enviar: $e');
      rethrow;
    }
  }

  /// Marcar mensajes como leídos
  Future<void> markAsRead(int orderId) async {
    try {
      print('👁️ Marcando mensajes como leídos para orden $orderId...');

      final response = await ApiService.dio.put(
        '/api/v1/mobile/orders/$orderId/messages/mark-read',
      );

      if (response.data['success'] == true) {
        final markedCount = response.data['data']['messages_marked'];
        print('✅ $markedCount mensajes marcados como leídos');
      }
    } on DioException catch (e) {
      print('⚠️ Error marcando como leídos: ${e.message}');
      // No lanzar excepción, solo loguear
    }
  }

  String _parseDioError(DioException e) {
    if (e.response?.data != null) {
      if (e.response!.data is Map) {
        return e.response!.data['message'] ?? 'Error en la petición';
      }
      return e.response!.data.toString();
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de recepción agotado';
      case DioExceptionType.badResponse:
        return 'Respuesta inválida del servidor';
      case DioExceptionType.cancel:
        return 'Petición cancelada';
      default:
        return e.message ?? 'Error de conexión';
    }
  }
}
```

---

### 3. Crear/Actualizar Pantalla de Chat: `lib/screens/order_chat_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class OrderChatScreen extends StatefulWidget {
  final Order order;

  const OrderChatScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends State<OrderChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Cargar mensajes
  Future<void> _loadMessages() async {
    try {
      print('🔄 Cargando mensajes...');
      setState(() => _isLoading = true);

      final messages = await _chatService.getMessages(widget.order.orderId);

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      print('✅ ${messages.length} mensajes cargados');

      // Scroll al final
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Marcar como leídos
      await _chatService.markAsRead(widget.order.orderId);
    } catch (e) {
      print('❌ Error cargando mensajes: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar mensajes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Enviar mensaje
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) {
      print('⚠️ Mensaje vacío, no se envía');
      return;
    }

    try {
      setState(() => _isSending = true);

      print('📤 Enviando mensaje: $messageText');

      final sentMessage = await _chatService.sendMessage(
        widget.order.orderId,
        messageText,
      );

      print('✅ Mensaje enviado exitosamente');

      // Agregar mensaje a la lista
      setState(() {
        _messages.add(sentMessage);
        _messageController.clear();
      });

      // Scroll al final
      _scrollToBottom();

      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mensaje enviado'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ Error enviando mensaje: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  /// Iniciar polling de mensajes nuevos
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages();
      }
    });
  }

  /// Scroll al final
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.order.folioNumber),
            Text(
              'Chat con el negocio',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text('No hay mensajes aún'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
          ),

          // Input de mensaje
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    enabled: !_isSending,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isSending ? null : _sendMessage,
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
    final isFromBusiness = message.isFromBusiness;

    return Align(
      alignment: isFromBusiness ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isFromBusiness ? Colors.grey[300] : Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isFromBusiness ? Colors.black : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: isFromBusiness ? Colors.black54 : Colors.white70,
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

## Integración con la Pantalla de Detalles de Orden

En tu pantalla de detalles de orden (`order_detail_screen.dart` o similar), agrega el botón de chat:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderChatScreen(order: order),
      ),
    );
  },
  icon: const Icon(Icons.chat),
  label: const Text('Chat con el negocio'),
)
```

---

## Checklist de Implementación

### Archivos a Crear
- [ ] `lib/models/chat_message.dart` - Modelo de mensaje
- [ ] `lib/services/chat_service.dart` - Servicio de chat
- [ ] `lib/screens/order_chat_screen.dart` - Pantalla de chat

### Verificaciones
- [ ] El `device_id` se envía en el header `X-Device-ID`
- [ ] Los prints de debug están habilitados para ver errores
- [ ] La pantalla hace polling cada 5 segundos para nuevos mensajes
- [ ] Los mensajes se marcan como leídos al abrir el chat
- [ ] El scroll se mueve automáticamente al final cuando hay mensajes nuevos

---

## Errores Comunes y Soluciones

### Error 1: "Device ID es requerido"
**Causa**: No se está enviando el header `X-Device-ID`
**Solución**: Verificar que `ApiService.dio` tenga configurado el device_id en los headers

### Error 2: "Dispositivo no encontrado"
**Causa**: El device_id no está registrado en la tabla `mobile_users`
**Solución**: Llamar al endpoint `/api/v1/mobile/register` para registrar el dispositivo primero

### Error 3: "Orden no encontrada o no pertenece a este dispositivo"
**Causa**: La orden no está asociada al `mobile_user_id` del dispositivo
**Solución**: Escanear el QR de la orden para asociarla primero

### Error 4: Los mensajes no se actualizan
**Causa**: El polling no está funcionando
**Solución**: Verificar que `_startPolling()` se llama en `initState()` y que el Timer no se cancela

---

## Prueba Completa

### Desde el Backend (Negocio)
1. Ir a http://127.0.0.1:8000/business/chat
2. Seleccionar una orden activa
3. Enviar mensaje: "Hola, tu orden está lista"
4. Verificar que aparece en la lista

### Desde la App Flutter
1. Abrir la orden en la app
2. Presionar botón "Chat con el negocio"
3. **VERIFICAR**: Debe mostrar el mensaje "Hola, tu orden está lista"
4. Escribir respuesta: "Gracias, voy en camino"
5. Presionar enviar
6. **VERIFICAR**: El mensaje aparece en la app
7. **VERIFICAR**: El mensaje aparece en el backend después de 3 segundos (polling)

### Verificar Logs
Los logs deben mostrar:
```
📨 Obteniendo mensajes de orden 123...
✅ Respuesta recibida: {...}
✅ 1 mensajes cargados
📤 Enviando mensaje a orden 123...
📝 Mensaje: Gracias, voy en camino
✅ Respuesta: {...}
✅ Mensaje enviado exitosamente
```

---

## Resumen

El chat NO funcionaba porque falta implementar:
1. ✅ Modelo de mensaje
2. ✅ Servicio de chat con los 3 endpoints
3. ✅ Pantalla de chat con UI completa
4. ✅ Polling automático para mensajes nuevos
5. ✅ Manejo de errores con mensajes claros

Sigue esta guía paso a paso y el chat funcionará correctamente en tu app Flutter.
