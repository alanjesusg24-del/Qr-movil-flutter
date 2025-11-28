import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/auth/code_input_field.dart';

class DeviceChangeScreen extends StatefulWidget {
  const DeviceChangeScreen({super.key});

  @override
  State<DeviceChangeScreen> createState() => _DeviceChangeScreenState();
}

class _DeviceChangeScreenState extends State<DeviceChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _requestSent = false;
  bool _canResend = false;
  int _resendCountdown = 60;
  Timer? _countdownTimer;
  int? _requestId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleRequestDeviceChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final deviceProvider = context.read<DeviceProvider>();

    final deviceId = deviceProvider.deviceId;
    if (deviceId == null) {
      _showError('Error al obtener identificador del dispositivo');
      setState(() => _isLoading = false);
      return;
    }

    // Aquí deberías tener un método en AuthProvider para solicitar cambio de dispositivo
    // que tome email y deviceId, y devuelva el requestId
    // Por ahora, simularemos el flujo

    // TODO: Implementar en AuthProvider:
    // final result = await authProvider.requestDeviceChangeByEmail(
    //   email: _emailController.text.trim(),
    //   newDeviceId: deviceId,
    // );

    setState(() => _isLoading = false);

    // Simulación de éxito
    setState(() {
      _requestSent = true;
      _requestId = 1; // Este debería venir del backend
    });
    _startCountdown();
    _showSuccess('Código enviado a tu email');
  }

  Future<void> _handleVerifyDeviceChange(String code) async {
    if (!_formKey.currentState!.validate()) return;
    if (_requestId == null) {
      _showError('Error: No se encontró la solicitud');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyDeviceChange(
      requestId: _requestId!,
      code: code,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        // Cambio de dispositivo exitoso, ir al home
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
        _showSuccess('Dispositivo cambiado correctamente');
      }
    } else {
      final error = authProvider.errorMessage;
      if (error != null) {
        _showError(error);
      }
    }
  }

  Future<void> _handleResendCode() async {
    if (_requestId == null) return;

    setState(() => _isLoading = true);

    // TODO: Implementar reenvío de código
    // final authProvider = context.read<AuthProvider>();
    // await authProvider.resendDeviceChangeCode(_requestId!);

    setState(() => _isLoading = false);

    _startCountdown();
    _showSuccess('Código reenviado. Revisa tu email.');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar Dispositivo'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl),

                // Icono
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.phonelink_lock_outlined,
                    size: 60,
                    color: AppColors.warning,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Título
                Text(
                  'Cambiar de dispositivo',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Descripción
                Text(
                  _requestSent
                      ? 'Ingresa el código que enviamos a tu email y tu contraseña para completar el cambio de dispositivo.'
                      : 'Esta cuenta está vinculada a otro dispositivo. Ingresa tu email y contraseña para cambiar de dispositivo.',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppSpacing.xxl),

                if (!_requestSent) ...[
                  // Formulario de solicitud
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'tu@email.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Botón de solicitar cambio
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleRequestDeviceChange,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Solicitar Cambio',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ] else ...[
                  // Formulario de verificación
                  CodeInputField(
                    onCompleted: _isLoading ? (_) {} : _handleVerifyDeviceChange,
                    length: 6,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Mostrar contraseña (ya ingresada)
                  Text(
                    'Confirma tu contraseña',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Loading indicator
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // Botón de reenviar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No recibiste el código?',
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (_canResend)
                        TextButton(
                          onPressed: _isLoading ? null : _handleResendCode,
                          child: const Text('Reenviar'),
                        )
                      else
                        Text(
                          'Reenviar en $_resendCountdown s',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Link para volver al login
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: const Text('Volver al inicio de sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
