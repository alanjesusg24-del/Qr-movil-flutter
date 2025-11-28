/*
 * ============================================================================
 * Project:        Order QR Mobile
 * File:           login_screen_cetam.dart
 * Author:         CETAM Development Team
 * Creation Date:  2025-11-27
 * Last Modified:  2025-11-27
 * Version:        1.0.0
 * Description:    Pantalla de inicio de sesión estandarizada CETAM
 * Dependencies:   flutter/material.dart, provider
 * Notes:          Cumple con estándares CETAM v3.0
 * ============================================================================
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';

/// Colores de la paleta CETAM usados en login
class LoginColors {
  static const background = Color(0xFFF8F9FA);      // Gray-50
  static const titleText = Color(0xFF1F2937);        // Gray-900 (Primary)
  static const subtitleText = Color(0xFF6C757D);     // Gray-600
  static const inputBorder = Color(0xFFE9ECEF);      // Gray-200
  static const inputFocused = Color(0xFF2196F3);     // Blue (Focus color)
  static const inputFill = Color(0xFFFFFFFF);        // White
  static const iconInactive = Color(0xFFADB5BD);     // Gray-500
  static const iconActive = Color(0xFF1F2937);       // Gray-900 (Primary) - Azul fuerte para iconos
  static const buttonPrimary = Color(0xFF1F2937);    // Primary (Gray-900)
  static const buttonText = Color(0xFFFFFFFF);       // White
  static const linkText = Color(0xFF6C757D);         // Gray-600
  static const errorColor = Color(0xFFE11D48);       // Danger
}

class LoginScreenCetam extends StatefulWidget {
  const LoginScreenCetam({super.key});

  @override
  State<LoginScreenCetam> createState() => _LoginScreenCetamState();
}

class _LoginScreenCetamState extends State<LoginScreenCetam> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECEFF1), // Fondo gris más oscuro
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: Colors.white, // Tarjeta blanca
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Título
                  const Text(
                    'Focus',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: LoginColors.titleText,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  const Text(
                    'Inicio de sesión',
                    style: TextStyle(
                      fontSize: 14,
                      color: LoginColors.subtitleText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                // Campo Email
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.email,
                        color: LoginColors.iconActive,
                        size: 20,
                      ),
                      hintText: 'correo@institucion.com',
                      hintStyle: const TextStyle(
                        color: LoginColors.iconActive,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: LoginColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.inputFocused,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.errorColor,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Contraseña
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: _validatePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: LoginColors.iconActive,
                        size: 20,
                      ),
                      hintText: '••••••',
                      hintStyle: const TextStyle(
                        color: LoginColors.iconInactive,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: LoginColors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.inputBorder,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.inputFocused,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.errorColor,
                          width: 1,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: LoginColors.errorColor,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botón Ingresar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LoginColors.buttonPrimary,
                      foregroundColor: LoginColors.buttonText,
                      elevation: 0,
                      disabledBackgroundColor: LoginColors.buttonPrimary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                LoginColors.buttonText,
                              ),
                            ),
                          )
                        : const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: LoginColors.inputBorder)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o',
                        style: TextStyle(
                          color: LoginColors.subtitleText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: LoginColors.inputBorder)),
                  ],
                ),

                const SizedBox(height: 24),

                // Botón Crear Cuenta
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _handleCreateAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LoginColors.buttonPrimary,
                      foregroundColor: LoginColors.buttonText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Crear cuenta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
              // Footer fuera de la tarjeta flotante
              const SizedBox(height: 32),
              Column(
                children: [
                  // Enlaces
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Navegar a términos de uso
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: LoginColors.linkText,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Términos de uso',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: LoginColors.subtitleText)),
                      TextButton(
                        onPressed: () {
                          // TODO: Navegar a aviso de privacidad
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: LoginColors.linkText,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Aviso de privacidad',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Soporte técnico
                  TextButton(
                    onPressed: () {
                      // TODO: Navegar a soporte técnico
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: LoginColors.linkText,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Soporte técnico',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Logo y copyright
                  const Text(
                    '© 2025 Focus',
                    style: TextStyle(
                      fontSize: 11,
                      color: LoginColors.subtitleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sistema de Gestión de Órdenes',
                    style: TextStyle(
                      fontSize: 10,
                      color: LoginColors.subtitleText,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validación de email según estándares CETAM
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo institucional es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  /// Validación de contraseña según estándares CETAM
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Manejo de login
  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Device ID es opcional - puede ser null
      String? deviceId;
      try {
        final deviceProvider = context.read<DeviceProvider>();
        deviceId = deviceProvider.deviceId;
      } catch (e) {
        // DeviceProvider no disponible, continuar sin device_id
        print('[INFO] DeviceProvider no disponible, continuando sin device_id');
      }

      final success = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceId: deviceId, // Puede ser null
      );

      if (mounted) {
        if (success) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          final error = authProvider.errorMessage ?? 'Error al iniciar sesión';

          if (authProvider.status == AuthStatus.deviceChangePending) {
            _showDeviceChangeDialog();
          } else {
            _showError(error);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Mostrar diálogo de cambio de dispositivo
  void _showDeviceChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dispositivo Diferente'),
        content: const Text(
          'Esta cuenta está vinculada a otro dispositivo. '
          '¿Deseas cambiar de dispositivo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/device-change');
            },
            child: const Text('Cambiar Dispositivo'),
          ),
        ],
      ),
    );
  }

  /// Mostrar error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LoginColors.errorColor,
      ),
    );
  }

  /// Navegación a recuperar contraseña
  void _handleForgotPassword() {
    // TODO: Implementar pantalla de recuperación de contraseña
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de recuperar contraseña próximamente'),
        backgroundColor: LoginColors.linkText,
      ),
    );
  }

  /// Navegación a crear cuenta
  void _handleCreateAccount() {
    Navigator.pushNamed(context, '/register');
  }
}
