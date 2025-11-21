import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/device_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/auth_provider.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Inicializar dispositivo
      final deviceProvider = context.read<DeviceProvider>();
      await deviceProvider.initialize();

      // Inicializar autenticación
      final authProvider = context.read<AuthProvider>();
      await authProvider.initialize();

      // Inicializar notificaciones
      await NotificationService.instance.initialize();

      // Configurar callback de notificaciones
      NotificationService.instance.onNotificationNavigate = (data) {
        final orderId = int.tryParse(data['order_id']?.toString() ?? '');
        if (orderId != null) {
          Navigator.pushReplacementNamed(
            context,
            '/order-detail',
            arguments: {'orderId': orderId},
          );
        }
      };

      // Esperar un poco para mostrar el splash
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // Verificar estado de autenticación
      print('🔍 Estado de autenticación: ${authProvider.status}');
      print('👤 Usuario: ${authProvider.user?.email}');
      print('✅ ¿Autenticado? ${authProvider.isAuthenticated}');

      if (authProvider.status == AuthStatus.authenticated) {
        // Usuario autenticado, cargar órdenes
        final ordersProvider = context.read<OrdersProvider>();
        await ordersProvider.loadLocalOrders();

        // Intentar sincronizar con el servidor
        try {
          await ordersProvider.fetchOrders();
        } catch (e) {
          print('⚠️ No se pudo sincronizar con el servidor: $e');
        }

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else if (authProvider.status == AuthStatus.emailNotVerified) {
        // Email no verificado, ir a pantalla de verificación
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/verify-email',
            arguments: {'userId': authProvider.user?.userId},
          );
        }
      } else {
        // No autenticado, ir a login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('❌ Error durante la inicialización: $e');
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error de Inicialización'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error),
            const SizedBox(height: 16),
            const Text(
              'Posibles soluciones:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Verifica tu conexión a internet'),
            const Text('• Asegúrate de que el servidor esté corriendo'),
            const Text('• Revisa la configuración de red'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initialize();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono de la app
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Order QR System',
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Gestión de Órdenes',
              style: AppTextStyles.body1.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
