import 'package:dio/dio.dart';

// =============================================================================
// DEVELOPER-FACING: ApiException (for logging and debugging)
// =============================================================================

/// API exception holding all technical details. Use [UserErrorMapper] to get
/// a safe, user-facing message. Do not show [message], [errorCode], or [rawError]
/// directly to users.
class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.rawError,
    this.errors,
  });

  /// Backend or internal message (for logs). Not for end users.
  final String message;

  /// HTTP status code when available.
  final int? statusCode;

  /// Backend error code (e.g. "PRODUCT_ALREADY_IN_WISHLIST"). For logging only.
  final String? errorCode;

  /// Full response body (for debugging). For logging only.
  final dynamic rawError;

  /// Laravel-style validation errors (field → list of messages). For 422.
  final Map<String, dynamic>? errors;

  /// Use this for logging: includes status, code, and message.
  String get logMessage =>
      'ApiException(statusCode: $statusCode, errorCode: $errorCode, message: $message)';

  @override
  String toString() => logMessage;
}

// =============================================================================
// USER-FACING: UserErrorMapper (friendly, non-technical messages only)
// =============================================================================

/// Converts [ApiException] into a single, user-friendly message. Use this
/// for SnackBars, dialogs, and any UI. Never expose [ApiException.message]
/// or [rawError] to users.
class UserErrorMapper {
  UserErrorMapper._();

  /// Returns a safe, friendly message for the given [ApiException].
  /// Validation errors (422) are combined into one readable line without field names.
  static String toUserMessage(ApiException e) {
    // Known backend error codes → fixed friendly messages
    final byCode = _messageByErrorCode(e.errorCode, e.statusCode);
    if (byCode != null) return byCode;

    // Fallback by HTTP status
    switch (e.statusCode) {
      case 400:
        return 'Invalid request. Please try again.';
      case 401:
        return 'Incorrect email or password.';
      case 403:
        return 'You don\'t have permission to do that.';
      case 404:
        return 'We couldn\'t find what you\'re looking for.';
      case 409:
        return 'This item is already in your wishlist.';
      case 422:
        return _userMessageFromValidation(e.errors);
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 500:
        return 'Something went wrong. Please try again later.';
    }

    // Network/connection (no status or unknown)
    if (e.statusCode == null) {
      return 'Please check your internet connection.';
    }
    return 'Something went wrong. Please try again later.';
  }

  /// Map known backend [errorCode] (and optional [statusCode]) to user message.
  static String? _messageByErrorCode(String? errorCode, int? statusCode) {
    if (errorCode == null || errorCode.isEmpty) return null;
    switch (errorCode.toUpperCase()) {
      case 'PRODUCT ALREADY IN_WISHLIST':
        return 'This item is already in your wishlist.';
      case 'UNAUTHENTICATED':
      case 'UNAUTHORIZED':
        return 'Incorrect email or password.';
      case 'VALIDATION_ERROR':
        return null; // Handled via 422 + errors
      default:
        return null;
    }
  }

  /// Build one friendly message from 422 validation errors; no field names.
  static String _userMessageFromValidation(Map<String, dynamic>? errors) {
    if (errors == null || errors.isEmpty) {
      return 'Please check the information you entered and try again.';
    }
    final list = <String>[];
    for (final entry in errors.entries) {
      final value = entry.value;
      if (value is List) {
        for (final item in value) {
          final s = item?.toString().trim();
          if (s != null && s.isNotEmpty) list.add(_sanitizeValidationMessage(s));
        }
      }
    }
    if (list.isEmpty) {
      return 'Please check the information you entered and try again.';
    }
    // Single message → return as is (sanitized); multiple → one combined line
    if (list.length == 1) return list.first;
    return 'Please check the information you entered and try again.';
  }

  /// Strip field names and technical wording from a single validation message.
  static String _sanitizeValidationMessage(String s) {
    // "The email field is required" → "Please enter your email."
    final lower = s.toLowerCase();
    if (lower.contains('required')) {
      if (lower.contains('email')) return 'Please enter your email.';
      if (lower.contains('password')) return 'Please enter your password.';
      if (lower.contains('name')) return 'Please enter your name.';
      return 'This field is required.';
    }
    if (lower.contains('invalid')) return 'Please enter a valid value.';
    if (lower.contains('must be')) return 'Please check the value you entered.';
    return s;
  }
}

// =============================================================================
// GLOBAL HANDLER: ApiErrorHandler (DioException → ApiException)
// =============================================================================

/// Converts [DioException] into [ApiException] with full developer data.
/// UI should use [UserErrorMapper.toUserMessage] on the thrown [ApiException].
class ApiErrorHandler {
  ApiErrorHandler._();

  static Never handle(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Network / timeout (no response)
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.unknown) {
      throw ApiException(
        message: 'Network/connection error',
        statusCode: statusCode,
        rawError: data,
      );
    }

    final message = _extractMessage(data);
    final errorCode = _extractCode(data);
    final errors = _extractErrors(data);

    switch (statusCode) {
      case 400:
        throw ApiException(
          message: message ?? 'Bad request',
          statusCode: 400,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 401:
        throw ApiException(
          message: message ?? 'Unauthorized',
          statusCode: 401,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 403:
        throw ApiException(
          message: message ?? 'Forbidden',
          statusCode: 403,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 404:
        throw ApiException(
          message: message ?? 'Not found',
          statusCode: 404,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 409:
        throw ApiException(
          message: message ?? 'Conflict',
          statusCode: 409,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 422:
        throw ApiException(
          message: message ?? 'Validation failed',
          statusCode: 422,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 429:
        throw ApiException(
          message: message ?? 'Too many requests',
          statusCode: 429,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
      case 500:
        throw ApiException(
          message: message ?? 'Server error',
          statusCode: 500,
          errorCode: errorCode,
          rawError: data,
          errors: errors,
        );
    }

    throw ApiException(
      message: message ?? 'Request failed',
      statusCode: statusCode,
      errorCode: errorCode,
      rawError: data,
      errors: errors,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final msg = data['message'];
      return msg?.toString().trim();
    }
    return null;
  }

  static String? _extractCode(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final code = data['code'];
      return code?.toString().trim();
    }
    return null;
  }

  static Map<String, dynamic>? _extractErrors(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final err = data['errors'];
      if (err is Map<String, dynamic>) return err;
      if (err is Map) return Map<String, dynamic>.from(err);
    }
    if (data is Map && data['errors'] != null) {
      final err = data['errors'];
      if (err is Map) return Map<String, dynamic>.from(err);
    }
    return null;
  }
}
