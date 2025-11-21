import 'auth_user.dart';

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final AuthUser? user;
  final bool requiresEmailVerification;
  final bool requiresDeviceChange;
  final int? userId;
  final int? requestId;
  final DateTime? expiresAt;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.user,
    this.requiresEmailVerification = false,
    this.requiresDeviceChange = false,
    this.userId,
    this.requestId,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['token'],
      user: json['user'] != null ? AuthUser.fromJson(json['user']) : null,
      requiresEmailVerification: json['requires_email_verification'] ?? false,
      requiresDeviceChange: json['requires_device_change'] ?? false,
      userId: json['user_id'],
      requestId: json['request_id'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }
}
