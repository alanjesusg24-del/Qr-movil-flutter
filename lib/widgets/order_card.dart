import 'package:flutter/material.dart';
import '../models/order.dart';
import '../config/theme.dart';
import '../screens/chat_screen.dart';
import 'volt_card.dart';
import 'volt_badge.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return VoltCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Folio + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.folioNumber,
                style: AppTextStyles.h5,
              ),
              VoltBadge(
                text: _getStatusLabel(order.status),
                backgroundColor: _getStatusColor(order.status),
                icon: _getStatusIcon(order.status),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Descripción
          Text(
            order.description ?? 'Sin descripción',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.md),

          // Footer: Time
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                _formatTime(order.createdAt),
                style: AppTextStyles.caption,
              ),
              if (order.customerName != null) ...[
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.person, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.customerName!,
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              const Spacer(),
              // Botón de chat
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(order: order),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: order.hasUnreadMessages
                        ? AppColors.primary
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble,
                        size: 16,
                        color: order.hasUnreadMessages
                            ? Colors.white
                            : AppColors.textMuted,
                      ),
                      if (order.unreadMessagesCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${order.unreadMessagesCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        return 'Listo';
      case 'delivered':
        return 'Entregado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
