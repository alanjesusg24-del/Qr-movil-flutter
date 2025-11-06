import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class OrdersProvider extends ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Order> get activeOrders =>
      _orders.where((o) => o.status == 'pending' || o.status == 'ready').toList();

  List<Order> get pendingOrders =>
      _orders.where((o) => o.status == 'pending').toList();

  List<Order> get readyOrders =>
      _orders.where((o) => o.status == 'ready').toList();

  List<Order> get deliveredOrders =>
      _orders.where((o) => o.status == 'delivered').toList();

  List<Order> get cancelledOrders =>
      _orders.where((o) => o.status == 'cancelled').toList();

  int get activeOrdersCount => activeOrders.length;
  int get readyOrdersCount => readyOrders.length;
  int get totalOrdersCount => _orders.length;

  // Cargar órdenes desde la base de datos local
  Future<void> loadLocalOrders() async {
    try {
      _orders = await DatabaseService.instance.getAllOrders();
      notifyListeners();
      print('📦 ${_orders.length} órdenes cargadas desde DB local');
    } catch (e) {
      print('❌ Error al cargar órdenes locales: $e');
    }
  }

  // Obtener órdenes desde el servidor
  Future<void> fetchOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedOrders = await ApiService.getOrders(status: status);
      _orders = fetchedOrders;

      // Guardar en base de datos local
      await DatabaseService.instance.syncOrders(_orders);

      _isLoading = false;
      notifyListeners();
      print('✅ ${_orders.length} órdenes obtenidas del servidor');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Error al obtener órdenes: $e');

      // Cargar desde base de datos local si falla
      await loadLocalOrders();
    }
  }

  // Asociar orden con el dispositivo
  Future<Order> associateOrder(String qrToken) async {
    try {
      final order = await ApiService.associateOrder(qrToken);

      // Agregar al inicio de la lista
      _orders.insert(0, order);

      // Guardar en base de datos local
      await DatabaseService.instance.insertOrder(order);

      notifyListeners();
      print('✅ Orden ${order.folioNumber} asociada exitosamente');
      return order;
    } catch (e) {
      print('❌ Error al asociar orden: $e');
      rethrow;
    }
  }

  // Obtener detalle de orden
  Future<Order> getOrderDetail(int orderId) async {
    try {
      final order = await ApiService.getOrderDetail(orderId);

      // Actualizar en la lista
      final index = _orders.indexWhere((o) => o.orderId == orderId);
      if (index != -1) {
        _orders[index] = order;
        notifyListeners();
      }

      // Actualizar en base de datos local
      await DatabaseService.instance.updateOrder(order);

      return order;
    } catch (e) {
      print('❌ Error al obtener detalle de orden: $e');
      rethrow;
    }
  }

  // Actualizar orden individual
  Future<void> refreshOrder(int orderId) async {
    try {
      await getOrderDetail(orderId);
      print('🔄 Orden $orderId actualizada');
    } catch (e) {
      print('❌ Error al actualizar orden $orderId: $e');
    }
  }

  // Filtrar órdenes por estado
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((o) => o.status == status).toList();
  }

  // Obtener orden por ID desde la lista local
  Order? getOrderById(int orderId) {
    try {
      return _orders.firstWhere((o) => o.orderId == orderId);
    } catch (e) {
      return null;
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Limpiar todas las órdenes
  Future<void> clearAllOrders() async {
    await DatabaseService.instance.deleteAllOrders();
    _orders = [];
    notifyListeners();
    print('🗑️ Todas las órdenes eliminadas');
  }
}
