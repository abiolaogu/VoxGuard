// Fraud Prevention Domain Entities
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fraud_entities.freezed.dart';
part 'fraud_entities.g.dart';

// ============================================================
// CLI VERIFICATION
// ============================================================

@freezed
class CLIVerification with _$CLIVerification {
  const factory CLIVerification({
    required String id,
    required String presentedCli,
    String? actualCli,
    String? networkCli,
    required bool spoofingDetected,
    String? spoofingType,
    double? confidenceScore,
    String? verificationMethod,
    Map<String, dynamic>? ss7Analysis,
    Map<String, dynamic>? stirShakenResult,
    String? carrierId,
    String? callDirection,
    required DateTime createdAt,
  }) = _CLIVerification;

  factory CLIVerification.fromJson(Map<String, dynamic> json) =>
      _$CLIVerificationFromJson(json);
}

@freezed
class SpoofingType with _$SpoofingType {
  const factory SpoofingType.cliManipulation() = _CLIManipulation;
  const factory SpoofingType.numberSubstitution() = _NumberSubstitution;
  const factory SpoofingType.neighborSpoofing() = _NeighborSpoofing;
  const factory SpoofingType.tollFreeSpoofing() = _TollFreeSpoofing;
  const factory SpoofingType.governmentImpersonation() = _GovernmentImpersonation;
  const factory SpoofingType.bankImpersonation() = _BankImpersonation;
  const factory SpoofingType.none() = _None;
}

// ============================================================
// IRSF INCIDENT
// ============================================================

@freezed
class IRSFIncident with _$IRSFIncident {
  const factory IRSFIncident({
    required String id,
    required String sourceNumber,
    required String destinationNumber,
    required String destinationCountry,
    String? destinationPrefix,
    required double riskScore,
    required Map<String, dynamic> irsfIndicators,
    String? detectionMethod,
    String? matchedPatternId,
    int? callDurationSeconds,
    double? ratePerMinute,
    double? estimatedLoss,
    String? actionTaken,
    DateTime? blockedAt,
    String? carrierId,
    String? subscriberId,
    required DateTime createdAt,
  }) = _IRSFIncident;

  factory IRSFIncident.fromJson(Map<String, dynamic> json) =>
      _$IRSFIncidentFromJson(json);
}

@freezed
class IRSFDestination with _$IRSFDestination {
  const factory IRSFDestination({
    required String id,
    required String countryCode,
    required String prefix,
    String? countryName,
    required String riskLevel,
    List<String>? fraudTypes,
    double? averageFraudRate,
    int? incidentCount,
    DateTime? lastIncidentAt,
    required bool isBlacklisted,
    required bool isMonitored,
    required DateTime createdAt,
  }) = _IRSFDestination;

  factory IRSFDestination.fromJson(Map<String, dynamic> json) =>
      _$IRSFDestinationFromJson(json);
}

// ============================================================
// WANGIRI INCIDENT
// ============================================================

@freezed
class WangiriIncident with _$WangiriIncident {
  const factory WangiriIncident({
    required String id,
    required String sourceNumber,
    required String targetNumber,
    required int ringDurationMs,
    required Map<String, dynamic> wangiriIndicators,
    required double confidenceScore,
    required bool callbackAttempted,
    String? callbackDestination,
    double? callbackCost,
    int? callbackDurationSeconds,
    String? campaignId,
    required bool warningSent,
    required bool callbackBlocked,
    required DateTime createdAt,
  }) = _WangiriIncident;

  factory WangiriIncident.fromJson(Map<String, dynamic> json) =>
      _$WangiriIncidentFromJson(json);
}

@freezed
class WangiriCampaign with _$WangiriCampaign {
  const factory WangiriCampaign({
    required String id,
    required List<String> sourceNumbers,
    String? sourceCountry,
    String? sourceCarrierId,
    required DateTime startTime,
    DateTime? endTime,
    List<String>? targetedPrefixes,
    int? avgRingDurationMs,
    required int totalCallAttempts,
    required int successfulCallbacks,
    required double estimatedRevenueLoss,
    required String status,
    List<String>? blockedNumbers,
    required int alertsSent,
    required DateTime createdAt,
  }) = _WangiriCampaign;

  factory WangiriCampaign.fromJson(Map<String, dynamic> json) =>
      _$WangiriCampaignFromJson(json);
}

// ============================================================
// CALLBACK FRAUD
// ============================================================

@freezed
class CallbackFraudIncident with _$CallbackFraudIncident {
  const factory CallbackFraudIncident({
    required String id,
    required String triggerType,
    String? triggerCallId,
    required String callbackSource,
    required String callbackDestination,
    int? callbackDurationSeconds,
    String? destinationRiskLevel,
    String? fraudType,
    required double domesticCost,
    required double internationalCost,
    required double premiumCost,
    required double totalLoss,
    String? detectionMethod,
    required DateTime detectionTime,
    String? actionTaken,
    required bool subscriberNotified,
    required DateTime createdAt,
  }) = _CallbackFraudIncident;

  factory CallbackFraudIncident.fromJson(Map<String, dynamic> json) =>
      _$CallbackFraudIncidentFromJson(json);
}

// ============================================================
// FRAUD SUMMARY
// ============================================================

@freezed
class FraudSummary with _$FraudSummary {
  const factory FraudSummary({
    required int cliSpoofingCount,
    required int irsfCount,
    required int wangiriCount,
    required int callbackFraudCount,
    required double totalRevenueProtected,
    required DateTime lastUpdated,
  }) = _FraudSummary;

  factory FraudSummary.fromJson(Map<String, dynamic> json) =>
      _$FraudSummaryFromJson(json);
}

// ============================================================
// RISK LEVEL
// ============================================================

enum RiskLevel {
  critical,
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case RiskLevel.critical:
        return 'CRITICAL';
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.medium:
        return 'MEDIUM';
      case RiskLevel.low:
        return 'LOW';
    }
  }

  static RiskLevel fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CRITICAL':
        return RiskLevel.critical;
      case 'HIGH':
        return RiskLevel.high;
      case 'MEDIUM':
        return RiskLevel.medium;
      default:
        return RiskLevel.low;
    }
  }
}
