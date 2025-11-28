/*
 * ============================================================================
 * Project:        Order QR Mobile - OQR
 * File:           business.dart
 * Author:         Order QR Team
 * Creation Date:  2025-11-27
 * Last Modified:  2025-11-27
 * Version:        1.0.0
 * Description:    Business model representing a business entity with location,
 *                 rating, and operational details.
 * Dependencies:   None
 * Notes:          Extended model with geolocation and rating features.
 * ============================================================================
 */

/// Represents a business entity in the Order QR system.
///
/// This class contains all business information including basic details,
/// location data, ratings, and operational status.
///
/// Example:
/// ```dart
/// final business = Business(
///   businessId: 1,
///   businessName: 'Pizza Palace',
///   phone: '555-1234',
///   address: '123 Main St',
///   city: 'Springfield',
///   state: 'IL',
/// );
/// ```
class Business {
  final int businessId;
  final String businessName;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? addressDetails;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? totalReviews;
  final double? distanceKm;
  final bool? isOpen;
  final bool hasLocation;

  Business({
    required this.businessId,
    required this.businessName,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.addressDetails,
    this.latitude,
    this.longitude,
    this.rating,
    this.totalReviews,
    this.distanceKm,
    this.isOpen,
    bool? hasLocation,
  }) : hasLocation = hasLocation ?? (latitude != null && longitude != null);

  /// Creates a [Business] instance from a JSON map.
  ///
  /// Throws [FormatException] if required fields are missing or invalid.
  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      businessId: json['business_id'] as int,
      businessName: json['business_name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      addressDetails: json['address_details'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      totalReviews: json['total_reviews'] as int?,
      distanceKm: json['distance_km'] != null ? (json['distance_km'] as num).toDouble() : null,
      isOpen: json['is_open'] as bool?,
      hasLocation: json['has_location'] as bool?,
    );
  }

  /// Converts this [Business] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'business_id': businessId,
      'business_name': businessName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'address_details': addressDetails,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'total_reviews': totalReviews,
      'distance_km': distanceKm,
      'is_open': isOpen,
      'has_location': hasLocation,
    };
  }

  /// Converts this [Business] instance to a Map for database storage.
  Map<String, dynamic> toMap() {
    return {
      'business_id': businessId,
      'business_name': businessName,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'address_details': addressDetails,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'total_reviews': totalReviews,
      'distance_km': distanceKm,
      'is_open': isOpen,
      'has_location': hasLocation ? 1 : 0,
    };
  }

  /// Creates a [Business] instance from a database Map.
  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      businessId: map['business_id'] as int,
      businessName: map['business_name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      addressDetails: map['address_details'] as String?,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      rating: map['rating'] != null ? (map['rating'] as num).toDouble() : null,
      totalReviews: map['total_reviews'] as int?,
      distanceKm: map['distance_km'] != null ? (map['distance_km'] as num).toDouble() : null,
      isOpen: map['is_open'] != null ? (map['is_open'] as int) == 1 : null,
      hasLocation: map['has_location'] != null ? (map['has_location'] as int) == 1 : null,
    );
  }

  /// Creates a copy of this [Business] with optional field updates.
  Business copyWith({
    int? businessId,
    String? businessName,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? addressDetails,
    double? latitude,
    double? longitude,
    double? rating,
    int? totalReviews,
    double? distanceKm,
    bool? isOpen,
    bool? hasLocation,
  }) {
    return Business(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      addressDetails: addressDetails ?? this.addressDetails,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      distanceKm: distanceKm ?? this.distanceKm,
      isOpen: isOpen ?? this.isOpen,
      hasLocation: hasLocation ?? this.hasLocation,
    );
  }
}
