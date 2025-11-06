import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../models/mobile_user.dart';

class DeviceProvider extends ChangeNotifier {
  String? _deviceId;
  MobileUser? _mobileUser;
  bool _isInitialized = false;

  String? get deviceId => _deviceId;
  MobileUser? get mobileUser => _mobileUser;
  bool get isInitialized => _isInitialized;

  static const String _deviceIdKey = 'device_id';
  static const String _appVersion = '1.0.0';

  Future<void> initialize() async {
    try {
      // Obtener o generar device ID
      await _loadOrGenerateDeviceId();

      // Obtener información del dispositivo
      final deviceInfo = await _getDeviceInfo();

      // Configurar el device ID en el ApiService primero
      ApiService.setDeviceId(_deviceId!);

      // Intentar registrar dispositivo en el backend (modo offline-first)
      try {
        _mobileUser = await ApiService.registerDevice(
          deviceId: _deviceId!,
          fcmToken: null, // Se actualizará después con Firebase
          deviceType: Platform.isAndroid ? 'android' : 'ios',
          deviceModel: deviceInfo['model'],
          osVersion: deviceInfo['osVersion'],
          appVersion: _appVersion,
        );
        print('✅ Dispositivo registrado en el servidor: $_deviceId');
      } catch (e) {
        print('⚠️ No se pudo conectar al servidor: $e');
        print('📱 Continuando en modo offline con device ID: $_deviceId');
        // Continuar en modo offline sin lanzar excepción
      }

      _isInitialized = true;
      notifyListeners();

      print('✅ Dispositivo inicializado: $_deviceId');
    } catch (e) {
      print('❌ Error crítico al inicializar dispositivo: $e');
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadOrGenerateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);

    if (_deviceId == null) {
      // Generar nuevo UUID
      _deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
      print('📱 Nuevo device ID generado: $_deviceId');
    } else {
      print('📱 Device ID existente: $_deviceId');
    }
  }

  Future<Map<String, String?>> _getDeviceInfo() async {
    final deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return {
        'model': '${androidInfo.manufacturer} ${androidInfo.model}',
        'osVersion': 'Android ${androidInfo.version.release}',
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'model': iosInfo.model,
        'osVersion': 'iOS ${iosInfo.systemVersion}',
      };
    }

    return {
      'model': 'Unknown',
      'osVersion': 'Unknown',
    };
  }

  Future<void> clearDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    _deviceId = null;
    _mobileUser = null;
    _isInitialized = false;
    notifyListeners();
  }
}
