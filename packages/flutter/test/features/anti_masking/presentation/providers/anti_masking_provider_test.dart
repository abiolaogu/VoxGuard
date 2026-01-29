import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:acm_mobile/core/errors/failures.dart';
import 'package:acm_mobile/features/anti_masking/domain/entities/call_verification.dart';
import 'package:acm_mobile/features/anti_masking/domain/usecases/verify_call.dart';
import 'package:acm_mobile/features/anti_masking/domain/usecases/get_verification_history.dart';
import 'package:acm_mobile/features/anti_masking/presentation/providers/anti_masking_provider.dart';

class MockVerifyCall extends Mock implements VerifyCall {}
class MockGetVerificationHistory extends Mock implements GetVerificationHistory {}

void main() {
  late ProviderContainer container;
  late MockVerifyCall mockVerifyCall;
  late MockGetVerificationHistory mockGetHistory;

  setUp(() {
    mockVerifyCall = MockVerifyCall();
    mockGetHistory = MockGetVerificationHistory();

    // Register fallback values
    registerFallbackValue(const VerifyCallParams(
      callerNumber: '',
      calleeNumber: '',
    ));
    registerFallbackValue(const GetVerificationHistoryParams());

    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  final tVerification = CallVerification(
    id: 'test-id',
    callerNumber: '08031234567',
    calleeNumber: '08051234567',
    originalCli: '08031234567',
    maskingDetected: false,
    confidenceScore: 0.1,
    status: VerificationStatus.verified,
    verifiedAt: DateTime.now(),
  );

  final tMaskedVerification = CallVerification(
    id: 'masked-id',
    callerNumber: '08031234567',
    calleeNumber: '08051234567',
    originalCli: '08031234567',
    detectedCli: '08099999999',
    maskingDetected: true,
    confidenceScore: 0.92,
    status: VerificationStatus.masking_detected,
    verifiedAt: DateTime.now(),
  );

  group('VerificationState', () {
    test('initial state should have empty values', () {
      const state = VerificationState();

      expect(state.isLoading, false);
      expect(state.verifications, isEmpty);
      expect(state.error, isNull);
      expect(state.lastVerification, isNull);
    });

    test('copyWith should update specified fields', () {
      const initialState = VerificationState();
      final newState = initialState.copyWith(
        isLoading: true,
        verifications: [tVerification],
      );

      expect(newState.isLoading, true);
      expect(newState.verifications, [tVerification]);
      expect(newState.error, isNull);
    });

    test('copyWith with error should be accessible', () {
      const initialState = VerificationState();
      final newState = initialState.copyWith(
        error: 'Test error',
      );

      expect(newState.error, 'Test error');
      expect(newState.isLoading, false);
    });
  });

  group('FraudAlertState', () {
    test('initial state should have zero pending count', () {
      const state = FraudAlertState();

      expect(state.isLoading, false);
      expect(state.alerts, isEmpty);
      expect(state.error, isNull);
      expect(state.pendingCount, 0);
    });

    test('copyWith should update pending count', () {
      const initialState = FraudAlertState();
      final newState = initialState.copyWith(
        pendingCount: 5,
        isLoading: true,
      );

      expect(newState.pendingCount, 5);
      expect(newState.isLoading, true);
    });
  });

  group('Verification list behavior', () {
    test('new verifications should be prepended to list', () {
      const initialState = VerificationState(
        verifications: [],
      );

      final state1 = initialState.copyWith(
        verifications: [tVerification],
        lastVerification: tVerification,
      );

      expect(state1.verifications.length, 1);
      expect(state1.lastVerification, tVerification);

      final state2 = state1.copyWith(
        verifications: [tMaskedVerification, ...state1.verifications],
        lastVerification: tMaskedVerification,
      );

      expect(state2.verifications.length, 2);
      expect(state2.verifications.first.maskingDetected, true);
      expect(state2.lastVerification?.maskingDetected, true);
    });

    test('masking detection should have high confidence score', () {
      const state = VerificationState();
      final newState = state.copyWith(
        lastVerification: tMaskedVerification,
      );

      expect(newState.lastVerification?.maskingDetected, true);
      expect(newState.lastVerification?.confidenceScore, greaterThan(0.9));
      expect(newState.lastVerification?.riskLevel, RiskLevel.critical);
    });
  });
}
