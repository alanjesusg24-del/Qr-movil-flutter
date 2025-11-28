import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../core/icons/app_icon.dart';
import '../core/icons/app_icons.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final subscriptionProvider = context.watch<SubscriptionProvider>();

    return Drawer(
      backgroundColor: AppColors.primary,
      child: Column(
        children: [
          // Header con logo y nombre
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  // Icono de la aplicación
                  AppIcon(
                    name: AppIconName.qrScan,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Nombre de la app
                  const Text(
                    'Focus',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Opciones de navegación
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: AppIconName.home,
                  selectedIcon: AppIconName.home,
                  title: 'Inicio',
                  route: '/home',
                  isSelected: currentRoute == '/home',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: AppIconName.business,
                  selectedIcon: AppIconName.business,
                  title: 'Todos los Negocios',
                  route: '/all-businesses',
                  isSelected: currentRoute == '/all-businesses',
                  isPremium: true,
                  hasPremiumAccess: subscriptionProvider.isPremium,
                ),
                _buildDrawerItem(
                  context: context,
                  icon: AppIconName.map,
                  selectedIcon: AppIconName.map,
                  title: 'Mapa',
                  route: '/map',
                  isSelected: currentRoute == '/map',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: AppIconName.settings,
                  selectedIcon: AppIconName.settings,
                  title: 'Configuración',
                  route: '/settings',
                  isSelected: currentRoute == '/settings',
                ),
                _buildDrawerItem(
                  context: context,
                  icon: AppIconName.premium,
                  selectedIcon: AppIconName.premium,
                  title: 'Suscripción',
                  route: '/premium',
                  isSelected: currentRoute == '/premium',
                ),
              ],
            ),
          ),

          // Botón de cerrar sesión
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListTile(
              leading: AppIcon(
                name: AppIconName.logout,
                color: Colors.white,
              ),
              title: const Text(
                'Cerrar Sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              onTap: () async {
                // Mostrar diálogo de confirmación
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text(
                      '¿Estás seguro de que deseas cerrar sesión?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                        child: const Text('Cerrar Sesión'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (!context.mounted) return;

                  // Cerrar sesión primero
                  final auth = context.read<AuthProvider>();
                  await auth.logout();

                  // Navegar a login y limpiar toda la pila de navegación
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String title,
    required String route,
    required bool isSelected,
    bool isPremium = false,
    bool hasPremiumAccess = false,
  }) {
    return ListTile(
      leading: AppIcon(
        name: isSelected ? selectedIcon : icon,
        color: Colors.white,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ),
          if (isPremium && !hasPremiumAccess) ...[
            const SizedBox(width: 4),
            AppIcon(
              name: AppIconName.premium,
              size: 16,
              color: AppColors.warning,
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedTileColor: Colors.white.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context); // Cerrar el drawer
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pop(context); // Solo cerrar el drawer si ya estamos en esa ruta
        }
      },
    );
  }
}
