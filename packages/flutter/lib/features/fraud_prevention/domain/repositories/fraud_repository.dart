// Fraud Prevention Repository
import '../entities/fraud_entities.dart';

abstract class FraudRepository {
  // CLI Verifications
  Future<List<CLIVerification>> getCLIVerifications({
    int limit = 20,
    int offset = 0,
    bool? spoofingDetected,
  });

  Future<CLIVerification?> getCLIVerification(String id);

  // IRSF
  Future<List<IRSFIncident>> getIRSFIncidents({
    int limit = 20,
    int offset = 0,
    String? riskLevel,
  });

  Future<List<IRSFDestination>> getIRSFDestinations({
    String? riskLevel,
    bool? isBlacklisted,
  });

  Future<void> blacklistDestination(String destinationId);

  // Wangiri
  Future<List<WangiriIncident>> getWangiriIncidents({
    int limit = 20,
    int offset = 0,
  });

  Future<List<WangiriCampaign>> getWangiriCampaigns({
    String? status,
  });

  Future<void> blockWangiriSource(String sourceNumber);

  // Callback Fraud
  Future<List<CallbackFraudIncident>> getCallbackFraudIncidents({
    int limit = 20,
    int offset = 0,
  });

  // Summary
  Future<FraudSummary> getFraudSummary();

  // Actions
  Future<void> reportFraudulentNumber(String number, String fraudType);
  Future<void> blockNumber(String number, String reason);
}
