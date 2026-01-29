import 'package:equatable/equatable.dart';

/// Base failure class for domain layer errors
abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server-side failures
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
  });
}

/// Network connectivity failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'No internet connection',
    super.code = 'NETWORK_ERROR',
  });
}

/// Cache/local storage failures
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Cache error',
    super.code = 'CACHE_ERROR',
  });
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
  });
}

/// Unauthorized access
class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure({
    super.message = 'Unauthorized access',
    super.code = 'UNAUTHORIZED',
  });
}

/// Session expired
class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure({
    super.message = 'Session expired. Please login again.',
    super.code = 'SESSION_EXPIRED',
  });
}

/// Validation failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? fieldErrors;

  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [message, code, fieldErrors];
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.code = 'NOT_FOUND',
  });
}

/// Rate limiting failures
class RateLimitFailure extends Failure {
  final Duration? retryAfter;

  const RateLimitFailure({
    super.message = 'Too many requests. Please try again later.',
    super.code = 'RATE_LIMIT',
    this.retryAfter,
  });

  @override
  List<Object?> get props => [message, code, retryAfter];
}

/// Permission denied failures
class PermissionFailure extends Failure {
  const PermissionFailure({
    required super.message,
    super.code = 'PERMISSION_DENIED',
  });
}

/// Timeout failures
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    super.message = 'Request timed out. Please try again.',
    super.code = 'TIMEOUT',
  });
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred',
    super.code = 'UNKNOWN_ERROR',
  });
}

/// Call masking specific failures
class MaskingDetectionFailure extends Failure {
  final double? confidenceScore;

  const MaskingDetectionFailure({
    required super.message,
    super.code = 'MASKING_DETECTED',
    this.confidenceScore,
  });

  @override
  List<Object?> get props => [message, code, confidenceScore];
}

/// Remittance specific failures
class RemittanceFailure extends Failure {
  final String? transactionId;

  const RemittanceFailure({
    required super.message,
    super.code = 'REMITTANCE_ERROR',
    this.transactionId,
  });

  @override
  List<Object?> get props => [message, code, transactionId];
}

/// Bank account verification failure
class BankVerificationFailure extends Failure {
  const BankVerificationFailure({
    super.message = 'Failed to verify bank account',
    super.code = 'BANK_VERIFICATION_ERROR',
  });
}
