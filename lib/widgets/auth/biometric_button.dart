import 'package:flutter/material.dart';

class BiometricButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String biometricType;

  const BiometricButton({
    super.key,
    required this.onPressed,
    this.biometricType = 'Biometría',
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (biometricType.contains('Face')) {
      icon = Icons.face;
    } else if (biometricType.contains('Huella')) {
      icon = Icons.fingerprint;
    } else {
      icon = Icons.security;
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 32),
      color: Theme.of(context).primaryColor,
      tooltip: 'Iniciar sesión con $biometricType',
    );
  }
}
