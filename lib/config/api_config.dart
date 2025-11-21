class ApiConfig {
  // Base URL - Cambiar según el entorno
  // URL para servidor Laravel local (usa la IP de tu computadora en la red local)
  static const String baseUrl = 'https://gerald-ironical-contradictorily.ngrok-free.dev/api/v1';

  // Endpoints - Device
  static const String registerDevice = '/mobile/register';
  static const String associateOrder = '/mobile/orders/associate';
  static const String getOrders = '/mobile/orders';
  static String getOrderDetail(int orderId) => '/mobile/orders/$orderId';
  static const String updateFcmToken = '/mobile/update-token';

  // Endpoints - Auth (solo Google Sign-In)
  static const String authLoginGoogle = '/auth/login/google';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';

  // Endpoints - Device Management
  static const String deviceChangeRequest = '/auth/device/change-request';
  static const String deviceVerifyChange = '/auth/device/verify-change';
  static const String deviceCancelRequest = '/auth/device/cancel-request';

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
