import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import '../config/theme.dart';
import '../providers/orders_provider.dart';
import '../services/qr_service.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!isProcessing && scanData.code != null) {
        _handleQrCode(scanData.code!);
      }
    });
  }

  Future<void> _handleQrCode(String qrData) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    controller?.pauseCamera();

    // Validar formato de QR
    if (!QrService.instance.isValidQrToken(qrData)) {
      _showErrorDialog('Código QR inválido', 'Este código no es válido para el sistema.');
      setState(() {
        isProcessing = false;
      });
      controller?.resumeCamera();
      return;
    }

    // Extraer token
    final token = QrService.instance.extractTokenFromQr(qrData);
    if (token == null) {
      _showErrorDialog('Error', 'No se pudo extraer el token del código QR.');
      setState(() {
        isProcessing = false;
      });
      controller?.resumeCamera();
      return;
    }

    // Asociar orden
    try {
      final ordersProvider = context.read<OrdersProvider>();
      final order = await ordersProvider.associateOrder(token);

      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Orden ${order.folioNumber} asociada exitosamente'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navegar al detalle de la orden
        Navigator.pushReplacementNamed(
          context,
          '/order-detail',
          arguments: {'orderId': order.orderId},
        );
      }
    } catch (e) {
      _showErrorDialog('Error al Asociar Orden', e.toString());
      setState(() {
        isProcessing = false;
      });
      controller?.resumeCamera();
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: AppColors.primary,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: AppColors.cardBackground,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isProcessing)
                    const CircularProgressIndicator()
                  else ...[
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Coloca el código QR dentro del marco',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
