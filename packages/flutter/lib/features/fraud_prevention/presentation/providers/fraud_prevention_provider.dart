// Fraud Prevention Provider (Riverpod)
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/entities/fraud_entities.dart';
import '../domain/repositories/fraud_repository.dart';
import '../data/repositories/fraud_repository_impl.dart';

part 'fraud_prevention_provider.g.dart';

// Repository provider
@riverpod
FraudRepository fraudRepository(FraudRepositoryRef ref) {
  return FraudRepositoryImpl(ref);
}

// Fraud Summary
@riverpod
Future<FraudSummary> fraudSummary(FraudSummaryRef ref) async {
  final repository = ref.watch(fraudRepositoryProvider);
  return repository.getFraudSummary();
}

// CLI Verifications
@riverpod
class CLIVerificationsNotifier extends _$CLIVerificationsNotifier {
  @override
  Future<List<CLIVerification>> build({bool? spoofingOnly}) async {
    final repository = ref.watch(fraudRepositoryProvider);
    return repository.getCLIVerifications(
      spoofingDetected: spoofingOnly,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fraudRepositoryProvider);
      return repository.getCLIVerifications();
    });
  }
}

// IRSF Incidents
@riverpod
class IRSFIncidentsNotifier extends _$IRSFIncidentsNotifier {
  @override
  Future<List<IRSFIncident>> build({String? riskLevel}) async {
    final repository = ref.watch(fraudRepositoryProvider);
    return repository.getIRSFIncidents(riskLevel: riskLevel);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fraudRepositoryProvider);
      return repository.getIRSFIncidents();
    });
  }
}

// IRSF Destinations
@riverpod
Future<List<IRSFDestination>> irsfDestinations(
  IrsfDestinationsRef ref, {
  String? riskLevel,
}) async {
  final repository = ref.watch(fraudRepositoryProvider);
  return repository.getIRSFDestinations(riskLevel: riskLevel);
}

// Wangiri Incidents
@riverpod
class WangiriIncidentsNotifier extends _$WangiriIncidentsNotifier {
  @override
  Future<List<WangiriIncident>> build() async {
    final repository = ref.watch(fraudRepositoryProvider);
    return repository.getWangiriIncidents();
  }

  Future<void> blockSource(String sourceNumber) async {
    final repository = ref.read(fraudRepositoryProvider);
    await repository.blockWangiriSource(sourceNumber);
    ref.invalidateSelf();
  }
}

// Wangiri Campaigns
@riverpod
Future<List<WangiriCampaign>> wangiriCampaigns(
  WangiriCampaignsRef ref, {
  String? status,
}) async {
  final repository = ref.watch(fraudRepositoryProvider);
  return repository.getWangiriCampaigns(status: status);
}

// Callback Fraud
@riverpod
Future<List<CallbackFraudIncident>> callbackFraudIncidents(
  CallbackFraudIncidentsRef ref,
) async {
  final repository = ref.watch(fraudRepositoryProvider);
  return repository.getCallbackFraudIncidents();
}

// Block Number Action
@riverpod
class BlockNumberNotifier extends _$BlockNumberNotifier {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> blockNumber(String number, String reason) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(fraudRepositoryProvider);
      await repository.blockNumber(number, reason);
    });
  }
}
