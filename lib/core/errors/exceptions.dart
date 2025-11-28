/*
 * ============================================================================
 * Project:        Order QR Mobile - OQR
 * File:           exceptions.dart
 * Author:         Order QR Team
 * Creation Date:  2025-11-27
 * Last Modified:  2025-11-27
 * Version:        1.0.0
 * Description:    Custom exception classes for application error handling.
 *                 Provides typed exceptions for different error scenarios.
 * Dependencies:   None
 * Notes:          All exceptions extend base Exception class.
 * ============================================================================
 */

/// Base exception for server-related errors
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception thrown when network connectivity is unavailable
class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when requested resource is not found
class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Exception thrown for validation errors
class ValidationException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;

  ValidationException(this.message, {this.errors});

  @override
  String toString() => 'ValidationException: $message';
}

/// Generic exception for unexpected errors
class UnknownException implements Exception {
  final String message;
  final dynamic originalError;

  UnknownException(this.message, {this.originalError});

  @override
  String toString() => 'UnknownException: $message';
}

/// Exception thrown when operation times out
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}
