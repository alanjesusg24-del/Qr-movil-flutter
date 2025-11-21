class AuthUser {
  final int userId;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final String? googleId;
  final bool emailVerified;
  final String? currentDeviceId;
  final DateTime? deviceLinkedAt;
  final DateTime createdAt;

  AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    this.googleId,
    required this.emailVerified,
    this.currentDeviceId,
    this.deviceLinkedAt,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['user_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      profilePhotoUrl: json['profile_photo_url'],
      googleId: json['google_id'],
      emailVerified: json['email_verified'] ?? (json['email_verified_at'] != null),
      currentDeviceId: json['current_device_id'],
      deviceLinkedAt: json['device_linked_at'] != null
          ? DateTime.parse(json['device_linked_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'profile_photo_url': profilePhotoUrl,
      'google_id': googleId,
      'email_verified': emailVerified,
      'current_device_id': currentDeviceId,
      'device_linked_at': deviceLinkedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isDeviceLinked => currentDeviceId != null;
  bool get isGoogleUser => googleId != null;

  AuthUser copyWith({
    int? userId,
    String? name,
    String? email,
    String? profilePhotoUrl,
    String? googleId,
    bool? emailVerified,
    String? currentDeviceId,
    DateTime? deviceLinkedAt,
    DateTime? createdAt,
  }) {
    return AuthUser(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      googleId: googleId ?? this.googleId,
      emailVerified: emailVerified ?? this.emailVerified,
      currentDeviceId: currentDeviceId ?? this.currentDeviceId,
      deviceLinkedAt: deviceLinkedAt ?? this.deviceLinkedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
