import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../widgets/app_drawer.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../models/business.dart';
import '../providers/subscription_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final LocationService _locationService = LocationService();
  List<Business> _nearbyBusinesses = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  double _currentRadius = 10.0; // km

  // Ubicación inicial (CDMX - Zócalo)
  static const LatLng _initialPosition = LatLng(19.432608, -99.133209);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Primero verificar permisos sin solicitarlos
      final permissionResult = await _locationService.checkAndRequestPermission();

      if (!permissionResult.isGranted) {
        // Mostrar diálogo según el tipo de error
        if (mounted) {
          await _handlePermissionDenied(permissionResult);
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Obtener ubicación del usuario
      final position = await _locationService.getCurrentPosition();

      if (position != null) {
        _currentPosition = position;

        // Agregar marcador del usuario
        _addUserMarker(position);

        // Cargar negocios cercanos
        await _loadNearbyBusinesses(
          position.latitude,
          position.longitude,
        );

        // Mover cámara a la ubicación del usuario
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'No se pudo obtener tu ubicación';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar el mapa: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePermissionDenied(dynamic permissionResult) async {
    final status = permissionResult.status;
    final message = permissionResult.message ?? 'No se pudo obtener acceso a la ubicación';

    if (status == LocationPermissionStatus.deniedForever) {
      // Permisos denegados permanentemente - mostrar diálogo para ir a configuración
      await _showPermissionDialog(
        title: 'Permisos de Ubicación Requeridos',
        message: message,
        actionText: 'Abrir Configuración',
        onAction: () async {
          await _locationService.openLocationSettings();
        },
      );
    } else if (status == LocationPermissionStatus.serviceDisabled) {
      // Servicios de ubicación deshabilitados
      await _showPermissionDialog(
        title: 'Servicios de Ubicación Deshabilitados',
        message: message,
        actionText: 'Abrir Configuración',
        onAction: () async {
          await _locationService.openLocationSettings();
        },
      );
    } else {
      // Permisos denegados temporalmente
      setState(() {
        _errorMessage = message;
      });
    }
  }

  Future<void> _showPermissionDialog({
    required String title,
    required String message,
    required String actionText,
    required VoidCallback onAction,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.location_off, color: AppColors.danger),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(title, style: AppTextStyles.h6)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.md),
            Text(
              '¿Por qué necesitamos tu ubicación?',
              style: AppTextStyles.h6.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildPermissionReason(
              Icons.store,
              'Mostrar negocios cercanos a ti',
            ),
            _buildPermissionReason(
              Icons.directions,
              'Calcular distancias y rutas',
            ),
            _buildPermissionReason(
              Icons.local_shipping,
              'Optimizar entregas y seguimiento',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Volver a la pantalla anterior
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onAction();
            },
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionReason(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNearbyBusinesses(double lat, double lng) async {
    try {
      print('Cargando negocios cercanos...');
      final businesses = await ApiService.getNearbyBusinesses(
        latitude: lat,
        longitude: lng,
        radius: _currentRadius,
      );

      print('Negocios recibidos: ${businesses.length}');

      setState(() {
        _nearbyBusinesses = businesses;
        _addBusinessMarkers(businesses);
        // Limpiar error si la carga fue exitosa
        if (_errorMessage != null && _errorMessage!.contains('negocios')) {
          _errorMessage = null;
        }
      });

      // Mostrar mensaje informativo si no hay negocios
      if (businesses.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se encontraron negocios en un radio de ${_currentRadius.toInt()} km'),
            action: SnackBarAction(
              label: 'Ampliar',
              onPressed: () {
                if (_currentRadius < 50) {
                  _changeRadius(_currentRadius + 10);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error al cargar negocios cercanos: $e');
      final errorMsg = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _errorMessage = 'No se pudieron cargar los negocios: $errorMsg';
      });

      // Mostrar snackbar con el error
      if (mounted) {
        // Detectar tipo de error
        final is404Error = errorMsg.contains('404') ||
            errorMsg.contains('no encontrado') ||
            errorMsg.contains('Recurso no encontrado');

        final is500Error = errorMsg.contains('500') || errorMsg.contains('Error del servidor');

        String? helpText;
        if (is404Error) {
          helpText = 'El endpoint /businesses/nearby no está implementado en el backend';
        } else if (is500Error) {
          helpText = 'Error interno del servidor. Revisa SOLUCION_ERROR_500.md';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Error: $errorMsg'),
                if (helpText != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    helpText,
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _loadNearbyBusinesses(lat, lng),
            ),
          ),
        );
      }
    }
  }

  void _addUserMarker(Position position) {
    final marker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(position.latitude, position.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: const InfoWindow(
        title: 'Tu ubicación',
        snippet: 'Estás aquí',
      ),
    );

    setState(() {
      _markers.add(marker);
    });
  }

  void _addBusinessMarkers(List<Business> businesses) {
    setState(() {
      // Limpiar marcadores anteriores (excepto el del usuario)
      _markers.removeWhere((marker) => marker.markerId.value != 'user_location');

      // Agregar marcadores de negocios
      for (var business in businesses) {
        if (business.hasLocation) {
          final marker = Marker(
            markerId: MarkerId('business_${business.businessId}'),
            position: LatLng(business.latitude!, business.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: business.businessName,
              snippet: business.distanceKm != null
                  ? '${business.distanceKm!.toStringAsFixed(1)} km'
                  : business.address ?? '',
            ),
            onTap: () => _showBusinessDetails(business),
          );

          _markers.add(marker);
        }
      }
    });
  }

  void _showBusinessDetails(Business business) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              business.businessName,
              style: AppTextStyles.h5,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (business.distanceKm != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${business.distanceKm!.toStringAsFixed(1)} km de distancia',
                    style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            if (business.address != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.place, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      business.address!,
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ],
            if (business.phone != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    business.phone!,
                    style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
            if (business.rating != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '${business.rating!.toStringAsFixed(1)} / 5.0',
                    style: AppTextStyles.body2,
                  ),
                  if (business.totalReviews != null)
                    Text(
                      ' (${business.totalReviews} reseñas)',
                      style: AppTextStyles.body2.copyWith(color: AppColors.textMuted),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _changeRadius(double newRadius) {
    setState(() {
      _currentRadius = newRadius;
    });

    if (_currentPosition != null) {
      _loadNearbyBusinesses(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Negocios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _initializeMap,
            tooltip: 'Centrar en mi ubicación',
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/map'),
      body: Stack(
        children: [
          // Mapa
          _isLoading && _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Obteniendo tu ubicación...',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                        : _initialPosition,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  mapType: MapType.normal,
                  // Configuración para mapa limpio sin distracciones
                  buildingsEnabled: false, // Sin edificios 3D
                  trafficEnabled: false, // Sin tráfico
                  indoorViewEnabled: false, // Sin vista interior
                  compassEnabled: true, // Mantener brújula
                  mapToolbarEnabled: false, // Sin toolbar de Google Maps
                  zoomControlsEnabled: false, // Sin controles de zoom (usar gestos)
                  rotateGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: false, // Sin inclinación
                  zoomGesturesEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _setMapStyle(controller);
                  },
                ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: AppColors.danger,
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Panel de información
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_nearbyBusinesses.length} negocios cercanos',
                          style: AppTextStyles.h6,
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.radar, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('Radio: ${_currentRadius.toInt()} km'),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showRadiusSelector(),
                          child: const Text('Cambiar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRadiusSelector() {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final hasPremium = subscriptionProvider.hasAccessTo(PremiumFeature.mapLargeRadius);
    double tempRadius = _currentRadius;

    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('Selecciona el radio de búsqueda', style: AppTextStyles.h6),
                  if (!hasPremium) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.workspace_premium,
                      size: 18,
                      color: AppColors.warning,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Slider(
                value: tempRadius,
                min: 1,
                max: 50,
                divisions: 49,
                label: '${tempRadius.toInt()} km',
                onChanged: (value) {
                  // Si no tiene premium, limitar a 10 km
                  if (!hasPremium && value > 10) {
                    setModalState(() {
                      tempRadius = 10;
                    });
                    return;
                  }
                  setModalState(() {
                    tempRadius = value;
                  });
                },
              ),
              Text('${tempRadius.toInt()} kilómetros'),
              if (!hasPremium && tempRadius > 10) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Radio limitado a 10 km en plan gratuito',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (!hasPremium) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Con Premium puedes usar hasta 50 km',
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            try {
                              await subscriptionProvider.activatePremium();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Plan Premium activado'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.danger,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.upgrade, size: 16),
                          label: const Text('Activar Premium', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Validar que no exceda 10km sin premium
                    if (!hasPremium && tempRadius > 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El plan gratuito está limitado a 10 km'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      tempRadius = 10;
                    }
                    Navigator.pop(context);
                    _changeRadius(tempRadius);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Aplica un estilo minimalista al mapa
  /// Oculta: POI, negocios, etiquetas de tránsito, etc.
  /// Solo muestra: calles, parques, agua, y tus marcadores personalizados
  void _setMapStyle(GoogleMapController controller) {
    const String mapStyle = '''
[
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.business",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.attraction",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.government",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.medical",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.place_of_worship",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.school",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "poi.sports_complex",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [{"visibility": "off"}]
  },
  {
    "featureType": "transit.station",
    "stylers": [{"visibility": "off"}]
  }
]
''';

    controller.setMapStyle(mapStyle);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
