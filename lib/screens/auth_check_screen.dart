import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/device_provider.dart';
import '../providers/orders_provider.dart';
import '../services/notification_service.dart';

/// Pantalla que verifica el estado de autenticación sin UI visible
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Inicializar dispositivo
      final deviceProvider = context.read<DeviceProvider>();
      await deviceProvider.initialize();

      // Inicializar autenticación
      final authProvider = context.read<AuthProvider>();
      await authProvider.initialize();

      // Inicializar notificaciones
      await NotificationService.instance.initialize();

      if (!mounted) return;

      // Verificar estado de autenticación
      if (authProvider.status == AuthStatus.authenticated) {
        // Usuario autenticado, cargar órdenes
        final ordersProvider = context.read<OrdersProvider>();
        await ordersProvider.loadLocalOrders();

        // Intentar sincronizar con el servidor
        try {
          await ordersProvider.fetchOrders();
        } catch (e) {
          print('No se pudo sincronizar con el servidor: $e');
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // No autenticado, ir a login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error durante la inicialización: $e');
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla vacía mientras verifica
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
