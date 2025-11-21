import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/auth/biometric_button.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometría';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final biometricService = BiometricService();
    final available = await biometricService.isAvailable();
    if (available) {
      final type = await biometricService.getBiometricTypeName();
      setState(() {
        _biometricAvailable = available;
        _biometricType = type;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final deviceProvider = context.read<DeviceProvider>();
    final authProvider = context.read<AuthProvider>();

    final deviceId = deviceProvider.deviceId;
    if (deviceId == null) {
      _showError('Error al obtener identificador del dispositivo');
      setState(() => _isLoading = false);
      return;
    }

    final success = await authProvider.loginWithGoogle(deviceId);

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      final error = authProvider.errorMessage;
      if (error != null) {
        if (authProvider.status == AuthStatus.deviceChangePending) {
          _showDeviceChangeDialog();
        } else {
          _showError(error);
        }
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.loginWithBiometric();

    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } else {
      _showError('No se pudo autenticar con $_biometricType');
    }
  }

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl * 2),

              // Logo o título
              Icon(
                Icons.qr_code_scanner,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Order QR',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Inicia sesión con tu cuenta de Google',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxl * 2),

              // Botón de Google
              GoogleSignInButton(
                onPressed: _handleGoogleSignIn,
                isLoading: _isLoading,
              ),

              // Botón de biometría (si está disponible)
              if (_biometricAvailable) ...[
                const SizedBox(height: AppSpacing.xxl),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Text(
                        'O usa',
                        style: AppTextStyles.caption,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Column(
                    children: [
                      BiometricButton(
                        onPressed: _handleBiometricLogin,
                        biometricType: _biometricType,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Usar $_biometricType',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl * 2),

              // Información adicional
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Al iniciar sesión, aceptas nuestros términos de servicio y política de privacidad.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
