import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/business_card.dart';
import '../widgets/app_drawer.dart';

class NearbyBusinessesScreen extends StatefulWidget {
  const NearbyBusinessesScreen({super.key});

  @override
  State<NearbyBusinessesScreen> createState() => _NearbyBusinessesScreenState();
}

class _NearbyBusinessesScreenState extends State<NearbyBusinessesScreen> {
  final LocationService _locationService = LocationService();

  List<Business> _businesses = [];
  Position? _currentPosition;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedRadius = 10; // km

  @override
  void initState() {
    super.initState();
    _loadNearbyBusinesses();
  }

  Future<void> _loadNearbyBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtener ubicación actual
      print('Solicitando ubicación del usuario...');
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        setState(() {
          _errorMessage = 'No se pudo obtener tu ubicación.\n'
              'Por favor, habilita los permisos de ubicación en la configuración.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      print('Consultando negocios cercanos en radio de $_selectedRadius km...');

      // 2. Obtener negocios cercanos
      final businesses = await ApiService.getNearbyBusinesses(
        latitude: position.latitude,
        longitude: position.longitude,
        radius: _selectedRadius.toDouble(),
      );

      print('Respuesta recibida: ${businesses.length} negocios');

      setState(() {
        _businesses = businesses;
        _isLoading = false;
      });

      if (_businesses.isEmpty) {
        setState(() {
          _errorMessage = 'No hay negocios en un radio de $_selectedRadius km.\n'
              'Intenta ampliar el radio de búsqueda.';
        });
      }
    } catch (e) {
      print('Error al cargar negocios: $e');
      setState(() {
        _errorMessage = 'Error al cargar negocios:\n$e\n\n'
            'Verifica tu conexión a internet y que el servidor esté activo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Negocios Cercanos'),
        elevation: 2,
        actions: [
          // Selector de radio
          PopupMenuButton<int>(
            icon: const Icon(Icons.tune),
            tooltip: 'Cambiar radio de búsqueda',
            onSelected: (value) {
              setState(() {
                _selectedRadius = value;
              });
              _loadNearbyBusinesses();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.location_searching, size: 20),
                    SizedBox(width: 12),
                    Text('1 km'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 5,
                child: Row(
                  children: [
                    Icon(Icons.location_searching, size: 20),
                    SizedBox(width: 12),
                    Text('5 km'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 10,
                child: Row(
                  children: [
                    Icon(Icons.location_searching, size: 20),
                    SizedBox(width: 12),
                    Text('10 km'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 20,
                child: Row(
                  children: [
                    Icon(Icons.location_searching, size: 20),
                    SizedBox(width: 12),
                    Text('20 km'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 50,
                child: Row(
                  children: [
                    Icon(Icons.location_searching, size: 20),
                    SizedBox(width: 12),
                    Text('50 km'),
                  ],
                ),
              ),
            ],
          ),
          // Botón de refrescar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _loadNearbyBusinesses,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/nearby-businesses'),
      body: RefreshIndicator(
        onRefresh: _loadNearbyBusinesses,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Obteniendo tu ubicación...',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Buscando negocios cercanos...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.orange[700],
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadNearbyBusinesses,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay negocios en un radio de $_selectedRadius km',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedRadius = 50;
                });
                _loadNearbyBusinesses();
              },
              icon: const Icon(Icons.zoom_out_map),
              label: const Text('Ampliar radio a 50 km'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con información
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_businesses.length} negocios en $_selectedRadius km',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (_currentPosition != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GPS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Lista de negocios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _businesses.length,
            itemBuilder: (context, index) {
              final business = _businesses[index];
              return BusinessCard(
                business: business,
                onTap: () {
                  // Navegar a detalle (implementar después)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Seleccionado: ${business.businessName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
