// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraud_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CLIVerificationImpl _$$CLIVerificationImplFromJson(
        Map<String, dynamic> json) =>
    _$CLIVerificationImpl(
      id: json['id'] as String,
      presentedCli: json['presentedCli'] as String,
      actualCli: json['actualCli'] as String?,
      networkCli: json['networkCli'] as String?,
      spoofingDetected: json['spoofingDetected'] as bool,
      spoofingType: json['spoofingType'] as String?,
      confidenceScore: (json['confidenceScore'] as num?)?.toDouble(),
      verificationMethod: json['verificationMethod'] as String?,
      ss7Analysis: json['ss7Analysis'] as Map<String, dynamic>?,
      stirShakenResult: json['stirShakenResult'] as Map<String, dynamic>?,
      carrierId: json['carrierId'] as String?,
      callDirection: json['callDirection'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CLIVerificationImplToJson(
    _$CLIVerificationImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'presentedCli': instance.presentedCli,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('actualCli', instance.actualCli);
  writeNotNull('networkCli', instance.networkCli);
  val['spoofingDetected'] = instance.spoofingDetected;
  writeNotNull('spoofingType', instance.spoofingType);
  writeNotNull('confidenceScore', instance.confidenceScore);
  writeNotNull('verificationMethod', instance.verificationMethod);
  writeNotNull('ss7Analysis', instance.ss7Analysis);
  writeNotNull('stirShakenResult', instance.stirShakenResult);
  writeNotNull('carrierId', instance.carrierId);
  writeNotNull('callDirection', instance.callDirection);
  val['createdAt'] = instance.createdAt.toIso8601String();
  return val;
}

_$IRSFIncidentImpl _$$IRSFIncidentImplFromJson(Map<String, dynamic> json) =>
    _$IRSFIncidentImpl(
      id: json['id'] as String,
      sourceNumber: json['sourceNumber'] as String,
      destinationNumber: json['destinationNumber'] as String,
      destinationCountry: json['destinationCountry'] as String,
      destinationPrefix: json['destinationPrefix'] as String?,
      riskScore: (json['riskScore'] as num).toDouble(),
      irsfIndicators: json['irsfIndicators'] as Map<String, dynamic>,
      detectionMethod: json['detectionMethod'] as String?,
      matchedPatternId: json['matchedPatternId'] as String?,
      callDurationSeconds: (json['callDurationSeconds'] as num?)?.toInt(),
      ratePerMinute: (json['ratePerMinute'] as num?)?.toDouble(),
      estimatedLoss: (json['estimatedLoss'] as num?)?.toDouble(),
      actionTaken: json['actionTaken'] as String?,
      blockedAt: json['blockedAt'] == null
          ? null
          : DateTime.parse(json['blockedAt'] as String),
      carrierId: json['carrierId'] as String?,
      subscriberId: json['subscriberId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$IRSFIncidentImplToJson(_$IRSFIncidentImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'sourceNumber': instance.sourceNumber,
    'destinationNumber': instance.destinationNumber,
    'destinationCountry': instance.destinationCountry,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('destinationPrefix', instance.destinationPrefix);
  val['riskScore'] = instance.riskScore;
  val['irsfIndicators'] = instance.irsfIndicators;
  writeNotNull('detectionMethod', instance.detectionMethod);
  writeNotNull('matchedPatternId', instance.matchedPatternId);
  writeNotNull('callDurationSeconds', instance.callDurationSeconds);
  writeNotNull('ratePerMinute', instance.ratePerMinute);
  writeNotNull('estimatedLoss', instance.estimatedLoss);
  writeNotNull('actionTaken', instance.actionTaken);
  writeNotNull('blockedAt', instance.blockedAt?.toIso8601String());
  writeNotNull('carrierId', instance.carrierId);
  writeNotNull('subscriberId', instance.subscriberId);
  val['createdAt'] = instance.createdAt.toIso8601String();
  return val;
}

_$IRSFDestinationImpl _$$IRSFDestinationImplFromJson(
        Map<String, dynamic> json) =>
    _$IRSFDestinationImpl(
      id: json['id'] as String,
      countryCode: json['countryCode'] as String,
      prefix: json['prefix'] as String,
      countryName: json['countryName'] as String?,
      riskLevel: json['riskLevel'] as String,
      fraudTypes: (json['fraudTypes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      averageFraudRate: (json['averageFraudRate'] as num?)?.toDouble(),
      incidentCount: (json['incidentCount'] as num?)?.toInt(),
      lastIncidentAt: json['lastIncidentAt'] == null
          ? null
          : DateTime.parse(json['lastIncidentAt'] as String),
      isBlacklisted: json['isBlacklisted'] as bool,
      isMonitored: json['isMonitored'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$IRSFDestinationImplToJson(
    _$IRSFDestinationImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'countryCode': instance.countryCode,
    'prefix': instance.prefix,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('countryName', instance.countryName);
  val['riskLevel'] = instance.riskLevel;
  writeNotNull('fraudTypes', instance.fraudTypes);
  writeNotNull('averageFraudRate', instance.averageFraudRate);
  writeNotNull('incidentCount', instance.incidentCount);
  writeNotNull('lastIncidentAt', instance.lastIncidentAt?.toIso8601String());
  val['isBlacklisted'] = instance.isBlacklisted;
  val['isMonitored'] = instance.isMonitored;
  val['createdAt'] = instance.createdAt.toIso8601String();
  return val;
}

_$WangiriIncidentImpl _$$WangiriIncidentImplFromJson(
        Map<String, dynamic> json) =>
    _$WangiriIncidentImpl(
      id: json['id'] as String,
      sourceNumber: json['sourceNumber'] as String,
      targetNumber: json['targetNumber'] as String,
      ringDurationMs: (json['ringDurationMs'] as num).toInt(),
      wangiriIndicators: json['wangiriIndicators'] as Map<String, dynamic>,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      callbackAttempted: json['callbackAttempted'] as bool,
      callbackDestination: json['callbackDestination'] as String?,
      callbackCost: (json['callbackCost'] as num?)?.toDouble(),
      callbackDurationSeconds:
          (json['callbackDurationSeconds'] as num?)?.toInt(),
      campaignId: json['campaignId'] as String?,
      warningSent: json['warningSent'] as bool,
      callbackBlocked: json['callbackBlocked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WangiriIncidentImplToJson(
    _$WangiriIncidentImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'sourceNumber': instance.sourceNumber,
    'targetNumber': instance.targetNumber,
    'ringDurationMs': instance.ringDurationMs,
    'wangiriIndicators': instance.wangiriIndicators,
    'confidenceScore': instance.confidenceScore,
    'callbackAttempted': instance.callbackAttempted,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('callbackDestination', instance.callbackDestination);
  writeNotNull('callbackCost', instance.callbackCost);
  writeNotNull('callbackDurationSeconds', instance.callbackDurationSeconds);
  writeNotNull('campaignId', instance.campaignId);
  val['warningSent'] = instance.warningSent;
  val['callbackBlocked'] = instance.callbackBlocked;
  val['createdAt'] = instance.createdAt.toIso8601String();
  return val;
}

_$WangiriCampaignImpl _$$WangiriCampaignImplFromJson(
        Map<String, dynamic> json) =>
    _$WangiriCampaignImpl(
      id: json['id'] as String,
      sourceNumbers: (json['sourceNumbers'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sourceCountry: json['sourceCountry'] as String?,
      sourceCarrierId: json['sourceCarrierId'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      targetedPrefixes: (json['targetedPrefixes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      avgRingDurationMs: (json['avgRingDurationMs'] as num?)?.toInt(),
      totalCallAttempts: (json['totalCallAttempts'] as num).toInt(),
      successfulCallbacks: (json['successfulCallbacks'] as num).toInt(),
      estimatedRevenueLoss: (json['estimatedRevenueLoss'] as num).toDouble(),
      status: json['status'] as String,
      blockedNumbers: (json['blockedNumbers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      alertsSent: (json['alertsSent'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WangiriCampaignImplToJson(
    _$WangiriCampaignImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'sourceNumbers': instance.sourceNumbers,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('sourceCountry', instance.sourceCountry);
  writeNotNull('sourceCarrierId', instance.sourceCarrierId);
  val['startTime'] = instance.startTime.toIso8601String();
  writeNotNull('endTime', instance.endTime?.toIso8601String());
  writeNotNull('targetedPrefixes', instance.targetedPrefixes);
  writeNotNull('avgRingDurationMs', instance.avgRingDurationMs);
  val['totalCallAttempts'] = instance.totalCallAttempts;
  val['successfulCallbacks'] = instance.successfulCallbacks;
  val['estimatedRevenueLoss'] = instance.estimatedRevenueLoss;
  val['status'] = instance.status;
  writeNotNull('blockedNumbers', instance.blockedNumbers);
  val['alertsSent'] = instance.alertsSent;
  val['createdAt'] = instance.createdAt.toIso8601String();
  return val;
}

_$CallbackFraudIncidentImpl _$$CallbackFraudIncidentImplFromJson(
        Map<String, dynamic> json) =>
    _$CallbackFraudIncidentImpl(
      id: json['id'] as String,
      triggerType: json['triggerType'] as String,
      triggerCallId: json['triggerCallId'] as String?,
      callbackSource: json['callbackSource'] as String,
      callbackDestination: json['callbackDestination'] as String,
      callbackDurationSeconds:
          (json['callbackDurationSeconds'] as num?)?.toInt(),
      destinationRiskLevel: json['destinationRiskLevel'] as String?,
      fraudType: json['fraudType'] as String?,
      domesticCost: (json['domesticCost'] as num).toDouble(),
      internationalCost: (json['internationalCost'] as num).toDouble(),
      premiumCost: (json['premiumCost'] as num).toDouble(),
      totalLoss: (json['totalLoss'] as num).toDouble(),
      detectionMethod: json['detectionMethod'] as String?,
      detectionTime: DateTime.parse(json['detectionTime'] as String),
      actionTaken: json['actionTaken'] as String?,
      subscriberNotified: json['subscriberNotified'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CallbackFraudIncidentImplToJson(
    _$CallbackFraudIncidentImpl instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'triggerType': instance.triggerType,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('triggerCallId', instance.triggerCallId);
  val['callbackSource'] = instance.callbackSource;
  val['callbackDestination'] = instance.callbackDestination;
  writeNotNull('callbackDurationSeconds', instance.callbackDurationSeconds);
  writeNotNull('destinationRiskLevel', instance.destinationRiskLevel);
  writeNotNull('fraudType', instance.fraudType);
  val['domesticCost'] = instance.domesticCost;
  val['internationalCost'] = instance.internationalCost;
  val['premiumCost'] = instance.premiumCost;
  val['totalLoss'] = instance.totalLoss;
  writeNotNull('detectionMethod', instance.detectionMethod);
  val['detectionTime'] = instance.detectionTime.toIso8601String();
  writeNotNull('actionTaken', instance.actionTaken);
  val['subscriberNotified'] = instance.subscriberNotified;
  val['createdAt'] = instance.createdAt.toIso8601String();
  return val;
}

_$FraudSummaryImpl _$$FraudSummaryImplFromJson(Map<String, dynamic> json) =>
    _$FraudSummaryImpl(
      cliSpoofingCount: (json['cliSpoofingCount'] as num).toInt(),
      irsfCount: (json['irsfCount'] as num).toInt(),
      wangiriCount: (json['wangiriCount'] as num).toInt(),
      callbackFraudCount: (json['callbackFraudCount'] as num).toInt(),
      totalRevenueProtected: (json['totalRevenueProtected'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$$FraudSummaryImplToJson(_$FraudSummaryImpl instance) =>
    <String, dynamic>{
      'cliSpoofingCount': instance.cliSpoofingCount,
      'irsfCount': instance.irsfCount,
      'wangiriCount': instance.wangiriCount,
      'callbackFraudCount': instance.callbackFraudCount,
      'totalRevenueProtected': instance.totalRevenueProtected,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
