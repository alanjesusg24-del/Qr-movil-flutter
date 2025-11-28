/*
 * ============================================================================
 * Project:        Order QR Mobile
 * File:           register_screen_cetam.dart
 * Author:         CETAM Development Team
 * Creation Date:  2025-11-27
 * Last Modified:  2025-11-27
 * Version:        1.0.0
 * Description:    Pantalla de registro estandarizada CETAM
 * Dependencies:   flutter/material.dart, provider
 * Notes:          Cumple con estándares CETAM v3.0
 * ============================================================================
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';

/// Colores de la paleta CETAM usados en registro
class RegisterColors {
  static const background = Color(0xFFECEFF1);      // Fondo gris
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

class RegisterScreenCetam extends StatefulWidget {
  const RegisterScreenCetam({super.key});

  @override
  State<RegisterScreenCetam> createState() => _RegisterScreenCetamState();
}

class _RegisterScreenCetamState extends State<RegisterScreenCetam> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegisterColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                      color: RegisterColors.titleText,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  const Text(
                    'Crear nueva cuenta',
                    style: TextStyle(
                      fontSize: 14,
                      color: RegisterColors.subtitleText,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Campo Nombre
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: TextFormField(
                      controller: _nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      validator: _validateName,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.person,
                          color: RegisterColors.iconActive,
                          size: 20,
                        ),
                        hintText: 'Nombre completo',
                        hintStyle: const TextStyle(
                          color: RegisterColors.iconActive,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: RegisterColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputFocused,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
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
                          color: RegisterColors.iconActive,
                          size: 20,
                        ),
                        hintText: 'correo@institucion.com',
                        hintStyle: const TextStyle(
                          color: RegisterColors.iconActive,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: RegisterColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputFocused,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
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
                          color: RegisterColors.iconActive,
                          size: 20,
                        ),
                        hintText: '••••••',
                        hintStyle: const TextStyle(
                          color: RegisterColors.iconInactive,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: RegisterColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputFocused,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
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

                  // Campo Confirmar Contraseña
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      validator: _validateConfirmPassword,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: RegisterColors.iconActive,
                          size: 20,
                        ),
                        hintText: '••••••',
                        hintStyle: const TextStyle(
                          color: RegisterColors.iconInactive,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: RegisterColors.inputFill,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputBorder,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.inputFocused,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
                            width: 1,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: RegisterColors.errorColor,
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

                  // Botón Crear Cuenta
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RegisterColors.buttonPrimary,
                        foregroundColor: RegisterColors.buttonText,
                        elevation: 0,
                        disabledBackgroundColor: RegisterColors.buttonPrimary.withValues(alpha: 0.5),
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
                                  RegisterColors.buttonText,
                                ),
                              ),
                            )
                          : const Text(
                              'Crear cuenta',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enlace Ya tengo cuenta
                  TextButton(
                    onPressed: _handleBackToLogin,
                    style: TextButton.styleFrom(
                      foregroundColor: RegisterColors.linkText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                    ),
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                          foregroundColor: RegisterColors.linkText,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text(
                          'Términos de uso',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      const Text('•', style: TextStyle(color: RegisterColors.subtitleText)),
                      TextButton(
                        onPressed: () {
                          // TODO: Navegar a aviso de privacidad
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: RegisterColors.linkText,
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
                      foregroundColor: RegisterColors.linkText,
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
                      color: RegisterColors.subtitleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sistema de Gestión de Órdenes',
                    style: TextStyle(
                      fontSize: 10,
                      color: RegisterColors.subtitleText,
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

  /// Validación de email
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingrese un correo válido';
    }
    return null;
  }

  /// Validación de contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Validación de confirmar contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme su contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Validación de nombre
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su nombre';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Manejo de registro
  void _handleRegister() async {
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

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceId: deviceId, // Puede ser null
      );

      if (mounted) {
        if (success) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cuenta creada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Navegar a home
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          final error = authProvider.errorMessage ?? 'Error al crear la cuenta';
          _showError(error);
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

  /// Mostrar error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RegisterColors.errorColor,
      ),
    );
  }

  /// Volver a login
  void _handleBackToLogin() {
    Navigator.pop(context);
  }
}
