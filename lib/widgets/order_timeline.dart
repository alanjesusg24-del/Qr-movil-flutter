import 'package:flutter/material.dart';
import '../models/order.dart';
import '../config/theme.dart';

class OrderTimeline extends StatelessWidget {
  final Order order;

  const OrderTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historial de Estados', style: AppTextStyles.h6),
        const SizedBox(height: AppSpacing.md),
        _buildTimelineItem(
          'Orden Creada',
          order.createdAt,
          AppColors.success,
          true,
          isLast: order.readyAt == null &&
              order.deliveredAt == null &&
              order.cancelledAt == null,
        ),
        if (order.readyAt != null)
          _buildTimelineItem(
            'Orden Lista',
            order.readyAt!,
            AppColors.success,
            true,
            isLast: order.deliveredAt == null && order.cancelledAt == null,
          ),
        if (order.deliveredAt != null)
          _buildTimelineItem(
            'Orden Entregada',
            order.deliveredAt!,
            AppColors.info,
            true,
            isLast: true,
          ),
        if (order.cancelledAt != null)
          _buildTimelineItem(
            'Orden Cancelada',
            order.cancelledAt!,
            AppColors.danger,
            true,
            isLast: true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    DateTime timestamp,
    Color color,
    bool isCompleted, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? color : AppColors.gray300,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 18,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: AppColors.gray300,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body1),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(timestamp),
                  style: AppTextStyles.caption,
                ),
                if (!isLast) const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
