# 🐛 Solución al Error: type 'null' is not a subtype of type 'Map<String, dynamic>'

## 📋 Descripción del Error

La app Flutter está lanzando el error:
```
Error al asociar order: type 'null' is not a subtype of type 'Map<String, dynamic>' in type cast
```

Esto ocurre cuando se escanea un código QR y se intenta asociar una orden.

---

## 🔍 Causa del Problema

El backend Laravel está devolviendo la respuesta en este formato:

```json
{
  "success": true,
  "message": "Order associated successfully",
  "data": {
    "order_id": 2,
    "order_number": "ORD-2025-001",
    "customer_name": "Juan Pérez",
    "items": [...],
    "status_history": []
  }
}
```

**PERO** la app Flutter probablemente está esperando:

```json
{
  "success": true,
  "data": {
    "order": {
      "order_id": 2,
      ...
    }
  }
}
```

O está intentando acceder a un campo que puede ser `null`.

---

## ✅ Solución en Flutter

### 1. Verifica el método `associateOrder` o similar

Busca en tu código Flutter el método que hace la petición POST a `/mobile/orders/associate`.

**Archivo probable:** `lib/services/order_service.dart` o `lib/repositories/order_repository.dart`

**Código actual (INCORRECTO):**
```dart
Future<Order> associateOrder(String qrToken) async {
  final response = await http.post(
    Uri.parse('$baseUrl/mobile/orders/associate'),
    headers: {
      'Content-Type': 'application/json',
      'X-Device-ID': deviceId,
    },
    body: json.encode({'qr_token': qrToken}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    // ❌ PROBLEMA: Está intentando acceder a data['order']
    return Order.fromJson(data['data']['order']);

    // O peor aún:
    // ❌ PROBLEMA: data['data'] podría ser null
    return Order.fromJson(data['data']);
  }
  throw Exception('Error al asociar orden');
}
```

**Código CORRECTO:**
```dart
Future<Order> associateOrder(String qrToken) async {
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/mobile/orders/associate'),
      headers: {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      },
      body: json.encode({'qr_token': qrToken}),
    );

    final Map<String, dynamic> responseData = json.decode(response.body);

    // Verificar que la petición fue exitosa
    if (response.statusCode == 200 && responseData['success'] == true) {
      // ✅ CORRECTO: Acceder directamente a data
      final orderData = responseData['data'];

      // Verificación adicional de seguridad
      if (orderData == null) {
        throw Exception('No se recibieron datos de la orden');
      }

      return Order.fromJson(orderData);
    } else {
      // Manejar errores del backend
      final message = responseData['message'] ?? 'Error desconocido';
      throw Exception(message);
    }
  } catch (e) {
    print('Error en associateOrder: $e');
    throw Exception('Error al asociar orden: $e');
  }
}
```

---

### 2. Verifica el modelo `Order`

**Archivo:** `lib/models/order.dart` o `lib/models/order_model.dart`

Asegúrate de que el modelo maneje correctamente los campos que pueden ser `null`:

```dart
class Order {
  final int orderId;
  final String orderNumber;
  final int businessId;
  final String? customerName;      // ← Puede ser null
  final String? customerPhone;     // ← Puede ser null
  final String? customerEmail;     // ← Puede ser null
  final String folioNumber;
  final String? description;       // ← Puede ser null
  final double totalAmount;
  final String qrCodeUrl;
  final String qrToken;
  final String pickupToken;
  final String status;
  final int? mobileUserId;         // ← Puede ser null
  final DateTime? associatedAt;    // ← Puede ser null
  final DateTime? readyAt;         // ← Puede ser null
  final DateTime? deliveredAt;     // ← Puede ser null
  final DateTime? cancelledAt;     // ← Puede ser null
  final String? cancellationReason; // ← Puede ser null
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;

  Order({
    required this.orderId,
    required this.orderNumber,
    required this.businessId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.folioNumber,
    this.description,
    required this.totalAmount,
    required this.qrCodeUrl,
    required this.qrToken,
    required this.pickupToken,
    required this.status,
    this.mobileUserId,
    this.associatedAt,
    this.readyAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
    required this.statusHistory,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] as int,
      orderNumber: json['order_number'] as String,
      businessId: json['business_id'] as int,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerEmail: json['customer_email'] as String?,
      folioNumber: json['folio_number'] as String,
      description: json['description'] as String?,
      totalAmount: double.parse(json['total_amount'].toString()),
      qrCodeUrl: json['qr_code_url'] as String,
      qrToken: json['qr_token'] as String,
      pickupToken: json['pickup_token'] as String,
      status: json['status'] as String,
      mobileUserId: json['mobile_user_id'] as int?,
      associatedAt: json['associated_at'] != null
          ? DateTime.parse(json['associated_at'])
          : null,
      readyAt: json['ready_at'] != null
          ? DateTime.parse(json['ready_at'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'])
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'])
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      statusHistory: (json['status_history'] as List<dynamic>?)
              ?.map((history) => OrderStatusHistory.fromJson(history))
              .toList() ??
          [],
    );
  }
}
```

---

### 3. Modelo OrderItem

```dart
class OrderItem {
  final int id;
  final int orderId;
  final String itemName;
  final String? description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.itemName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      itemName: json['item_name'] as String,
      description: json['description'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: double.parse(json['unit_price'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
```

