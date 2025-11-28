import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionPlan {
  free,
  premium,
}

class SubscriptionProvider with ChangeNotifier {
  SubscriptionPlan _currentPlan = SubscriptionPlan.free;
  DateTime? _premiumExpiryDate;
  bool _isLoading = false;

  SubscriptionPlan get currentPlan => _currentPlan;
  bool get isPremium => _currentPlan == SubscriptionPlan.premium;
  bool get isFree => _currentPlan == SubscriptionPlan.free;
  DateTime? get premiumExpiryDate => _premiumExpiryDate;
  bool get isLoading => _isLoading;

  // Constantes
  static const double annualPremiumPrice = 100.0; // MXN
  static const String currency = 'MXN';

  SubscriptionProvider() {
    _loadSubscriptionStatus();
  }

  /// Cargar estado de suscripción desde almacenamiento local
  Future<void> _loadSubscriptionStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();

      final planString = prefs.getString('subscription_plan') ?? 'free';
      _currentPlan = planString == 'premium' ? SubscriptionPlan.premium : SubscriptionPlan.free;

      final expiryTimestamp = prefs.getInt('premium_expiry_date');
      if (expiryTimestamp != null) {
        _premiumExpiryDate = DateTime.fromMillisecondsSinceEpoch(expiryTimestamp);

        // Verificar si la suscripción premium ha expirado
        if (_premiumExpiryDate!.isBefore(DateTime.now())) {
          print('[WARN] Suscripción premium expirada');
          await _downgradeToPlan(SubscriptionPlan.free);
        }
      }

      print('Plan cargado: $_currentPlan');
      if (_premiumExpiryDate != null) {
        print('Fecha de expiración: $_premiumExpiryDate');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ERROR] Error al cargar estado de suscripción: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Activar plan premium (por ahora solo toggle, después integrará pagos)
  Future<void> activatePremium() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Por ahora, activar premium por 1 año
      final expiryDate = DateTime.now().add(const Duration(days: 365));

      await _savePlan(SubscriptionPlan.premium, expiryDate);

      _currentPlan = SubscriptionPlan.premium;
      _premiumExpiryDate = expiryDate;

      print('[OK] Plan Premium activado hasta: $expiryDate');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ERROR] Error al activar premium: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Desactivar plan premium (downgrade a free)
  Future<void> deactivatePremium() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _downgradeToPlan(SubscriptionPlan.free);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[ERROR] Error al desactivar premium: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Guardar plan en almacenamiento local
  Future<void> _savePlan(SubscriptionPlan plan, [DateTime? expiryDate]) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('subscription_plan', plan.name);

    if (expiryDate != null) {
      await prefs.setInt('premium_expiry_date', expiryDate.millisecondsSinceEpoch);
    } else {
      await prefs.remove('premium_expiry_date');
    }
  }

  /// Bajar a plan gratuito
  Future<void> _downgradeToPlan(SubscriptionPlan plan) async {
    _currentPlan = plan;
    _premiumExpiryDate = null;

    await _savePlan(plan);

    print('[DOWN] Plan cambiado a: $plan');
    notifyListeners();
  }

  /// Verificar si tiene acceso a una característica premium
  bool hasAccessTo(PremiumFeature feature) {
    if (isPremium) return true;

    // Todas las características premium requieren suscripción
    return false;
  }

  /// Obtener días restantes de premium
  int? getDaysRemaining() {
    if (_premiumExpiryDate == null || !isPremium) return null;

    final now = DateTime.now();
    if (_premiumExpiryDate!.isBefore(now)) return 0;

    return _premiumExpiryDate!.difference(now).inDays;
  }

  /// Obtener nombre del plan actual
  String getPlanName() {
    return isPremium ? 'Premium' : 'Gratis';
  }

  /// Obtener descripción del plan
  String getPlanDescription() {
    if (isPremium) {
      final daysRemaining = getDaysRemaining();
      if (daysRemaining != null && daysRemaining > 0) {
        return 'Activo - $daysRemaining días restantes';
      } else if (daysRemaining == 0) {
        return 'Expira hoy';
      }
      return 'Activo';
    }
    return 'Características limitadas';
  }
}

/// Características premium de la aplicación
enum PremiumFeature {
  allBusinesses, // Ver todos los negocios
  mapLargeRadius, // Mapa con radio > 10km
  advancedFilters, // Filtros avanzados (futuro)
  prioritySupport, // Soporte prioritario (futuro)
}
