class ApiConfig {
  // Base URL - Cambiar según el entorno
  // URL para servidor Laravel local (usa la IP de tu computadora en la red local)
  static const String baseUrl = 'http://192.168.1.66:8000/api/v1';

  // Endpoints
  static const String registerDevice = '/mobile/register';
  static const String associateOrder = '/mobile/orders/associate';
  static const String getOrders = '/mobile/orders';
  static String getOrderDetail(int orderId) => '/mobile/orders/$orderId';
  static const String updateFcmToken = '/mobile/update-token';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Rate limiting
  static const int maxRequestsPerMinute = 60;
}
