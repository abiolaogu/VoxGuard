import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/call_verification.dart';

/// Anti-masking repository interface
abstract class AntiMaskingRepository {
  /// Verify a call for masking
  Future<Either<Failure, CallVerification>> verifyCall({
    required String callerNumber,
    required String calleeNumber,
  });

  /// Get verification history
  Future<Either<Failure, List<CallVerification>>> getVerificationHistory({
    int page = 1,
    int pageSize = 20,
    bool? maskingOnly,
  });

  /// Get a specific verification by ID
  Future<Either<Failure, CallVerification>> getVerification(String id);

  /// Report masking to NCC
  Future<Either<Failure, bool>> reportMasking({
    required String verificationId,
    required String description,
    String? additionalNotes,
  });

  /// Get fraud alerts
  Future<Either<Failure, List<FraudAlert>>> getFraudAlerts({
    int page = 1,
    int pageSize = 20,
    AlertStatus? status,
    AlertSeverity? minSeverity,
  });

  /// Acknowledge a fraud alert
  Future<Either<Failure, FraudAlert>> acknowledgeAlert(String alertId);

  /// Resolve a fraud alert
  Future<Either<Failure, FraudAlert>> resolveAlert({
    required String alertId,
    required String resolution,
  });

  /// Stream of new fraud alerts (real-time)
  Stream<FraudAlert> watchFraudAlerts();

  /// Stream of new verifications (real-time)
  Stream<CallVerification> watchVerifications();
}
