class FirebaseConfig {
  // Notification channels
  static const String orderUpdatesChannelId = 'order_updates';
  static const String orderUpdatesChannelName = 'Actualizaciones de Órdenes';
  static const String orderUpdatesChannelDescription = 'Notificaciones sobre el estado de tus órdenes';

  // Notification IDs
  static const int orderReadyNotificationId = 1001;
  static const int orderCancelledNotificationId = 1002;

  // Topics
  static const String allUsersTopic = 'all_users';

  // Firebase options will be configured in firebase_options.dart
  // after running: flutterfire configure
}
