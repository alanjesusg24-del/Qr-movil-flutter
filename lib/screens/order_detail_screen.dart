import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../providers/orders_provider.dart';
import '../widgets/volt_card.dart';
import '../widgets/volt_badge.dart';
import '../widgets/volt_button.dart';
import '../widgets/qr_display.dart';
import '../widgets/order_timeline.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late int orderId;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    orderId = args['orderId'] as int;
    _refreshOrder();
  }

  Future<void> _refreshOrder() async {
    setState(() {
      isLoading = true;
    });

    try {
      await context.read<OrdersProvider>().refreshOrder(orderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede realizar la llamada'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Orden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _refreshOrder,
          ),
        ],
      ),
      body: Consumer<OrdersProvider>(
        builder: (context, ordersProvider, child) {
          final order = ordersProvider.getOrderById(orderId);

          if (order == null) {
            return const Center(
              child: Text('Orden no encontrada'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshOrder,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Folio y Estado
                  VoltCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.folioNumber,
                              style: AppTextStyles.h4,
                            ),
                            VoltBadge(
                              text: _getStatusLabel(order.status),
                              backgroundColor: _getStatusColor(order.status),
                              icon: _getStatusIcon(order.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Descripción',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          order.description ?? 'Sin descripción',
                          style: AppTextStyles.body1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // QR para entrega (solo si está ready)
                  if (order.status == 'ready') ...[
                    VoltCard(
                      child: Column(
                        children: [
                          Text(
                            '¡Tu orden está lista!',
                            style: AppTextStyles.h5.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          QrDisplay(
                            qrData: order.qrCodeUrl,
                            size: 220,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMedium,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Token de Recolección',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  order.pickupToken,
                                  style: AppTextStyles.h5.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Información del Cliente
                  if (order.customerName != null ||
                      order.customerPhone != null ||
                      order.customerEmail != null)
                    VoltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Información del Cliente',
                            style: AppTextStyles.h6,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (order.customerName != null)
                            _buildInfoRow(
                              Icons.person,
                              'Cliente',
                              order.customerName!,
                            ),
                          if (order.customerPhone != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _buildInfoRow(
                              Icons.phone,
                              'Teléfono',
                              order.customerPhone!,
                              onTap: () => _makePhoneCall(order.customerPhone!),
                            ),
                          ],
                          if (order.customerEmail != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            _buildInfoRow(
                              Icons.email,
                              'Email',
                              order.customerEmail!,
                            ),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Items de la orden
                  if (order.items.isNotEmpty)
                    VoltCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Items de la Orden',
                            style: AppTextStyles.h6,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...order.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.itemName,
                                        style: AppTextStyles.body1,
                                      ),
                                      if (item.description != null)
                                        Text(
                                          item.description!,
                                          style: AppTextStyles.caption,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'x${item.quantity}',
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '\$${item.totalPrice.toStringAsFixed(2)}',
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: AppTextStyles.h6,
                              ),
                              Text(
                                '\$${order.totalAmount.toStringAsFixed(2)}',
                                style: AppTextStyles.h6.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Timeline
                  VoltCard(
                    child: OrderTimeline(order: order),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Botón de llamada si está disponible
                  if (order.customerPhone != null)
                    VoltButton(
                      text: 'Llamar al Cliente',
                      icon: Icons.phone,
                      backgroundColor: AppColors.success,
                      onPressed: () => _makePhoneCall(order.customerPhone!),
                      width: double.infinity,
                    ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption,
              ),
              Text(
                value,
                style: AppTextStyles.body1,
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textMuted,
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: row,
        ),
      );
    }

    return row;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'ready':
        return AppColors.success;
      case 'delivered':
        return AppColors.info;
      case 'cancelled':
        return AppColors.danger;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'ready':
        return Icons.check_circle;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'ready':
        return 'Listo para Recoger';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
