import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/mobile_user.dart';

class ApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectionTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.headers,
    ),
  );

  static String? _deviceId;

  static void setDeviceId(String deviceId) {
    _deviceId = deviceId;
    _dio.options.headers['X-Device-ID'] = deviceId;
  }

  // Registro de dispositivo móvil
  static Future<MobileUser> registerDevice({
    required String deviceId,
    String? fcmToken,
    required String deviceType,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.registerDevice,
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'device_type': deviceType,
          'device_model': deviceModel,
          'os_version': osVersion,
          'app_version': appVersion,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return MobileUser.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Error al registrar dispositivo');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Asociar orden con cliente (escaneo inicial)
  static Future<Order> associateOrder(String qrToken) async {
    try {
      final response = await _dio.post(
        ApiConfig.associateOrder,
        data: {'qr_token': qrToken},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Acceder directamente a data, no a data['order']
        final orderData = response.data['data'];

        if (orderData == null) {
          throw Exception('No se recibieron datos de la orden');
        }

        return Order.fromJson(orderData);
      } else {
        throw Exception(response.data['message'] ?? 'Error al asociar orden');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Obtener órdenes del cliente
  static Future<List<Order>> getOrders({
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (status != null) {
        queryParams['status'] = status;
      }

      final response = await _dio.get(
        ApiConfig.getOrders,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> ordersJson = response.data['data']['orders'];
        return ordersJson.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Error al obtener órdenes');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Obtener detalle de orden
  static Future<Order> getOrderDetail(int orderId) async {
    try {
      final response = await _dio.get(
        ApiConfig.getOrderDetail(orderId),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Acceder directamente a data, no a data['order']
        final orderData = response.data['data'];

        if (orderData == null) {
          throw Exception('No se recibieron datos de la orden');
        }

        return Order.fromJson(orderData);
      } else {
        throw Exception(response.data['message'] ?? 'Error al obtener orden');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Actualizar FCM Token
  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      final response = await _dio.put(
        ApiConfig.updateFcmToken,
        data: {'fcm_token': fcmToken},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Error al actualizar token');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Manejo de errores
  static Exception _handleError(DioException e) {
    String message = 'Error de conexión';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Tiempo de espera agotado';
        break;
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;

        if (data != null && data['message'] != null) {
          message = data['message'];
        } else {
          switch (statusCode) {
            case 404:
              message = 'Recurso no encontrado';
              break;
            case 409:
              message = 'Conflicto: Ya existe un registro';
              break;
            case 422:
              message = 'Datos inválidos';
              break;
            case 429:
              message = 'Demasiadas peticiones, intenta más tarde';
              break;
            case 500:
              message = 'Error del servidor';
              break;
            case 503:
              message = 'Servicio no disponible';
              break;
            default:
              message = 'Error: $statusCode';
          }
        }
        break;
      case DioExceptionType.cancel:
        message = 'Petición cancelada';
        break;
      case DioExceptionType.unknown:
        message = 'Sin conexión a internet';
        break;
      default:
        message = 'Error desconocido';
    }

    return Exception(message);
  }
}
