import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationPermissionResult {
  final LocationPermissionStatus status;
  final String? message;

  LocationPermissionResult({
    required this.status,
    this.message,
  });

  bool get isGranted => status == LocationPermissionStatus.granted;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Verificar si los servicios de ubicación están habilitados
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Verificar el estado actual de los permisos sin solicitarlos
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Verificar y solicitar permisos de ubicación con resultado detallado
  Future<LocationPermissionResult> checkAndRequestPermission() async {
    // Primero verificar si el servicio de ubicación está habilitado
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Servicios de ubicación deshabilitados');
      return LocationPermissionResult(
        status: LocationPermissionStatus.serviceDisabled,
        message:
            'Los servicios de ubicación están deshabilitados. Por favor, actívalos en la configuración de tu dispositivo.',
      );
    }

    // Verificar permisos actuales
    LocationPermission permission = await Geolocator.checkPermission();

    // Si ya están concedidos, retornar éxito
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      print('Permisos de ubicación ya concedidos');
      return LocationPermissionResult(
        status: LocationPermissionStatus.granted,
      );
    }

    // Si están denegados permanentemente, no podemos solicitarlos
    if (permission == LocationPermission.deniedForever) {
      print('Permisos de ubicación denegados permanentemente');
      return LocationPermissionResult(
        status: LocationPermissionStatus.deniedForever,
        message:
            'Los permisos de ubicación han sido denegados permanentemente. Por favor, actívalos manualmente en la configuración de la aplicación.',
      );
    }

    // Solicitar permisos
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      print('Permisos de ubicación denegados');
      return LocationPermissionResult(
        status: LocationPermissionStatus.denied,
        message: 'Necesitamos acceso a tu ubicación para mostrar negocios cercanos.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      print('Permisos de ubicación denegados permanentemente');
      return LocationPermissionResult(
        status: LocationPermissionStatus.deniedForever,
        message:
            'Los permisos de ubicación han sido denegados permanentemente. Por favor, actívalos manualmente en la configuración de la aplicación.',
      );
    }

    print('Permisos de ubicación concedidos');
    return LocationPermissionResult(
      status: LocationPermissionStatus.granted,
    );
  }

  /// Obtener la ubicación actual del usuario
  Future<Position?> getCurrentPosition() async {
    try {
      // Verificar y solicitar permisos
      final permissionResult = await checkAndRequestPermission();
      if (!permissionResult.isGranted) {
        print('No se puede obtener ubicación: ${permissionResult.message}');
        return null;
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('Ubicación actual: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error al obtener ubicación: $e');
      return null;
    }
  }

  /// Obtener stream de actualizaciones de ubicación
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calcular distancia entre dos puntos (en kilómetros)
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000; // Convertir metros a kilómetros
  }

  /// Abrir configuración de ubicación del dispositivo
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Obtener última ubicación conocida (más rápido pero puede ser desactualizada)
  Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('No se pudo obtener última ubicación conocida: $e');
      return null;
    }
  }
}
