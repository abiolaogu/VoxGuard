import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/call_verification.dart';
import '../repositories/anti_masking_repository.dart';

/// Use case for getting verification history
class GetVerificationHistory {
  final AntiMaskingRepository repository;

  GetVerificationHistory(this.repository);

  Future<Either<Failure, List<CallVerification>>> call(
    GetVerificationHistoryParams params,
  ) {
    return repository.getVerificationHistory(
      page: params.page,
      pageSize: params.pageSize,
      maskingOnly: params.maskingOnly,
    );
  }
}

/// Parameters for get verification history use case
class GetVerificationHistoryParams extends Equatable {
  final int page;
  final int pageSize;
  final bool? maskingOnly;

  const GetVerificationHistoryParams({
    this.page = 1,
    this.pageSize = 20,
    this.maskingOnly,
  });

  @override
  List<Object?> get props => [page, pageSize, maskingOnly];
}
