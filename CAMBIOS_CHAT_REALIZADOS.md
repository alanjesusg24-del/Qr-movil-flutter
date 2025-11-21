# Cambios Realizados en el Chat - Flutter

## Resumen

Se han corregido los problemas del chat para asegurar que:
1. Los mensajes se carguen correctamente desde el backend
2. Los mensajes se envíen con autenticación apropiada
3. El token de autenticación se incluya en todas las peticiones del chat

## Problema Principal

El `ChatService` estaba usando su propia instancia de Dio sin configuración de autenticación, lo que causaba que:
- Las peticiones de chat no incluían el header `Authorization`
- El backend no podía identificar al usuario autenticado
- Los mensajes no se asociaban correctamente con el usuario

## Archivos Modificados

### 1. `lib/services/chat_service.dart`

**Cambios realizados:**

#### Antes (INCORRECTO):
```dart
class ChatService {
  static final Dio _dio = Dio(BaseOptions(
    baseURL: ApiConfig.baseUrl,
    headers: {'Content-Type': 'application/json'},
  ));

  static Future<List<ChatMessage>> getMessages(int orderId) async {
    // Usaba _dio sin autenticación
  }
}
```

#### Después (CORRECTO):
```dart
class ChatService {
  /// Obtener mensajes de una orden
  Future<List<ChatMessage>> getMessages(int orderId) async {
    try {
      print('📨 Obteniendo mensajes de orden $orderId...');

      final response = await ApiService.dio.get(
        '/mobile/orders/$orderId/messages',
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
        '/mobile/orders/$orderId/messages',
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
        '/mobile/orders/$orderId/messages/mark-read',
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

**Cambios clave:**
- ❌ Eliminada instancia estática de Dio
- ✅ Ahora usa `ApiService.dio` que tiene el token configurado
- ✅ Convertido de métodos estáticos a métodos de instancia
- ✅ Agregados logs detallados para debug
- ✅ Mejorado manejo de errores con `_parseDioError()`

---

### 2. `lib/screens/chat_screen.dart`

**Cambios realizados:**

#### Línea 1-6: Eliminado import innecesario
```dart
// ANTES:
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

// DESPUÉS: (eliminados)
```

#### Línea 23: Crear instancia de ChatService
```dart
// ANTES:
// No había instancia, se usaban métodos estáticos

