import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/call_verification.dart';
import '../repositories/anti_masking_repository.dart';

/// Use case for verifying a call
class VerifyCall {
  final AntiMaskingRepository repository;

  VerifyCall(this.repository);

  Future<Either<Failure, CallVerification>> call(VerifyCallParams params) {
    return repository.verifyCall(
      callerNumber: params.callerNumber,
      calleeNumber: params.calleeNumber,
    );
  }
}

/// Parameters for verify call use case
class VerifyCallParams extends Equatable {
  final String callerNumber;
  final String calleeNumber;

  const VerifyCallParams({
    required this.callerNumber,
    required this.calleeNumber,
  });

  @override
  List<Object?> get props => [callerNumber, calleeNumber];
}
