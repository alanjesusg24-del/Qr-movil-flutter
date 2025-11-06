import 'package:permission_handler/permission_handler.dart';

class QrService {
  static final QrService instance = QrService._privateConstructor();
  QrService._privateConstructor();

  // Validar formato de QR token
  bool isValidQrToken(String qrData) {
    // El formato esperado es: https://app.example.com/order/scan/{qr_token}
    // El token debe tener 32 caracteres alfanuméricos

    final RegExp urlPattern = RegExp(
      r'^https?://[^/]+/order/scan/([a-zA-Z0-9]{32})$',
      caseSensitive: false,
    );

    return urlPattern.hasMatch(qrData);
  }

  // Extraer token del QR
  String? extractTokenFromQr(String qrData) {
    final RegExp urlPattern = RegExp(
      r'^https?://[^/]+/order/scan/([a-zA-Z0-9]{32})$',
      caseSensitive: false,
    );

    final match = urlPattern.firstMatch(qrData);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  // Solicitar permisos de cámara
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // El usuario negó permanentemente el permiso
      // Mostrar diálogo para ir a configuración
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Verificar si el permiso de cámara está concedido
  Future<bool> isCameraPermissionGranted() async {
    return await Permission.camera.isGranted;
  }
}
