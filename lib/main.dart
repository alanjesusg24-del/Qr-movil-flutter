import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'config/theme.dart';
import 'providers/device_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_qr_screen.dart';
import 'screens/order_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/verify_email_screen.dart';
import 'screens/auth/device_change_screen.dart';
import 'models/order.dart';

// GlobalKey para navegación desde notificaciones
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handler para mensajes en background (debe estar fuera de cualquier clase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Mensaje recibido en background: ${message.notification?.title}');
  print('   Data: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('⚠️ Firebase no configurado: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
      ],
      child: MaterialApp(
        title: 'Order QR System',
        debugShowCheckedModeBanner: false,
        theme: voltTheme(),
        navigatorKey: navigatorKey, // Para navegación desde notificaciones
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/verify-email': (context) => const VerifyEmailScreen(),
          '/device-change': (context) => const DeviceChangeScreen(),
          '/home': (context) => const HomeScreen(),
          '/scan-qr': (context) => const ScanQrScreen(),
          '/order-detail': (context) => const OrderDetailScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/chat') {
            final args = settings.arguments as Map<String, dynamic>;
            final order = args['order'] as Order;
            return MaterialPageRoute(
              builder: (context) => ChatScreen(order: order),
            );
          }
          return null;
        },
      ),
    );
  }
}