---

### 4. Modelo OrderStatusHistory

```dart
class OrderStatusHistory {
  final int id;
  final int orderId;
  final String? oldStatus;
  final String newStatus;
  final String? notes;
  final String? changedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderStatusHistory({
    required this.id,
    required this.orderId,
    this.oldStatus,
    required this.newStatus,
    this.notes,
    this.changedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String,
      notes: json['notes'] as String?,
      changedBy: json['changed_by'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
```

---

## 🧪 Cómo Probar

### 1. Agregar logs para debugging

En el método `associateOrder`, agrega prints:

```dart
Future<Order> associateOrder(String qrToken) async {
  try {
    print('🔍 Enviando petición con token: $qrToken');

    final response = await http.post(
      Uri.parse('$baseUrl/mobile/orders/associate'),
      headers: {
        'Content-Type': 'application/json',
        'X-Device-ID': deviceId,
      },
      body: json.encode({'qr_token': qrToken}),
    );

    print('📥 Status code: ${response.statusCode}');
    print('📥 Response body: ${response.body}');

    final Map<String, dynamic> responseData = json.decode(response.body);

    print('✅ Success: ${responseData['success']}');
    print('📦 Data: ${responseData['data']}');

    if (response.statusCode == 200 && responseData['success'] == true) {
      final orderData = responseData['data'];

      if (orderData == null) {
        print('❌ orderData es null!');
        throw Exception('No se recibieron datos de la orden');
      }

      print('✅ Creando Order desde JSON...');
      return Order.fromJson(orderData);
    } else {
      final message = responseData['message'] ?? 'Error desconocido';
      print('❌ Error del backend: $message');
      throw Exception(message);
    }
  } catch (e, stackTrace) {
    print('❌ Error en associateOrder: $e');
    print('📍 Stack trace: $stackTrace');
    throw Exception('Error al asociar orden: $e');
  }
}
```

---

## 📡 Respuesta del Backend

El backend Laravel está devolviendo exactamente esto:

```json
{
  "success": true,
  "message": "Order associated successfully",
  "data": {
    "order_id": 2,
    "order_number": "ORD-2025-001",
    "business_id": 1,
    "customer_name": "Juan Pérez",
    "customer_phone": "+52 555 1234567",
    "customer_email": "juan@example.com",
    "folio_number": "TEST-001",
    "description": "Café americano grande + croissant",
    "total_amount": "85.00",
    "qr_code_url": "https://api.qrserver.com/v1/create-qr-code/?data=TEST001&size=300x300",
    "qr_token": "8hNhwLErGSjuv2bOBaaYQT1D7vnNKvIM",
    "pickup_token": "f8jKYJVgq1xGU9tC",
    "status": "pending",
    "mobile_user_id": 2,
    "associated_at": "2025-11-06T16:02:38.000000Z",
    "ready_at": null,
    "delivered_at": null,
    "cancelled_at": null,
    "cancellation_reason": null,
    "created_at": "2025-11-06T15:31:42.000000Z",
    "updated_at": "2025-11-06T16:02:38.000000Z",
    "deleted_at": null,
    "items": [
      {
        "id": 1,
        "order_id": 2,
        "item_name": "Producto de ejemplo",
        "description": "Descripción del producto",
        "quantity": 2,
        "unit_price": "42.50",
        "total_price": "85.00",
        "created_at": "2025-11-06T15:31:42.000000Z",
        "updated_at": "2025-11-06T15:31:42.000000Z"
      }
    ],
    "status_history": []
  }
}
```

---

## 🎯 Resumen de Cambios Necesarios

1. ✅ **Acceder a `data` directamente**, no a `data['order']`
2. ✅ **Manejar todos los campos nullable** con `?` en el modelo
3. ✅ **Validar que `data` no sea null** antes de parsear
4. ✅ **Agregar try-catch** robusto con logs
5. ✅ **Manejar arrays vacíos** para `items` y `status_history`

---

## 🚀 Después de Aplicar los Cambios

1. **Hot reload** o reinicia la app
2. Escanea uno de los QR codes
3. Revisa la consola/logs para ver qué está pasando
4. Si hay más errores, los logs te dirán exactamente dónde

---

## 📞 Información del Backend

- **Base URL:** `http://192.168.1.66:8000/api/v1`
- **Endpoint:** `POST /mobile/orders/associate`
- **Headers requeridos:**
  - `Content-Type: application/json`
  - `X-Device-ID: {tu-device-uuid}`
- **Body:** `{"qr_token": "TOKEN_AQUI"}`

---

## 🔧 Tokens QR de Prueba

Si necesitas tokens para testing manual:

```dart
// Token 1 - Juan Pérez - $85.00 - pending
'8hNhwLErGSjuv2bOBaaYQT1D7vnNKvIM'

// Token 2 - María García - $120.00 - ready
'vVfqJlD0c39OVm6bUGoCYasZKcQulkZt'

// Token 3 - Cliente Nuevo - $0.00 - pending
'tYYfspYrFoClwUaoo0lHmUUVLT8ZClYp'
```

---

**Creado:** 2025-11-06
**Backend Version:** Laravel 10.x
**API Version:** 1.0.0
