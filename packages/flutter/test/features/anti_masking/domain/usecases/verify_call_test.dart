import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:acm_mobile/core/errors/failures.dart';
import 'package:acm_mobile/features/anti_masking/domain/entities/call_verification.dart';
import 'package:acm_mobile/features/anti_masking/domain/repositories/anti_masking_repository.dart';
import 'package:acm_mobile/features/anti_masking/domain/usecases/verify_call.dart';

class MockAntiMaskingRepository extends Mock implements AntiMaskingRepository {}

void main() {
  late VerifyCall usecase;
  late MockAntiMaskingRepository mockRepository;

  setUp(() {
    mockRepository = MockAntiMaskingRepository();
    usecase = VerifyCall(mockRepository);
  });

  const tCallerNumber = '08031234567';
  const tCalleeNumber = '08051234567';
  final tVerification = CallVerification(
    id: 'test-id',
    callerNumber: tCallerNumber,
    calleeNumber: tCalleeNumber,
    originalCli: tCallerNumber,
    maskingDetected: false,
    confidenceScore: 0.1,
    status: VerificationStatus.verified,
    verifiedAt: DateTime.now(),
  );

  group('VerifyCall', () {
    test('should return CallVerification when call is verified successfully', () async {
      // Arrange
      when(() => mockRepository.verifyCall(
        callerNumber: any(named: 'callerNumber'),
        calleeNumber: any(named: 'calleeNumber'),
      )).thenAnswer((_) async => Right(tVerification));

      // Act
      final result = await usecase(const VerifyCallParams(
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
      ));

      // Assert
      expect(result, Right(tVerification));
      verify(() => mockRepository.verifyCall(
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
      )).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure(message: 'Server error');
      when(() => mockRepository.verifyCall(
        callerNumber: any(named: 'callerNumber'),
        calleeNumber: any(named: 'calleeNumber'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(const VerifyCallParams(
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
      ));

      // Assert
      expect(result, const Left(failure));
      verify(() => mockRepository.verifyCall(
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
      )).called(1);
    });

    test('should return NetworkFailure when there is no internet', () async {
      // Arrange
      const failure = NetworkFailure();
      when(() => mockRepository.verifyCall(
        callerNumber: any(named: 'callerNumber'),
        calleeNumber: any(named: 'calleeNumber'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await usecase(const VerifyCallParams(
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
      ));

      // Assert
      expect(result, const Left(failure));
    });

    test('should detect masking when confidence score is high', () async {
      // Arrange
      final maskedVerification = CallVerification(
        id: 'test-id-masked',
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
        originalCli: tCallerNumber,
        detectedCli: '08099999999', // Different CLI detected
        maskingDetected: true,
        confidenceScore: 0.95,
        status: VerificationStatus.masking_detected,
        verifiedAt: DateTime.now(),
      );

      when(() => mockRepository.verifyCall(
        callerNumber: any(named: 'callerNumber'),
        calleeNumber: any(named: 'calleeNumber'),
      )).thenAnswer((_) async => Right(maskedVerification));

      // Act
      final result = await usecase(const VerifyCallParams(
        callerNumber: tCallerNumber,
        calleeNumber: tCalleeNumber,
      ));

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (verification) {
          expect(verification.maskingDetected, true);
          expect(verification.confidenceScore, greaterThan(0.9));
          expect(verification.riskLevel, RiskLevel.critical);
          expect(verification.isSuspicious, true);
        },
      );
    });
  });

  group('CallVerification entity', () {
    test('isSafe should return true when no masking and low confidence', () {
      final verification = CallVerification(
        id: 'test',
        callerNumber: '08031234567',
        calleeNumber: '08051234567',
        originalCli: '08031234567',
        maskingDetected: false,
        confidenceScore: 0.2,
        status: VerificationStatus.verified,
        verifiedAt: DateTime.now(),
      );

      expect(verification.isSafe, true);
      expect(verification.isSuspicious, false);
    });

    test('isSuspicious should return true when masking detected', () {
      final verification = CallVerification(
        id: 'test',
        callerNumber: '08031234567',
        calleeNumber: '08051234567',
        originalCli: '08031234567',
        maskingDetected: true,
        confidenceScore: 0.85,
        status: VerificationStatus.masking_detected,
        verifiedAt: DateTime.now(),
      );

      expect(verification.isSafe, false);
      expect(verification.isSuspicious, true);
    });

    test('riskLevel should return correct level based on confidence', () {
      expect(
        _createVerification(0.95).riskLevel,
        RiskLevel.critical,
      );
      expect(
        _createVerification(0.75).riskLevel,
        RiskLevel.high,
      );
      expect(
        _createVerification(0.55).riskLevel,
        RiskLevel.medium,
      );
      expect(
        _createVerification(0.25).riskLevel,
        RiskLevel.low,
      );
    });
  });
}

CallVerification _createVerification(double confidenceScore) {
  return CallVerification(
    id: 'test',
    callerNumber: '08031234567',
    calleeNumber: '08051234567',
    originalCli: '08031234567',
    maskingDetected: confidenceScore >= 0.5,
    confidenceScore: confidenceScore,
    status: confidenceScore >= 0.5
        ? VerificationStatus.masking_detected
        : VerificationStatus.verified,
    verifiedAt: DateTime.now(),
  );
}
