# 🐛 Solución al Error: FormatException: invalid double null

## 📋 Descripción del Error

```
FormatException: invalid double null
```

Este error ocurre cuando Flutter intenta convertir un valor `null` a `double` usando `double.parse()`.

---

## 🔍 Causa del Problema

En el modelo `Order` o `OrderItem`, hay campos numéricos que pueden ser `null` pero están siendo parseados directamente:

```dart
// ❌ PROBLEMA: Si total_amount es null, esto falla
totalAmount: double.parse(json['total_amount'].toString()),

// ❌ PROBLEMA: Si unit_price es null, esto falla
unitPrice: double.parse(json['unit_price'].toString()),
```

---

## ✅ Solución Completa

### 1. Actualizar el modelo `Order`

Reemplaza el método `fromJson` en tu modelo `Order`:

```dart
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

    // ✅ CORRECTO: Manejar null en total_amount
    totalAmount: _parseDouble(json['total_amount']),

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

// ✅ Método auxiliar para parsear doubles de forma segura
static double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? 0.0;
  }
  return 0.0;
}
```

---

### 2. Actualizar el modelo `OrderItem`

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
      quantity: _parseInt(json['quantity']),

      // ✅ CORRECTO: Parseo seguro de doubles
      unitPrice: _parseDouble(json['unit_price']),
      totalPrice: _parseDouble(json['total_price']),

      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // ✅ Método auxiliar para parsear doubles de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }

  // ✅ Método auxiliar para parsear integers de forma segura
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? 0;
    }
    return 0;
  }
}
```

---

### 3. Alternativa: Usar extensión global

Crea un archivo `lib/utils/json_helpers.dart`:

```dart
/// Helpers para parsear JSON de forma segura
class JsonHelpers {
  /// Parsea un valor a double de forma segura
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parsea un valor a int de forma segura
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Parsea un valor a DateTime de forma segura
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parseando DateTime: $value');
        return null;
      }
    }
    return null;
  }

  /// Parsea una lista de forma segura
  static List<T> parseList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (value == null) return [];
    if (value is! List) return [];

    return value
        .where((item) => item != null)
        .map((item) {
          try {
            return fromJson(item as Map<String, dynamic>);
          } catch (e) {
            print('Error parseando item de lista: $e');
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }
}
```

Luego úsalo en tus modelos:

```dart
import 'package:tu_app/utils/json_helpers.dart';

factory Order.fromJson(Map<String, dynamic> json) {
  return Order(
    orderId: JsonHelpers.parseInt(json['order_id']),
    orderNumber: json['order_number'] as String,
    businessId: JsonHelpers.parseInt(json['business_id']),
    customerName: json['customer_name'] as String?,
    customerPhone: json['customer_phone'] as String?,
    customerEmail: json['customer_email'] as String?,
    folioNumber: json['folio_number'] as String,
    description: json['description'] as String?,

    // ✅ Uso de helper
    totalAmount: JsonHelpers.parseDouble(json['total_amount']),

    qrCodeUrl: json['qr_code_url'] as String,
    qrToken: json['qr_token'] as String,
    pickupToken: json['pickup_token'] as String,
    status: json['status'] as String,
    mobileUserId: JsonHelpers.parseInt(json['mobile_user_id']),

    // ✅ DateTime con helper
    associatedAt: JsonHelpers.parseDateTime(json['associated_at']),
    readyAt: JsonHelpers.parseDateTime(json['ready_at']),
    deliveredAt: JsonHelpers.parseDateTime(json['delivered_at']),
    cancelledAt: JsonHelpers.parseDateTime(json['cancelled_at']),
    cancellationReason: json['cancellation_reason'] as String?,

    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),

    // ✅ Lista con helper
    items: JsonHelpers.parseList<OrderItem>(
      json['items'],
      OrderItem.fromJson,
    ),
    statusHistory: JsonHelpers.parseList<OrderStatusHistory>(
      json['status_history'],
      OrderStatusHistory.fromJson,
    ),
  );
}
```

---

## 🧪 Debugging

Si quieres ver exactamente qué valor está causando el problema, agrega esto temporalmente:

```dart
factory Order.fromJson(Map<String, dynamic> json) {
  print('🔍 Parseando Order:');
  print('  total_amount raw: ${json['total_amount']} (${json['total_amount'].runtimeType})');

  try {
    return Order(
      // ... resto del código
      totalAmount: _parseDouble(json['total_amount']),
      // ...
    );
  } catch (e, stackTrace) {
    print('❌ Error parseando Order: $e');
    print('📋 JSON completo: $json');
    print('📍 Stack trace: $stackTrace');
    rethrow;
  }
}
```

---

## 📊 Valores del Backend

El backend Laravel devuelve `total_amount` como string:

```json
{
  "total_amount": "85.00"
}
```

Pero podría ser:
- String: `"85.00"` ✅
- Number: `85.0` ✅
- Null: `null` ❌ (causa el error)

Por eso necesitamos el parseo seguro.

---

## ✅ Checklist de Solución

- [ ] Crear archivo `lib/utils/json_helpers.dart` con los helpers
- [ ] Actualizar `Order.fromJson()` para usar `JsonHelpers.parseDouble()`
- [ ] Actualizar `OrderItem.fromJson()` para usar los helpers
- [ ] Probar escaneando un QR
- [ ] Si hay error, activar los prints de debugging
- [ ] Revisar la consola para ver qué valor está null

---

## 🎯 Resumen

El problema es que Flutter no puede convertir `null` a `double` directamente. La solución es:

1. ✅ Usar `double.tryParse()` en lugar de `double.parse()`
2. ✅ Proporcionar un valor por defecto (0.0) cuando sea null
3. ✅ Validar el tipo antes de parsear
4. ✅ Usar helpers reutilizables para todos los modelos

---

## 🚀 Después de Aplicar los Cambios

1. **Hot restart** (no solo hot reload)
2. Escanea el QR de nuevo
3. Revisa la consola si hay más errores
4. Los prints te mostrarán exactamente qué está pasando

---

**Creado:** 2025-11-06
**Error:** FormatException: invalid double null
**Solución:** Parseo seguro de tipos numéricos
