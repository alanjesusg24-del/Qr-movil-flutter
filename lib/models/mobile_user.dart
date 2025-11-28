class MobileUser {
  final int mobileUserId;
  final String deviceId;
  final String? fcmToken;
  final String deviceType;
  final String? deviceModel;
  final String? osVersion;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveAt;

  MobileUser({
    required this.mobileUserId,
    required this.deviceId,
    this.fcmToken,
    required this.deviceType,
    this.deviceModel,
    this.osVersion,
    this.appVersion,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveAt,
  });

  factory MobileUser.fromJson(Map<String, dynamic> json) {
    return MobileUser(
      mobileUserId: json['mobile_user_id'] as int,
      deviceId: json['device_id'] as String,
      fcmToken: json['fcm_token'] as String?,
      deviceType: json['device_type'] as String,
      deviceModel: json['device_model'] as String?,
      osVersion: json['os_version'] as String?,
      appVersion: json['app_version'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastActiveAt: json['last_active_at'] != null ? DateTime.parse(json['last_active_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mobile_user_id': mobileUserId,
      'device_id': deviceId,
      'fcm_token': fcmToken,
      'device_type': deviceType,
      'device_model': deviceModel,
      'os_version': osVersion,
      'app_version': appVersion,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }
}
