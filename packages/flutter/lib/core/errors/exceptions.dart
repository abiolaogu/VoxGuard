/// Base exception class for data layer errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

/// Server exception for HTTP errors
class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });

  factory ServerException.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ServerException(
          message: message ?? 'Bad request',
          code: 'BAD_REQUEST',
          statusCode: statusCode,
        );
      case 401:
        return ServerException(
          message: message ?? 'Unauthorized',
          code: 'UNAUTHORIZED',
          statusCode: statusCode,
        );
      case 403:
        return ServerException(
          message: message ?? 'Forbidden',
          code: 'FORBIDDEN',
          statusCode: statusCode,
        );
      case 404:
        return ServerException(
          message: message ?? 'Not found',
          code: 'NOT_FOUND',
          statusCode: statusCode,
        );
      case 429:
        return ServerException(
          message: message ?? 'Too many requests',
          code: 'RATE_LIMIT',
          statusCode: statusCode,
        );
      case 500:
        return ServerException(
          message: message ?? 'Internal server error',
          code: 'INTERNAL_ERROR',
          statusCode: statusCode,
        );
      case 502:
        return ServerException(
          message: message ?? 'Bad gateway',
          code: 'BAD_GATEWAY',
          statusCode: statusCode,
        );
      case 503:
        return ServerException(
          message: message ?? 'Service unavailable',
          code: 'SERVICE_UNAVAILABLE',
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: message ?? 'Server error',
          code: 'SERVER_ERROR',
          statusCode: statusCode,
        );
    }
  }
}

/// Network exception for connectivity issues
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
    super.originalError,
  });
}

/// Cache exception for local storage issues
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error',
    super.code = 'CACHE_ERROR',
    super.originalError,
  });
}

/// GraphQL exception for query/mutation errors
class GraphQLException extends AppException {
  final List<String>? errors;

  const GraphQLException({
    required super.message,
    super.code = 'GRAPHQL_ERROR',
    super.originalError,
    this.errors,
  });

  factory GraphQLException.fromErrors(List<dynamic> errors) {
    final messages = errors.map((e) => e.toString()).toList();
    return GraphQLException(
      message: messages.isNotEmpty ? messages.first : 'GraphQL error',
      errors: messages,
    );
  }
}

/// Validation exception for invalid input
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.originalError,
    this.fieldErrors,
  });
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.originalError,
  });
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException({
    super.message = 'Request timed out',
    super.code = 'TIMEOUT',
    super.originalError,
  });
}

/// Format exception for parsing errors
class FormatException extends AppException {
  const FormatException({
    super.message = 'Invalid format',
    super.code = 'FORMAT_ERROR',
    super.originalError,
  });
}
