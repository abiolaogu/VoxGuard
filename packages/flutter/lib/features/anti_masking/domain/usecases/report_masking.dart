import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/anti_masking_repository.dart';

/// Use case for reporting masking to NCC
class ReportMasking {
  final AntiMaskingRepository repository;

  ReportMasking(this.repository);

  Future<Either<Failure, bool>> call(ReportMaskingParams params) {
    return repository.reportMasking(
      verificationId: params.verificationId,
      description: params.description,
      additionalNotes: params.additionalNotes,
    );
  }
}

/// Parameters for report masking use case
class ReportMaskingParams extends Equatable {
  final String verificationId;
  final String description;
  final String? additionalNotes;

  const ReportMaskingParams({
    required this.verificationId,
    required this.description,
    this.additionalNotes,
  });

  @override
  List<Object?> get props => [verificationId, description, additionalNotes];
}
