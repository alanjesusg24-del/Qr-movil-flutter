import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/order.dart';
import '../models/mobile_user.dart';
import '../models/business.dart';

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
  static String? _authToken;

  static void setDeviceId(String deviceId) {
    _deviceId = deviceId;
    _dio.options.headers['X-Device-ID'] = deviceId;
  }

  /// Configurar token de autenticación
  static void setAuthToken(String? token) {
    _authToken = token;
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      print('Token configurado en ApiService: ${token.substring(0, 10)}...');
      print('Headers actuales: ${_dio.options.headers}');
    } else {
      _dio.options.headers.remove('Authorization');
      print('Token removido de ApiService');
    }
  }

  /// Verificar si el usuario está autenticado
  static bool get isAuthenticated => _authToken != null;

  /// Obtener el token actual
  static String? get authToken => _authToken;

  /// Exponer instancia de Dio para otros servicios
  static Dio get dio => _dio;

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

      // Debug: Mostrar si está autenticado
      print('========== OBTENIENDO ÓRDENES ==========');
      print('Autenticado: $isAuthenticated');
      print('Token presente: ${_authToken != null}');
      if (_authToken != null) {
        print('Token actual: ${_authToken!.substring(0, 20)}...');
      }
      print('Device ID: $_deviceId');
      print('Headers que se enviarán: ${_dio.options.headers}');

      final response = await _dio.get(
        ApiConfig.getOrders,
        queryParameters: queryParams,
      );

      print('Respuesta del servidor recibida');
      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> ordersJson = response.data['data']['orders'];
        print('${ordersJson.length} órdenes obtenidas del servidor');
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

  /// Obtener todos los negocios disponibles
  ///
  /// Retorna una lista de todos los negocios registrados en el sistema.
  /// Soporta paginación a través de parámetros opcionales.
  static Future<List<Business>> getAllBusinesses({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.getAllBusinesses,
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> businessesJson = response.data['data']['businesses'] ?? response.data['data'];
        return businessesJson.map((json) => Business.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Error al obtener negocios');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Obtener negocios cercanos a una ubicación
  ///
  /// [latitude] Latitud de la ubicación actual
  /// [longitude] Longitud de la ubicación actual
  /// [radius] Radio de búsqueda en kilómetros (default: 10km)
  ///
  /// Retorna una lista de negocios cercanos ordenados por distancia.
  static Future<List<Business>> getNearbyBusinesses({
    required double latitude,
    required double longitude,
    double radius = 10.0,
  }) async {
    try {
      final response = await _dio.get(
        ApiConfig.getNearbyBusinesses,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
        options: Options(
          headers: {
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> businessesJson = response.data['data']['businesses'] ?? response.data['data'];
        return businessesJson.map((json) => Business.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? 'Error al obtener negocios cercanos');
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Actualizar FCM token en el servidor
  static Future<void> updateFcmToken(String fcmToken) async {
    try {
      print('[API] Actualizando FCM token en backend...');
      await _dio.put(
        ApiConfig.updateFcmToken,
        data: {
          'fcm_token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      print('[API] FCM token actualizado exitosamente');
    } on DioException catch (e) {
      print('[API] Error al actualizar FCM token: ${e.response?.data ?? e.message}');
      // No lanzar excepción para no interrumpir el flujo de la app
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
