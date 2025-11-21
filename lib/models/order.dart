import '../utils/json_helpers.dart';
import 'business.dart';

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
      id: JsonHelpers.parseInt(json['id']),
      orderId: JsonHelpers.parseInt(json['order_id']),
      itemName: json['item_name'] as String,
      description: json['description'] as String?,
      quantity: JsonHelpers.parseInt(json['quantity']),
      unitPrice: JsonHelpers.parseDouble(json['unit_price']),
      totalPrice: JsonHelpers.parseDouble(json['total_price']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'item_name': itemName,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice.toString(),
      'total_price': totalPrice.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

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
      id: JsonHelpers.parseInt(json['id']),
      orderId: JsonHelpers.parseInt(json['order_id']),
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String,
      notes: json['notes'] as String?,
      changedBy: json['changed_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'notes': notes,
      'changed_by': changedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Order {
  final int orderId;
  final String orderNumber;
  final int businessId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final String folioNumber;
  final String? description;
  final double totalAmount;
  final String qrCodeUrl;
  final String qrToken;
  final String pickupToken;
  final String status;
  final int? mobileUserId;
  final DateTime? associatedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;
  final int unreadMessagesCount;
  final bool hasUnreadMessages;
  final Business? business;

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
    this.unreadMessagesCount = 0,
    this.hasUnreadMessages = false,
    this.business,
  });

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
      totalAmount: JsonHelpers.parseDouble(json['total_amount']),
      qrCodeUrl: json['qr_code_url'] as String,
      qrToken: json['qr_token'] as String,
      pickupToken: json['pickup_token'] as String,
      status: json['status'] as String,
      mobileUserId: json['mobile_user_id'] as int?,
      associatedAt: JsonHelpers.parseDateTime(json['associated_at']),
      readyAt: JsonHelpers.parseDateTime(json['ready_at']),
      deliveredAt: JsonHelpers.parseDateTime(json['delivered_at']),
      cancelledAt: JsonHelpers.parseDateTime(json['cancelled_at']),
      cancellationReason: json['cancellation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: JsonHelpers.parseList<OrderItem>(
        json['items'],
        OrderItem.fromJson,
      ),
      statusHistory: JsonHelpers.parseList<OrderStatusHistory>(
        json['status_history'],
        OrderStatusHistory.fromJson,
      ),
      unreadMessagesCount: json['unread_messages_count'] ?? 0,
      hasUnreadMessages: json['has_unread_messages'] ?? false,
      business: json['business'] != null ? Business.fromJson(json['business']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'order_number': orderNumber,
      'business_id': businessId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'folio_number': folioNumber,
      'description': description,
      'total_amount': totalAmount.toString(),
      'qr_code_url': qrCodeUrl,
      'qr_token': qrToken,
      'pickup_token': pickupToken,
      'status': status,
      'mobile_user_id': mobileUserId,
      'associated_at': associatedAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'status_history': statusHistory.map((history) => history.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'order_number': orderNumber,
      'business_id': businessId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'folio_number': folioNumber,
      'description': description,
      'total_amount': totalAmount.toString(),
      'qr_code_url': qrCodeUrl,
      'qr_token': qrToken,
      'pickup_token': pickupToken,
      'status': status,
      'mobile_user_id': mobileUserId,
      'associated_at': associatedAt?.toIso8601String(),
      'ready_at': readyAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      orderId: JsonHelpers.parseInt(map['order_id']),
      orderNumber: map['order_number'] as String,
      businessId: JsonHelpers.parseInt(map['business_id']),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      customerEmail: map['customer_email'] as String?,
      folioNumber: map['folio_number'] as String,
      description: map['description'] as String?,
      totalAmount: JsonHelpers.parseDouble(map['total_amount']),
      qrCodeUrl: map['qr_code_url'] as String,
      qrToken: map['qr_token'] as String,
      pickupToken: map['pickup_token'] as String,
      status: map['status'] as String,
      mobileUserId: map['mobile_user_id'] as int?,
      associatedAt: JsonHelpers.parseDateTime(map['associated_at']),
      readyAt: JsonHelpers.parseDateTime(map['ready_at']),
      deliveredAt: JsonHelpers.parseDateTime(map['delivered_at']),
      cancelledAt: JsonHelpers.parseDateTime(map['cancelled_at']),
      cancellationReason: map['cancellation_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      items: [],
      statusHistory: [],
    );
  }

  bool get isActive => status == 'pending' || status == 'ready';
}
