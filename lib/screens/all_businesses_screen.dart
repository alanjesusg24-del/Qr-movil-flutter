import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/business.dart';
import '../services/api_service.dart';
import '../widgets/business_card.dart';
import '../widgets/app_drawer.dart';
import '../providers/subscription_provider.dart';

class AllBusinessesScreen extends StatefulWidget {
  const AllBusinessesScreen({super.key});

  @override
  State<AllBusinessesScreen> createState() => _AllBusinessesScreenState();
}

class _AllBusinessesScreenState extends State<AllBusinessesScreen> {
  List<Business> _allBusinesses = [];
  List<Business> _filteredBusinesses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filtros
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCity;
  String? _selectedState;
  bool _onlyWithLocation = false;

  // Listas únicas para filtros
  List<String> _cities = [];
  List<String> _states = [];

  @override
  void initState() {
    super.initState();
    _loadAllBusinesses();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBusinesses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📋 Cargando todos los negocios...');
      final businesses = await ApiService.getAllBusinesses();

      setState(() {
        _allBusinesses = businesses;
        _filteredBusinesses = businesses;
        _isLoading = false;

        // Extraer ciudades y estados únicos
        _cities = businesses.where((b) => b.city != null && b.city!.isNotEmpty).map((b) => b.city!).toSet().toList()
          ..sort();

        _states = businesses.where((b) => b.state != null && b.state!.isNotEmpty).map((b) => b.state!).toSet().toList()
          ..sort();
      });

      print('${businesses.length} negocios cargados');
      print('Ciudades encontradas: ${_cities.length}');
      print('Estados encontrados: ${_states.length}');
    } catch (e) {
      print('Error al cargar negocios: $e');
      setState(() {
        _errorMessage = 'Error al cargar negocios:\n$e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredBusinesses = _allBusinesses.where((business) {
        // Filtro de búsqueda por nombre
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            business.businessName.toLowerCase().contains(searchTerm) ||
            (business.address?.toLowerCase().contains(searchTerm) ?? false);

        // Filtro por ciudad
        final matchesCity = _selectedCity == null || business.city == _selectedCity;

        // Filtro por estado
        final matchesState = _selectedState == null || business.state == _selectedState;

        // Filtro por ubicación
        final matchesLocation = !_onlyWithLocation || business.hasLocation;

        return matchesSearch && matchesCity && matchesState && matchesLocation;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCity = null;
      _selectedState = null;
      _onlyWithLocation = false;
      _filteredBusinesses = _allBusinesses;
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final hasPremium = subscriptionProvider.hasAccessTo(PremiumFeature.allBusinesses);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Todos los Negocios'),
            if (!hasPremium) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.workspace_premium,
                size: 20,
                color: AppColors.warning,
              ),
            ],
          ],
        ),
        elevation: 2,
        actions: hasPremium
            ? [
                // Botón de filtros
                IconButton(
                  icon: Icon(
                    _hasActiveFilters() ? Icons.filter_alt : Icons.filter_alt_outlined,
                    color: _hasActiveFilters() ? AppColors.warning : Colors.white,
                  ),
                  tooltip: 'Filtros',
                  onPressed: _showFiltersDialog,
                ),
                // Botón de refrescar
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                  onPressed: _loadAllBusinesses,
                ),
              ]
            : null,
      ),
      drawer: const AppDrawer(currentRoute: '/all-businesses'),
      body: hasPremium
          ? RefreshIndicator(
              onRefresh: _loadAllBusinesses,
              child: _buildBody(),
            )
          : _buildPremiumRequired(context, subscriptionProvider),
    );
  }

  bool _hasActiveFilters() {
    return _searchController.text.isNotEmpty || _selectedCity != null || _selectedState != null || _onlyWithLocation;
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
              'Cargando negocios...',
              style: TextStyle(fontSize: 16),
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
                onPressed: _loadAllBusinesses,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_allBusinesses.isEmpty) {
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
              'No hay negocios registrados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Barra de búsqueda
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o dirección...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
        ),

        // Indicador de filtros activos
        if (_hasActiveFilters())
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            color: AppColors.primary.withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.filter_alt, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getActiveFiltersText(),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),

        // Header con información
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            border: Border(
              bottom: BorderSide(color: AppColors.gray300),
            ),
          ),
          child: Text(
            _filteredBusinesses.length == _allBusinesses.length
                ? '${_allBusinesses.length} negocios registrados'
                : '${_filteredBusinesses.length} de ${_allBusinesses.length} negocios',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Lista de negocios
        Expanded(
          child: _filteredBusinesses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No se encontraron negocios\ncon los filtros aplicados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpiar filtros'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredBusinesses.length,
                  itemBuilder: (context, index) {
                    final business = _filteredBusinesses[index];
                    return BusinessCard(
                      business: business,
                      onTap: () {
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

  String _getActiveFiltersText() {
    final filters = <String>[];

    if (_selectedCity != null) {
      filters.add('Ciudad: $_selectedCity');
    }
    if (_selectedState != null) {
      filters.add('Estado: $_selectedState');
    }
    if (_onlyWithLocation) {
      filters.add('Con ubicación');
    }
    if (_searchController.text.isNotEmpty) {
      filters.add('Búsqueda: "${_searchController.text}"');
    }

    return filters.join(' • ');
  }

  Widget _buildPremiumRequired(
    BuildContext context,
    SubscriptionProvider subscriptionProvider,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícono premium
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                size: 80,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Título
            Text(
              'Función Premium',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),

            // Descripción
            Text(
              'Esta función está disponible solo para usuarios Premium',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Características premium
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.textMuted.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Con Premium tendrás acceso a:',
                    style: AppTextStyles.body2.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPremiumFeature(
                    icon: Icons.business,
                    title: 'Todos los Negocios',
                    description: 'Explora el listado completo de negocios',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPremiumFeature(
                    icon: Icons.map,
                    title: 'Mapa Extendido',
                    description: 'Radio de búsqueda mayor a 10 km',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Precio
            Text(
              '\$${SubscriptionProvider.annualPremiumPrice} ${SubscriptionProvider.currency}/año',
              style: AppTextStyles.h5.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Botón de activar premium
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: subscriptionProvider.isLoading
                    ? null
                    : () async {
                        try {
                          await subscriptionProvider.activatePremium();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Plan Premium activado exitosamente'),
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
                icon: subscriptionProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upgrade),
                label: const Text('Activar Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_alt, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text('Filtros', style: AppTextStyles.h5),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedCity = null;
                          _selectedState = null;
                          _onlyWithLocation = false;
                        });
                        setState(() {
                          _selectedCity = null;
                          _selectedState = null;
                          _onlyWithLocation = false;
                          _applyFilters();
                        });
                      },
                      child: const Text('Limpiar todo'),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: AppSpacing.md),

                // Filtro por ciudad
                Text('Ciudad', style: AppTextStyles.h6.copyWith(fontSize: 14)),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    hintText: 'Todas las ciudades',
                    prefixIcon: Icon(Icons.location_city, size: 20),
                  ),
                  items: _cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedCity = value);
                    setState(() {
                      _selectedCity = value;
                      _applyFilters();
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Filtro por estado
                Text('Estado', style: AppTextStyles.h6.copyWith(fontSize: 14)),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: _selectedState,
                  decoration: const InputDecoration(
                    hintText: 'Todos los estados',
                    prefixIcon: Icon(Icons.map, size: 20),
                  ),
                  items: _states.map((state) {
                    return DropdownMenuItem(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setModalState(() => _selectedState = value);
                    setState(() {
                      _selectedState = value;
                      _applyFilters();
                    });
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                // Filtro por ubicación
                CheckboxListTile(
                  title: const Text('Solo negocios con ubicación GPS'),
                  subtitle: const Text('Mostrar solo negocios mapeables'),
                  value: _onlyWithLocation,
                  onChanged: (value) {
                    setModalState(() => _onlyWithLocation = value ?? false);
                    setState(() {
                      _onlyWithLocation = value ?? false;
                      _applyFilters();
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),

                const SizedBox(height: AppSpacing.md),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Aplicar filtros'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
