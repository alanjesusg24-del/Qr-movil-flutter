class DeviceChangeRequest {
  final int requestId;
  final String? oldDeviceId;
  final String newDeviceId;
  final DateTime expiresAt;
  final String status;

  DeviceChangeRequest({
    required this.requestId,
    this.oldDeviceId,
    required this.newDeviceId,
    required this.expiresAt,
    required this.status,
  });

  factory DeviceChangeRequest.fromJson(Map<String, dynamic> json) {
    return DeviceChangeRequest(
      requestId: json['request_id'] ?? json['id'],
      oldDeviceId: json['old_device_id'],
      newDeviceId: json['new_device_id'],
      expiresAt: DateTime.parse(json['expires_at']),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'old_device_id': oldDeviceId,
      'new_device_id': newDeviceId,
      'expires_at': expiresAt.toIso8601String(),
      'status': status,
    };
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
  bool get isPending => status == 'pending';
  bool get isVerified => status == 'verified';

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
}
