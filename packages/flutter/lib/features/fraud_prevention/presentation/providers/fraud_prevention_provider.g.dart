// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fraud_prevention_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fraudRepositoryHash() => r'dd9982968e03100a5b2d05ba481a429e0345fc2f';

/// See also [fraudRepository].
@ProviderFor(fraudRepository)
final fraudRepositoryProvider = AutoDisposeProvider<FraudRepository>.internal(
  fraudRepository,
  name: r'fraudRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fraudRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FraudRepositoryRef = AutoDisposeProviderRef<FraudRepository>;
String _$fraudSummaryHash() => r'9b855714ea4645f50bee75c853ef1a0d68e8e570';

/// See also [fraudSummary].
@ProviderFor(fraudSummary)
final fraudSummaryProvider = AutoDisposeFutureProvider<FraudSummary>.internal(
  fraudSummary,
  name: r'fraudSummaryProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fraudSummaryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FraudSummaryRef = AutoDisposeFutureProviderRef<FraudSummary>;
String _$irsfDestinationsHash() => r'd0d8cad9413a45187889a9a5eb9029890ae36f90';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [irsfDestinations].
@ProviderFor(irsfDestinations)
const irsfDestinationsProvider = IrsfDestinationsFamily();

/// See also [irsfDestinations].
class IrsfDestinationsFamily extends Family<AsyncValue<List<IRSFDestination>>> {
  /// See also [irsfDestinations].
  const IrsfDestinationsFamily();

  /// See also [irsfDestinations].
  IrsfDestinationsProvider call({
    String? riskLevel,
  }) {
    return IrsfDestinationsProvider(
      riskLevel: riskLevel,
    );
  }

  @override
  IrsfDestinationsProvider getProviderOverride(
    covariant IrsfDestinationsProvider provider,
  ) {
    return call(
      riskLevel: provider.riskLevel,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'irsfDestinationsProvider';
}

/// See also [irsfDestinations].
class IrsfDestinationsProvider
    extends AutoDisposeFutureProvider<List<IRSFDestination>> {
  /// See also [irsfDestinations].
  IrsfDestinationsProvider({
    String? riskLevel,
  }) : this._internal(
          (ref) => irsfDestinations(
            ref as IrsfDestinationsRef,
            riskLevel: riskLevel,
          ),
          from: irsfDestinationsProvider,
          name: r'irsfDestinationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$irsfDestinationsHash,
          dependencies: IrsfDestinationsFamily._dependencies,
          allTransitiveDependencies:
              IrsfDestinationsFamily._allTransitiveDependencies,
          riskLevel: riskLevel,
        );

  IrsfDestinationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.riskLevel,
  }) : super.internal();

  final String? riskLevel;

  @override
  Override overrideWith(
    FutureOr<List<IRSFDestination>> Function(IrsfDestinationsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IrsfDestinationsProvider._internal(
        (ref) => create(ref as IrsfDestinationsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        riskLevel: riskLevel,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<IRSFDestination>> createElement() {
    return _IrsfDestinationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IrsfDestinationsProvider && other.riskLevel == riskLevel;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, riskLevel.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IrsfDestinationsRef
    on AutoDisposeFutureProviderRef<List<IRSFDestination>> {
  /// The parameter `riskLevel` of this provider.
  String? get riskLevel;
}

class _IrsfDestinationsProviderElement
    extends AutoDisposeFutureProviderElement<List<IRSFDestination>>
    with IrsfDestinationsRef {
  _IrsfDestinationsProviderElement(super.provider);

  @override
  String? get riskLevel => (origin as IrsfDestinationsProvider).riskLevel;
}

String _$wangiriCampaignsHash() => r'cc232fc57fa5e1d3bcc55c0c90acdcfe7a06b831';

/// See also [wangiriCampaigns].
@ProviderFor(wangiriCampaigns)
const wangiriCampaignsProvider = WangiriCampaignsFamily();

/// See also [wangiriCampaigns].
class WangiriCampaignsFamily extends Family<AsyncValue<List<WangiriCampaign>>> {
  /// See also [wangiriCampaigns].
  const WangiriCampaignsFamily();

  /// See also [wangiriCampaigns].
  WangiriCampaignsProvider call({
    String? status,
  }) {
    return WangiriCampaignsProvider(
      status: status,
    );
  }

  @override
  WangiriCampaignsProvider getProviderOverride(
    covariant WangiriCampaignsProvider provider,
  ) {
    return call(
      status: provider.status,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'wangiriCampaignsProvider';
}

/// See also [wangiriCampaigns].
class WangiriCampaignsProvider
    extends AutoDisposeFutureProvider<List<WangiriCampaign>> {
  /// See also [wangiriCampaigns].
  WangiriCampaignsProvider({
    String? status,
  }) : this._internal(
          (ref) => wangiriCampaigns(
            ref as WangiriCampaignsRef,
            status: status,
          ),
          from: wangiriCampaignsProvider,
          name: r'wangiriCampaignsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$wangiriCampaignsHash,
          dependencies: WangiriCampaignsFamily._dependencies,
          allTransitiveDependencies:
              WangiriCampaignsFamily._allTransitiveDependencies,
          status: status,
        );

  WangiriCampaignsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final String? status;

  @override
  Override overrideWith(
    FutureOr<List<WangiriCampaign>> Function(WangiriCampaignsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WangiriCampaignsProvider._internal(
        (ref) => create(ref as WangiriCampaignsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<WangiriCampaign>> createElement() {
    return _WangiriCampaignsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WangiriCampaignsProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin WangiriCampaignsRef
    on AutoDisposeFutureProviderRef<List<WangiriCampaign>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _WangiriCampaignsProviderElement
    extends AutoDisposeFutureProviderElement<List<WangiriCampaign>>
    with WangiriCampaignsRef {
  _WangiriCampaignsProviderElement(super.provider);

  @override
  String? get status => (origin as WangiriCampaignsProvider).status;
}

String _$callbackFraudIncidentsHash() =>
    r'f39427ad2143e6eb8f610a9a2b47a71be533f3e8';

/// See also [callbackFraudIncidents].
@ProviderFor(callbackFraudIncidents)
final callbackFraudIncidentsProvider =
    AutoDisposeFutureProvider<List<CallbackFraudIncident>>.internal(
  callbackFraudIncidents,
  name: r'callbackFraudIncidentsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$callbackFraudIncidentsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CallbackFraudIncidentsRef
    = AutoDisposeFutureProviderRef<List<CallbackFraudIncident>>;
String _$cLIVerificationsNotifierHash() =>
    r'947e798f910447953df531416cb5bbd4e37a26b4';

abstract class _$CLIVerificationsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<CLIVerification>> {
  late final bool? spoofingOnly;

  FutureOr<List<CLIVerification>> build({
    bool? spoofingOnly,
  });
}

/// See also [CLIVerificationsNotifier].
@ProviderFor(CLIVerificationsNotifier)
const cLIVerificationsNotifierProvider = CLIVerificationsNotifierFamily();

/// See also [CLIVerificationsNotifier].
class CLIVerificationsNotifierFamily
    extends Family<AsyncValue<List<CLIVerification>>> {
  /// See also [CLIVerificationsNotifier].
  const CLIVerificationsNotifierFamily();

  /// See also [CLIVerificationsNotifier].
  CLIVerificationsNotifierProvider call({
    bool? spoofingOnly,
  }) {
    return CLIVerificationsNotifierProvider(
      spoofingOnly: spoofingOnly,
    );
  }

  @override
  CLIVerificationsNotifierProvider getProviderOverride(
    covariant CLIVerificationsNotifierProvider provider,
  ) {
    return call(
      spoofingOnly: provider.spoofingOnly,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cLIVerificationsNotifierProvider';
}

/// See also [CLIVerificationsNotifier].
class CLIVerificationsNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<CLIVerificationsNotifier,
        List<CLIVerification>> {
  /// See also [CLIVerificationsNotifier].
  CLIVerificationsNotifierProvider({
    bool? spoofingOnly,
  }) : this._internal(
          () => CLIVerificationsNotifier()..spoofingOnly = spoofingOnly,
          from: cLIVerificationsNotifierProvider,
          name: r'cLIVerificationsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cLIVerificationsNotifierHash,
          dependencies: CLIVerificationsNotifierFamily._dependencies,
          allTransitiveDependencies:
              CLIVerificationsNotifierFamily._allTransitiveDependencies,
          spoofingOnly: spoofingOnly,
        );

  CLIVerificationsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.spoofingOnly,
  }) : super.internal();

  final bool? spoofingOnly;

  @override
  FutureOr<List<CLIVerification>> runNotifierBuild(
    covariant CLIVerificationsNotifier notifier,
  ) {
    return notifier.build(
      spoofingOnly: spoofingOnly,
    );
  }

  @override
  Override overrideWith(CLIVerificationsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CLIVerificationsNotifierProvider._internal(
        () => create()..spoofingOnly = spoofingOnly,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        spoofingOnly: spoofingOnly,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CLIVerificationsNotifier,
      List<CLIVerification>> createElement() {
    return _CLIVerificationsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CLIVerificationsNotifierProvider &&
        other.spoofingOnly == spoofingOnly;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, spoofingOnly.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CLIVerificationsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<CLIVerification>> {
  /// The parameter `spoofingOnly` of this provider.
  bool? get spoofingOnly;
}

class _CLIVerificationsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CLIVerificationsNotifier,
        List<CLIVerification>> with CLIVerificationsNotifierRef {
  _CLIVerificationsNotifierProviderElement(super.provider);

  @override
  bool? get spoofingOnly =>
      (origin as CLIVerificationsNotifierProvider).spoofingOnly;
}

String _$iRSFIncidentsNotifierHash() =>
    r'2d54eae2f29c29ddb2113e7913d54867ffc46bd6';

abstract class _$IRSFIncidentsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<IRSFIncident>> {
  late final String? riskLevel;

  FutureOr<List<IRSFIncident>> build({
    String? riskLevel,
  });
}

/// See also [IRSFIncidentsNotifier].
@ProviderFor(IRSFIncidentsNotifier)
const iRSFIncidentsNotifierProvider = IRSFIncidentsNotifierFamily();

/// See also [IRSFIncidentsNotifier].
class IRSFIncidentsNotifierFamily
    extends Family<AsyncValue<List<IRSFIncident>>> {
  /// See also [IRSFIncidentsNotifier].
  const IRSFIncidentsNotifierFamily();

  /// See also [IRSFIncidentsNotifier].
  IRSFIncidentsNotifierProvider call({
    String? riskLevel,
  }) {
    return IRSFIncidentsNotifierProvider(
      riskLevel: riskLevel,
    );
  }

  @override
  IRSFIncidentsNotifierProvider getProviderOverride(
    covariant IRSFIncidentsNotifierProvider provider,
  ) {
    return call(
      riskLevel: provider.riskLevel,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'iRSFIncidentsNotifierProvider';
}

/// See also [IRSFIncidentsNotifier].
class IRSFIncidentsNotifierProvider
    extends AutoDisposeAsyncNotifierProviderImpl<IRSFIncidentsNotifier,
        List<IRSFIncident>> {
  /// See also [IRSFIncidentsNotifier].
  IRSFIncidentsNotifierProvider({
    String? riskLevel,
  }) : this._internal(
          () => IRSFIncidentsNotifier()..riskLevel = riskLevel,
          from: iRSFIncidentsNotifierProvider,
          name: r'iRSFIncidentsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$iRSFIncidentsNotifierHash,
          dependencies: IRSFIncidentsNotifierFamily._dependencies,
          allTransitiveDependencies:
              IRSFIncidentsNotifierFamily._allTransitiveDependencies,
          riskLevel: riskLevel,
        );

  IRSFIncidentsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.riskLevel,
  }) : super.internal();

  final String? riskLevel;

  @override
  FutureOr<List<IRSFIncident>> runNotifierBuild(
    covariant IRSFIncidentsNotifier notifier,
  ) {
    return notifier.build(
      riskLevel: riskLevel,
    );
  }

  @override
  Override overrideWith(IRSFIncidentsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: IRSFIncidentsNotifierProvider._internal(
        () => create()..riskLevel = riskLevel,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        riskLevel: riskLevel,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<IRSFIncidentsNotifier,
      List<IRSFIncident>> createElement() {
    return _IRSFIncidentsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IRSFIncidentsNotifierProvider &&
        other.riskLevel == riskLevel;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, riskLevel.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin IRSFIncidentsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<IRSFIncident>> {
  /// The parameter `riskLevel` of this provider.
  String? get riskLevel;
}

class _IRSFIncidentsNotifierProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<IRSFIncidentsNotifier,
        List<IRSFIncident>> with IRSFIncidentsNotifierRef {
  _IRSFIncidentsNotifierProviderElement(super.provider);

  @override
  String? get riskLevel => (origin as IRSFIncidentsNotifierProvider).riskLevel;
}

String _$wangiriIncidentsNotifierHash() =>
    r'fb1f662a8637e8b8e2218e86ae1ccd13e6f62823';

/// See also [WangiriIncidentsNotifier].
@ProviderFor(WangiriIncidentsNotifier)
final wangiriIncidentsNotifierProvider = AutoDisposeAsyncNotifierProvider<
    WangiriIncidentsNotifier, List<WangiriIncident>>.internal(
  WangiriIncidentsNotifier.new,
  name: r'wangiriIncidentsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$wangiriIncidentsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$WangiriIncidentsNotifier
    = AutoDisposeAsyncNotifier<List<WangiriIncident>>;
String _$blockNumberNotifierHash() =>
    r'e4dfffae52f393ce0e1ecf4ab181e1e707462548';

/// See also [BlockNumberNotifier].
@ProviderFor(BlockNumberNotifier)
final blockNumberNotifierProvider =
    AutoDisposeNotifierProvider<BlockNumberNotifier, AsyncValue<void>>.internal(
  BlockNumberNotifier.new,
  name: r'blockNumberNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$blockNumberNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$BlockNumberNotifier = AutoDisposeNotifier<AsyncValue<void>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
