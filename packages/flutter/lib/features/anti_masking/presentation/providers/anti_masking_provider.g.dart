// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anti_masking_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$callVerificationNotifierHash() =>
    r'e61783c62841e3593f79d08f0a2b873013fba9ac';

/// Call verification notifier
///
/// Copied from [CallVerificationNotifier].
@ProviderFor(CallVerificationNotifier)
final callVerificationNotifierProvider = AutoDisposeNotifierProvider<
    CallVerificationNotifier, VerificationState>.internal(
  CallVerificationNotifier.new,
  name: r'callVerificationNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$callVerificationNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CallVerificationNotifier = AutoDisposeNotifier<VerificationState>;
String _$fraudAlertsNotifierHash() =>
    r'0b24f69cd8d2b538f9abff61650f6cd05b1b4506';

/// Fraud alerts notifier
///
/// Copied from [FraudAlertsNotifier].
@ProviderFor(FraudAlertsNotifier)
final fraudAlertsNotifierProvider =
    AutoDisposeNotifierProvider<FraudAlertsNotifier, FraudAlertState>.internal(
  FraudAlertsNotifier.new,
  name: r'fraudAlertsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fraudAlertsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FraudAlertsNotifier = AutoDisposeNotifier<FraudAlertState>;
String _$verificationStatsHash() => r'fea134f84a88bd620b99d644f1a0bfcdc16e5318';

/// Quick verification stats provider
///
/// Copied from [VerificationStats].
@ProviderFor(VerificationStats)
final verificationStatsProvider =
    AutoDisposeNotifierProvider<VerificationStats, Map<String, int>>.internal(
  VerificationStats.new,
  name: r'verificationStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$verificationStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VerificationStats = AutoDisposeNotifier<Map<String, int>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
