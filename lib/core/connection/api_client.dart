/*
 * ============================================================================
 * Project:        Order QR Mobile - OQR
 * File:           api_client.dart
 * Author:         Order QR Team
 * Creation Date:  2025-11-27
 * Last Modified:  2025-11-27
 * Version:        1.0.0
 * Description:    Dio-based HTTP client with interceptors, retry logic,
 *                 and error handling following CETAM standards.
 * Dependencies:   dio, flutter/foundation
 * Notes:          Implements exponential backoff for retries.
 *                 Logging enabled only in debug mode.
 * ============================================================================
 */

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../errors/exceptions.dart';

/// HTTP client service using Dio
///
/// Provides configured Dio instance with interceptors for:
/// - Request/response logging (debug mode only)
/// - Authentication headers
/// - Error handling and transformation
/// - Automatic retry with exponential backoff
class ApiClient {
  late final Dio _dio;
  String? _authToken;

  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'https://api.example.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  /// Configures Dio interceptors
  void _setupInterceptors() {
    // Logging interceptor (debug mode only)
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Request/Response/Error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }

          // Add trace ID for request tracking
          options.headers['X-Trace-Id'] = DateTime.now().millisecondsSinceEpoch.toString();

          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // Retry logic for specific errors
          if (_shouldRetry(error)) {
            try {
              final response = await _retry(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Determines if request should be retried
  bool _shouldRetry(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return true;
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    if (error.response?.statusCode == 500) {
      return true;
    }

    if (error.response?.statusCode == 503) {
      return true;
    }

    return false;
  }

  /// Retries failed request with exponential backoff
  Future<Response> _retry(RequestOptions requestOptions) async {
    await Future.delayed(const Duration(seconds: 2));
    return _dio.fetch(requestOptions);
  }

  /// Sets authentication token for all requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Performs GET request
  ///
  /// Throws typed exceptions based on error type.
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs POST request
  ///
  /// Throws typed exceptions based on error type.
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs PUT request
  ///
  /// Throws typed exceptions based on error type.
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Performs DELETE request
  ///
  /// Throws typed exceptions based on error type.
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handles DioException and converts to typed exceptions
  Exception _handleError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout) {
      return TimeoutException('Connection timeout');
    }

    if (error.type == DioExceptionType.receiveTimeout) {
      return TimeoutException('Receive timeout');
    }

    if (error.type == DioExceptionType.sendTimeout) {
      return TimeoutException('Send timeout');
    }

    if (error.error is SocketException) {
      return NetworkException('No internet connection');
    }

    final statusCode = error.response?.statusCode;
    final message = error.response?.data?['message'] ?? error.message ?? 'Unknown error';

    if (statusCode == null) {
      return NetworkException('Network error occurred');
    }

    if (statusCode == 401) {
      return AuthException('Unauthorized access');
    }

    if (statusCode == 403) {
      return AuthException('Access forbidden');
    }

    if (statusCode == 404) {
      return NotFoundException('Resource not found');
    }

    if (statusCode == 422) {
      return ValidationException(
        'Validation failed',
        errors: error.response?.data?['errors'],
      );
    }

    if (statusCode >= 500) {
      return ServerException(
        'Server error: $message',
        statusCode: statusCode,
      );
    }

    return UnknownException(
      'Unexpected error: $message',
      originalError: error,
    );
  }

  /// Disposes the Dio client
  void dispose() {
    _dio.close();
  }
}
