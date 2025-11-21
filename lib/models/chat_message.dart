class ChatMessage {
  final int messageId;
  final String senderType;
  final String message;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.messageId,
    required this.senderType,
    required this.message,
    this.attachmentUrl,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'] as int,
      senderType: json['sender_type'] as String,
      message: json['message'] as String,
      attachmentUrl: json['attachment_url'] as String?,
      isRead: _parseBool(json['is_read']),
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }

  /// Helper para parsear bool que puede venir como int (0/1), bool o null
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'sender_type': senderType,
      'message': message,
      'attachment_url': attachmentUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  bool get isFromBusiness => senderType == 'business';
  bool get isFromCustomer => senderType == 'customer';
}
