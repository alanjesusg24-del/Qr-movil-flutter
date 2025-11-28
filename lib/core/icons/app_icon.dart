/*
 * ============================================================================
 * Project:        Order QR Mobile - Focus
 * File:           app_icon.dart
 * Author:         CETAM Development Team
 * Creation Date:  2025-11-27
 * Version:        4.0.0
 * Description:    Widget centralizado para íconos según estándares CETAM v4.0
 * Dependencies:   flutter/material.dart, app_icons.dart
 * Notes:          Reemplaza el uso directo de Icon(Icons.xxx)
 * ============================================================================
 */

import 'package:flutter/material.dart';

/// Widget estandarizado para mostrar íconos según CETAM v4.0
///
/// **Uso básico:**
/// ```dart
/// AppIcon(name: AppIconName.user)
/// ```
///
/// **Con personalización:**
/// ```dart
/// AppIcon(
///   name: AppIconName.success,
///   size: 32,
///   color: Color(0xFF10B981),
/// )
/// ```
///
/// **Ventajas sobre Icon():**
/// - Garantiza consistencia visual
/// - Facilita cambios globales
/// - Soporta temas personalizados
/// - Mejor para mantenimiento
///
/// **NUNCA usar:** `Icon(Icons.xxx)` directamente
/// **SIEMPRE usar:** `AppIcon(name: AppIconName.xxx)`
class AppIcon extends StatelessWidget {
  /// El ícono a mostrar (de AppIconName)
  final IconData name;

  /// Tamaño del ícono en píxeles (default: 24)
  final double? size;

  /// Color del ícono (default: color del tema)
  final Color? color;

  /// Permite override del tema semántico
  final String? semanticLabel;

  const AppIcon({
    super.key,
    required this.name,
    this.size,
    this.color,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      name,
      size: size ?? 24.0,
      color: color,
      semanticLabel: semanticLabel,
    );
  }
}
