import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';
import '../core/icons/app_icon.dart';
import '../core/icons/app_icons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AppIcon(
              name: AppIconName.userCircle,
              size: 28,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/notifications'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Placeholder para notificaciones
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    name: AppIconName.notification,
                    size: 80,
                    color: AppColors.gray400,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No hay notificaciones',
                    style: AppTextStyles.h5.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Aquí aparecerán las notificaciones de tus órdenes',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
