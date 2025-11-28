import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';
import '../providers/subscription_provider.dart';
import '../core/icons/app_icon.dart';
import '../core/icons/app_icons.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suscripción'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: AppIcon(
              name: AppIconName.notification,
              size: 28,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          IconButton(
            icon: AppIcon(
              name: AppIconName.userCircle,
              size: 28,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/premium'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Estado de suscripción
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: subscriptionProvider.isPremium
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.gray200,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(
                color: subscriptionProvider.isPremium
                    ? AppColors.success
                    : AppColors.gray300,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                AppIcon(
                  name: subscriptionProvider.isPremium
                      ? AppIconName.success
                      : AppIconName.premium,
                  size: 64,
                  color: subscriptionProvider.isPremium
                      ? AppColors.success
                      : AppColors.gray400,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  subscriptionProvider.isPremium
                      ? 'Suscripción Activa'
                      : 'Sin Suscripción',
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: subscriptionProvider.isPremium
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subscriptionProvider.isPremium
                      ? 'Tienes acceso a todas las funciones premium'
                      : 'Activa tu suscripción para desbloquear funciones premium',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Título de beneficios
          Text(
            'Beneficios Premium',
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Lista de beneficios
          _buildBenefit(
            icon: AppIconName.business,
            title: 'Ver todos los negocios',
            description: 'Accede al directorio completo de negocios disponibles',
            isActive: subscriptionProvider.isPremium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefit(
            icon: AppIconName.notification,
            title: 'Notificaciones prioritarias',
            description: 'Recibe alertas instantáneas sobre tus órdenes',
            isActive: subscriptionProvider.isPremium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefit(
            icon: AppIconName.orderActive,
            title: 'Procesamiento rápido',
            description: 'Tus órdenes se procesan con mayor prioridad',
            isActive: subscriptionProvider.isPremium,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefit(
            icon: AppIconName.support,
            title: 'Soporte premium',
            description: 'Atención personalizada y soporte 24/7',
            isActive: subscriptionProvider.isPremium,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Botón de acción
          if (!subscriptionProvider.isPremium) ...[
            ElevatedButton(
              onPressed: subscriptionProvider.isLoading
                  ? null
                  : () async {
                      try {
                        await subscriptionProvider.activatePremium();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Suscripción activada!'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: subscriptionProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Activar Suscripción',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '\$9.99 / mes',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            OutlinedButton(
              onPressed: subscriptionProvider.isLoading
                  ? null
                  : () async {
                      // Mostrar diálogo de confirmación
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Cancelar Suscripción'),
                          content: const Text(
                            '¿Estás seguro de que deseas cancelar tu suscripción premium? Perderás acceso a todas las funciones premium.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.danger,
                              ),
                              child: const Text('Sí, cancelar'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        try {
                          await subscriptionProvider.deactivatePremium();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Suscripción cancelada'),
                                backgroundColor: Colors.orange,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: subscriptionProvider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.danger,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Cancelar Suscripción',
                      style: AppTextStyles.button.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String title,
    required String description,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.success.withOpacity(0.1)
                : AppColors.gray200,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: AppIcon(
            name: icon,
            color: isActive ? AppColors.success : AppColors.gray400,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (isActive)
          AppIcon(
            name: AppIconName.success,
            color: AppColors.success,
            size: 20,
          ),
      ],
    );
  }
}