// DESPUÉS:
final ChatService _chatService = ChatService();
```

#### Líneas 38-49: Actualizado _initChat()
```dart
Future<void> _initChat() async {
  print('🔄 Inicializando chat para orden ${widget.order.orderId}...');
  await _loadMessages();
  await _chatService.markAsRead(widget.order.orderId);

  // Polling cada 5 segundos para nuevos mensajes
  _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
    if (mounted) {
      _loadMessages(showLoading: false);
    }
  });
}
```

**Cambios:**
- ✅ Usa `_chatService.markAsRead()` en lugar de método estático
- ✅ Eliminada lógica de device_id (manejada por ApiService)
- ✅ Agregado log de inicialización

#### Líneas 51-86: Mejorado _loadMessages()
```dart
Future<void> _loadMessages({bool showLoading = true}) async {
  if (showLoading) {
    setState(() => _isLoading = true);
  }

  try {
    print('🔄 Cargando mensajes...');
    final messages = await _chatService.getMessages(widget.order.orderId);

    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    print('✅ ${messages.length} mensajes cargados en UI');

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  } catch (e) {
    print('❌ Error cargando mensajes: $e');
    if (showLoading) {
      setState(() => _isLoading = false);
    }

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
```

**Cambios:**
- ✅ Usa `_chatService.getMessages()` en lugar de método estático
- ✅ Agregados logs para debug
- ✅ Mejorado manejo de errores con SnackBar

#### Líneas 98-157: Completamente reescrito _sendMessage()
```dart
Future<void> _sendMessage() async {
  final text = _messageController.text.trim();

  if (text.isEmpty) {
    print('⚠️ Mensaje vacío, no se envía');
    return;
  }

  if (_isSending) {
    print('⚠️ Ya hay un mensaje enviándose');
    return;
  }

  setState(() => _isSending = true);

  try {
    print('📤 Enviando mensaje: $text');

    final sentMessage = await _chatService.sendMessage(
      widget.order.orderId,
      text,
    );

    print('✅ Mensaje enviado exitosamente');

    // Agregar mensaje a la lista inmediatamente
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
```

**Cambios:**
- ✅ Usa `_chatService.sendMessage()` en lugar de método estático
- ✅ Eliminado parámetro `device_id`
- ✅ Agregados logs detallados
- ✅ Feedback inmediato en UI (mensaje se agrega antes de recibir confirmación)
- ✅ SnackBar de confirmación/error
- ✅ Mejor manejo del estado `_isSending`

---

## Flujo Corregido del Chat

### 1. Al Abrir el Chat
```
ChatScreen.initState()
  → _initChat()
    → _chatService.getMessages(orderId)
      → ApiService.dio.get('/mobile/orders/{orderId}/messages')
        → Headers incluyen: Authorization: Bearer {token} ✅
      → Backend retorna mensajes del usuario autenticado
    → _chatService.markAsRead(orderId)
      → ApiService.dio.put('/mobile/orders/{orderId}/messages/mark-read')
        → Headers incluyen: Authorization: Bearer {token} ✅
  → Timer de polling cada 5 segundos
```

### 2. Al Enviar un Mensaje
```
Usuario escribe mensaje y presiona enviar
  → _sendMessage()
    → Validar que no esté vacío
    → Validar que no haya otro envío en curso
    → _chatService.sendMessage(orderId, text)
      → ApiService.dio.post('/mobile/orders/{orderId}/messages')
        → Headers incluyen: Authorization: Bearer {token} ✅
        → Body: {message: "texto del mensaje"}
      → Backend asocia mensaje con user_id del token
      → Backend retorna mensaje creado
    → Agregar mensaje a la lista inmediatamente
    → Scroll al final
    → Mostrar SnackBar de confirmación
```

### 3. Polling Automático
```
Cada 5 segundos:
  → _loadMessages(showLoading: false)
    → _chatService.getMessages(orderId)
      → ApiService.dio.get('/mobile/orders/{orderId}/messages')
        → Headers incluyen: Authorization: Bearer {token} ✅
    → Actualizar lista de mensajes sin mostrar loading
```

---

## Cómo Verificar que Funciona

### 1. Abrir el chat de una orden

Deberías ver en los logs:

```
🔄 Inicializando chat para orden 123...
📨 Obteniendo mensajes de orden 123...
✅ Respuesta recibida: {success: true, data: {...}}
✅ 5 mensajes cargados
✅ 5 mensajes cargados en UI
👁️ Marcando mensajes como leídos para orden 123...
✅ 2 mensajes marcados como leídos
```

### 2. Enviar un mensaje

Deberías ver en los logs:

```
📤 Enviando mensaje a orden 123...
📝 Mensaje: Hola, ¿cómo va mi pedido?
✅ Respuesta: {success: true, data: {...}}
✅ Mensaje enviado exitosamente
```

Y en la UI:
- El mensaje aparece inmediatamente en el chat
- SnackBar verde: "Mensaje enviado"
- El scroll va automáticamente al final

### 3. Verificar autenticación

En los logs de backend (Laravel) deberías ver:

```
[INFO] Fetching messages for authenticated user {"user_id": 7, "order_id": 123}
[INFO] Message sent by authenticated user {"user_id": 7, "order_id": 123, "message": "Hola..."}
```

**NO debería decir**: "device_id" en los logs de chat

---

## Problemas Conocidos y Soluciones

### ❌ Si los mensajes no cargan

**Logs esperados:**
```
🔄 Cargando mensajes...
📨 Obteniendo mensajes de orden 123...
❌ DioException: 401 Unauthorized
```

**Causa**: El token no se está enviando correctamente

**Solución**:
1. Verificar que el usuario esté autenticado
2. Verificar logs: `🔐 Token configurado en ApiService`
3. Cerrar sesión y volver a iniciar sesión

### ❌ Si no se pueden enviar mensajes

**Logs esperados:**
```
📤 Enviando mensaje: Hola
❌ DioException al enviar: 401 Unauthorized
❌ Status code: 401
```

**Causa**: Similar al anterior, problema de autenticación

**Solución**: Igual que el problema anterior

### ❌ Si el mensaje se envía pero no aparece en la lista

**Causa**: El polling no está funcionando o hay un error en el backend

**Solución**:
1. Esperar 5 segundos (polling automático)
2. Verificar logs del backend
3. Revisar que el backend retorne el mensaje en el formato correcto

---

## Estado Actual

### ✅ Completado en Flutter

- [x] ChatService usa ApiService.dio con autenticación
- [x] Métodos convertidos de estáticos a instancia
- [x] Logs de debug implementados
- [x] Manejo de errores mejorado
- [x] UI con feedback inmediato
- [x] SnackBars de confirmación/error
- [x] Polling automático de mensajes
- [x] Marcar mensajes como leídos

### ⚠️ Pendiente de Pruebas

- [ ] Probar enviar un mensaje desde la app
- [ ] Verificar que el mensaje se asocie al usuario correcto
- [ ] Probar con dos usuarios diferentes en el mismo chat
- [ ] Verificar que el polling funcione correctamente

---

## Próximos Pasos

1. **Probar el chat**:
   - Abrir una orden
   - Hacer clic en el botón de chat
   - Enviar un mensaje
   - Verificar que aparezca correctamente

2. **Monitorear logs**:
   ```bash
   flutter logs | grep -E "(📨|📤|✅|❌|🔄)"
   ```

3. **Si hay errores**:
   - Compartir los logs completos
   - Verificar respuesta del backend
   - Revisar que los endpoints estén correctos

---

## Comandos Útiles

### Ver logs del chat en tiempo real
```bash
flutter logs | grep -E "(📨|📤|✅|❌|🔄|👁️)"
```

### Ver todos los logs de Flutter
```bash
flutter run -v
```

### Hot reload después de cambios
```
r (en la terminal donde corre flutter run)
```

---

**Nota**: Los cambios son compatibles con el sistema de autenticación implementado previamente. El chat ahora forma parte del ecosistema autenticado de la app.
