import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/orders_provider.dart';
import '../widgets/volt_card.dart';
import '../widgets/order_card.dart';
import '../services/notification_service.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _refreshOrders();
    _setupNotifications();
  }

  void _setupNotifications() {
    // Configurar listeners de notificaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.setupNotificationListeners(context);

      // Configurar callback de navegación
      NotificationService.instance.onNotificationNavigate = (data) {
        _handleNotificationNavigation(data);
      };
    });
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final orderId = int.tryParse(data['order_id']?.toString() ?? '');

    print('🔔 Navegando por notificación: type=$type, orderId=$orderId');

    switch (type) {
      case 'order_status_change':
      case 'order_associated':
        if (orderId != null) {
          // Navegar a la pantalla de detalle de orden
          navigatorKey.currentState?.pushNamed(
            '/order-detail',
            arguments: {'orderId': orderId},
          );
        }
        break;

      case 'new_message':
        if (orderId != null) {
          // Navegar a la pantalla de chat
          final ordersProvider = context.read<OrdersProvider>();
          final order = ordersProvider.getOrderById(orderId);
          if (order != null) {
            navigatorKey.currentState?.pushNamed(
              '/chat',
              arguments: {'order': order},
            );
          }
        }
        break;

      case 'order_reminder':
        // Ya estamos en la pantalla de home, solo refrescar
        _refreshOrders();
        break;

      case 'order_cancelled':
        // Refrescar la lista de órdenes
        _refreshOrders();
        break;
    }
  }

  Future<void> _refreshOrders() async {
    final ordersProvider = context.read<OrdersProvider>();
    await ordersProvider.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Órdenes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: Consumer<OrdersProvider>(
          builder: (context, ordersProvider, child) {
            if (ordersProvider.isLoading && ordersProvider.orders.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final filteredOrders = _getFilteredOrders(ordersProvider);

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Estadísticas
                VoltCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        'Activas',
                        '${ordersProvider.activeOrdersCount}',
                        AppColors.warning,
                      ),
                      _buildStat(
                        'Listas',
                        '${ordersProvider.readyOrdersCount}',
                        AppColors.success,
                      ),
                      _buildStat(
                        'Total',
                        '${ordersProvider.totalOrdersCount}',
                        AppColors.info,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Filtros
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todas', 'all'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Pendientes', 'pending'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Listas', 'ready'),
                      const SizedBox(width: AppSpacing.sm),
                      _buildFilterChip('Entregadas', 'delivered'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Título de sección
                Text(
                  _getSectionTitle(),
                  style: AppTextStyles.h5,
                ),
                const SizedBox(height: AppSpacing.md),

                // Lista de órdenes
                if (filteredOrders.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No hay órdenes',
                            style: AppTextStyles.h6.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Escanea un código QR para comenzar',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...filteredOrders.map((order) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: OrderCard(
                          order: order,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/order-detail',
                              arguments: {'orderId': order.orderId},
                            );
                          },
                        ),
                      )),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/scan-qr');
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Escanear QR'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.h3.copyWith(color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildFilterChip(String label, String filter) {
    final isSelected = _selectedFilter == filter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.gray300,
      ),
    );
  }

  List<dynamic> _getFilteredOrders(OrdersProvider provider) {
    switch (_selectedFilter) {
      case 'pending':
        return provider.pendingOrders;
      case 'ready':
        return provider.readyOrders;
      case 'delivered':
        return provider.deliveredOrders;
      case 'all':
      default:
        return provider.orders;
    }
  }

  String _getSectionTitle() {
    switch (_selectedFilter) {
      case 'pending':
        return 'Órdenes Pendientes';
      case 'ready':
        return 'Órdenes Listas';
      case 'delivered':
        return 'Órdenes Entregadas';
      case 'all':
      default:
        return 'Todas las Órdenes';
    }
  }
}
