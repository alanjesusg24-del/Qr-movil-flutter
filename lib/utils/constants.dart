class Constants {
  // App
  static const String appName = 'Order QR System';
  static const String appVersion = '1.0.0';

  // API
  static const int apiTimeout = 30;
  static const int maxRetries = 3;

  // Local Storage Keys
  static const String deviceIdKey = 'device_id';
  static const String fcmTokenKey = 'fcm_token';
  static const String lastSyncKey = 'last_sync';

  // QR
  static const int qrTokenLength = 32;
  static const int pickupTokenLength = 16;

  // Order Status
  static const String statusPending = 'pending';
  static const String statusReady = 'ready';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int splashDuration = 2; // seconds
  static const int snackbarDuration = 3; // seconds
}
