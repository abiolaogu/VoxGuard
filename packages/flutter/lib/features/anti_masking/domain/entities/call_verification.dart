import 'package:equatable/equatable.dart';

/// Call verification entity
class CallVerification extends Equatable {
  final String id;
  final String callerNumber;
  final String calleeNumber;
  final String originalCli;
  final String? detectedCli;
  final bool maskingDetected;
  final double confidenceScore;
  final VerificationStatus status;
  final String? gatewayId;
  final String? gatewayName;
  final String? mno;
  final DateTime verifiedAt;
  final VerificationDetails? details;

  const CallVerification({
    required this.id,
    required this.callerNumber,
    required this.calleeNumber,
    required this.originalCli,
    this.detectedCli,
    required this.maskingDetected,
    required this.confidenceScore,
    required this.status,
    this.gatewayId,
    this.gatewayName,
    this.mno,
    required this.verifiedAt,
    this.details,
  });

  /// Check if call is safe (no masking detected)
  bool get isSafe => !maskingDetected && confidenceScore < 0.5;

  /// Check if call is suspicious
  bool get isSuspicious => maskingDetected || confidenceScore >= 0.5;

  /// Get risk level based on confidence score
  RiskLevel get riskLevel {
    if (confidenceScore >= 0.9) return RiskLevel.critical;
    if (confidenceScore >= 0.7) return RiskLevel.high;
    if (confidenceScore >= 0.5) return RiskLevel.medium;
    return RiskLevel.low;
  }

  @override
  List<Object?> get props => [
        id,
        callerNumber,
        calleeNumber,
        originalCli,
        detectedCli,
        maskingDetected,
        confidenceScore,
        status,
        gatewayId,
        verifiedAt,
      ];
}

/// Verification status enum
enum VerificationStatus {
  pending,
  verified,
  masking_detected,
  failed,
  timeout,
}

/// Risk level enum
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Extension for risk level properties
extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
      case RiskLevel.critical:
        return 'Critical';
    }
  }

  String get color {
    switch (this) {
      case RiskLevel.low:
        return '1890FF';
      case RiskLevel.medium:
        return 'FAAD14';
      case RiskLevel.high:
        return 'FA8C16';
      case RiskLevel.critical:
        return 'FF4D4F';
    }
  }
}

/// Detailed verification information
class VerificationDetails extends Equatable {
  final String? prefixAnalysis;
  final String? routingAnalysis;
  final String? patternAnalysis;
  final String? velocityAnalysis;
  final Map<String, dynamic>? rawData;

  const VerificationDetails({
    this.prefixAnalysis,
    this.routingAnalysis,
    this.patternAnalysis,
    this.velocityAnalysis,
    this.rawData,
  });

  @override
  List<Object?> get props => [
        prefixAnalysis,
        routingAnalysis,
        patternAnalysis,
        velocityAnalysis,
      ];
}

/// Fraud alert entity
class FraudAlert extends Equatable {
  final String id;
  final String? callVerificationId;
  final String? gatewayId;
  final AlertSeverity severity;
  final AlertType alertType;
  final String description;
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime? resolvedAt;
  final String? resolution;

  const FraudAlert({
    required this.id,
    this.callVerificationId,
    this.gatewayId,
    required this.severity,
    required this.alertType,
    required this.description,
    required this.status,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedBy,
    this.resolvedAt,
    this.resolution,
  });

  bool get isPending => status == AlertStatus.pending;
  bool get isAcknowledged => status == AlertStatus.acknowledged;
  bool get isResolved => status == AlertStatus.resolved;

  @override
  List<Object?> get props => [
        id,
        callVerificationId,
        gatewayId,
        severity,
        alertType,
        status,
        createdAt,
      ];
}

/// Alert severity enum
enum AlertSeverity {
  low,
  medium,
  high,
  critical,
}

/// Alert type enum
enum AlertType {
  cli_masking,
  volume_spike,
  suspicious_pattern,
  gateway_issue,
  route_anomaly,
}

/// Alert status enum
enum AlertStatus {
  pending,
  acknowledged,
  investigating,
  resolved,
  false_positive,
}
