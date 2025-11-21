import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import 'api_service.dart';

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
