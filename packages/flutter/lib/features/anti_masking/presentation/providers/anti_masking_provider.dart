import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../injection.dart';
import '../../domain/entities/call_verification.dart';
import '../../domain/usecases/verify_call.dart';
import '../../domain/usecases/get_verification_history.dart';
import '../../domain/usecases/report_masking.dart';

part 'anti_masking_provider.g.dart';

/// State for call verification
class VerificationState {
  final bool isLoading;
  final List<CallVerification> verifications;
  final String? error;
  final CallVerification? lastVerification;

  const VerificationState({
    this.isLoading = false,
    this.verifications = const [],
    this.error,
    this.lastVerification,
  });

  VerificationState copyWith({
    bool? isLoading,
    List<CallVerification>? verifications,
    String? error,
    CallVerification? lastVerification,
  }) {
    return VerificationState(
      isLoading: isLoading ?? this.isLoading,
      verifications: verifications ?? this.verifications,
      error: error,
      lastVerification: lastVerification ?? this.lastVerification,
    );
  }
}

/// Call verification notifier
@riverpod
class CallVerificationNotifier extends _$CallVerificationNotifier {
  @override
  VerificationState build() {
    return const VerificationState();
  }

  /// Verify a call for masking
  Future<void> verifyCall(String callerNumber, String calleeNumber) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final verifyCallUseCase = getIt<VerifyCall>();
      final result = await verifyCallUseCase(VerifyCallParams(
        callerNumber: callerNumber,
        calleeNumber: calleeNumber,
      ));

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (verification) => state = state.copyWith(
          isLoading: false,
          lastVerification: verification,
          verifications: [verification, ...state.verifications],
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load verification history
  Future<void> loadHistory({
    int page = 1,
    bool? maskingOnly,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final getHistoryUseCase = getIt<GetVerificationHistory>();
      final result = await getHistoryUseCase(GetVerificationHistoryParams(
        page: page,
        maskingOnly: maskingOnly,
      ));

      result.fold(
        (failure) => state = state.copyWith(
          isLoading: false,
          error: failure.message,
        ),
        (verifications) => state = state.copyWith(
          isLoading: false,
          verifications: page == 1
              ? verifications
              : [...state.verifications, ...verifications],
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Report masking to NCC
  Future<bool> reportMasking(
    String verificationId,
    String description, {
    String? notes,
  }) async {
    try {
      final reportUseCase = getIt<ReportMasking>();
      final result = await reportUseCase(ReportMaskingParams(
        verificationId: verificationId,
        description: description,
        additionalNotes: notes,
      ));

      return result.fold(
        (failure) => false,
        (success) => success,
      );
    } catch (e) {
      return false;
    }
  }

  /// Clear last verification
  void clearLastVerification() {
    state = state.copyWith(lastVerification: null);
  }
}

/// State for fraud alerts
class FraudAlertState {
  final bool isLoading;
  final List<FraudAlert> alerts;
  final String? error;
  final int pendingCount;

  const FraudAlertState({
    this.isLoading = false,
    this.alerts = const [],
    this.error,
    this.pendingCount = 0,
  });

  FraudAlertState copyWith({
    bool? isLoading,
    List<FraudAlert>? alerts,
    String? error,
    int? pendingCount,
  }) {
    return FraudAlertState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      error: error,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }
}

/// Fraud alerts notifier
@riverpod
class FraudAlertsNotifier extends _$FraudAlertsNotifier {
  @override
  FraudAlertState build() {
    return const FraudAlertState();
  }

  /// Load fraud alerts
  Future<void> loadAlerts({
    int page = 1,
    AlertStatus? status,
    AlertSeverity? minSeverity,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    // TODO: Implement with repository
    await Future.delayed(const Duration(seconds: 1));

    state = state.copyWith(isLoading: false);
  }

  /// Acknowledge an alert
  Future<bool> acknowledgeAlert(String alertId) async {
    // TODO: Implement with repository
    return true;
  }

  /// Resolve an alert
  Future<bool> resolveAlert(String alertId, String resolution) async {
    // TODO: Implement with repository
    return true;
  }
}

/// Quick verification stats provider
@riverpod
class VerificationStats extends _$VerificationStats {
  @override
  Map<String, int> build() {
    return {
      'total': 0,
      'verified': 0,
      'masked': 0,
      'pending': 0,
    };
  }

  void updateStats(List<CallVerification> verifications) {
    final total = verifications.length;
    final verified = verifications.where((v) => !v.maskingDetected).length;
    final masked = verifications.where((v) => v.maskingDetected).length;
    final pending = verifications.where((v) => v.status == VerificationStatus.pending).length;

    state = {
      'total': total,
      'verified': verified,
      'masked': masked,
      'pending': pending,
    };
  }
}
