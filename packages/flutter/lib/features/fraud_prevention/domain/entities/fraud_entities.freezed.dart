// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fraud_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CLIVerification _$CLIVerificationFromJson(Map<String, dynamic> json) {
  return _CLIVerification.fromJson(json);
}

/// @nodoc
mixin _$CLIVerification {
  String get id => throw _privateConstructorUsedError;
  String get presentedCli => throw _privateConstructorUsedError;
  String? get actualCli => throw _privateConstructorUsedError;
  String? get networkCli => throw _privateConstructorUsedError;
  bool get spoofingDetected => throw _privateConstructorUsedError;
  String? get spoofingType => throw _privateConstructorUsedError;
  double? get confidenceScore => throw _privateConstructorUsedError;
  String? get verificationMethod => throw _privateConstructorUsedError;
  Map<String, dynamic>? get ss7Analysis => throw _privateConstructorUsedError;
  Map<String, dynamic>? get stirShakenResult =>
      throw _privateConstructorUsedError;
  String? get carrierId => throw _privateConstructorUsedError;
  String? get callDirection => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CLIVerificationCopyWith<CLIVerification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CLIVerificationCopyWith<$Res> {
  factory $CLIVerificationCopyWith(
          CLIVerification value, $Res Function(CLIVerification) then) =
      _$CLIVerificationCopyWithImpl<$Res, CLIVerification>;
  @useResult
  $Res call(
      {String id,
      String presentedCli,
      String? actualCli,
      String? networkCli,
      bool spoofingDetected,
      String? spoofingType,
      double? confidenceScore,
      String? verificationMethod,
      Map<String, dynamic>? ss7Analysis,
      Map<String, dynamic>? stirShakenResult,
      String? carrierId,
      String? callDirection,
      DateTime createdAt});
}

/// @nodoc
class _$CLIVerificationCopyWithImpl<$Res, $Val extends CLIVerification>
    implements $CLIVerificationCopyWith<$Res> {
  _$CLIVerificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? presentedCli = null,
    Object? actualCli = freezed,
    Object? networkCli = freezed,
    Object? spoofingDetected = null,
    Object? spoofingType = freezed,
    Object? confidenceScore = freezed,
    Object? verificationMethod = freezed,
    Object? ss7Analysis = freezed,
    Object? stirShakenResult = freezed,
    Object? carrierId = freezed,
    Object? callDirection = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      presentedCli: null == presentedCli
          ? _value.presentedCli
          : presentedCli // ignore: cast_nullable_to_non_nullable
              as String,
      actualCli: freezed == actualCli
          ? _value.actualCli
          : actualCli // ignore: cast_nullable_to_non_nullable
              as String?,
      networkCli: freezed == networkCli
          ? _value.networkCli
          : networkCli // ignore: cast_nullable_to_non_nullable
              as String?,
      spoofingDetected: null == spoofingDetected
          ? _value.spoofingDetected
          : spoofingDetected // ignore: cast_nullable_to_non_nullable
              as bool,
      spoofingType: freezed == spoofingType
          ? _value.spoofingType
          : spoofingType // ignore: cast_nullable_to_non_nullable
              as String?,
      confidenceScore: freezed == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      verificationMethod: freezed == verificationMethod
          ? _value.verificationMethod
          : verificationMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      ss7Analysis: freezed == ss7Analysis
          ? _value.ss7Analysis
          : ss7Analysis // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      stirShakenResult: freezed == stirShakenResult
          ? _value.stirShakenResult
          : stirShakenResult // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      carrierId: freezed == carrierId
          ? _value.carrierId
          : carrierId // ignore: cast_nullable_to_non_nullable
              as String?,
      callDirection: freezed == callDirection
          ? _value.callDirection
          : callDirection // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CLIVerificationImplCopyWith<$Res>
    implements $CLIVerificationCopyWith<$Res> {
  factory _$$CLIVerificationImplCopyWith(_$CLIVerificationImpl value,
          $Res Function(_$CLIVerificationImpl) then) =
      __$$CLIVerificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String presentedCli,
      String? actualCli,
      String? networkCli,
      bool spoofingDetected,
      String? spoofingType,
      double? confidenceScore,
      String? verificationMethod,
      Map<String, dynamic>? ss7Analysis,
      Map<String, dynamic>? stirShakenResult,
      String? carrierId,
      String? callDirection,
      DateTime createdAt});
}

/// @nodoc
class __$$CLIVerificationImplCopyWithImpl<$Res>
    extends _$CLIVerificationCopyWithImpl<$Res, _$CLIVerificationImpl>
    implements _$$CLIVerificationImplCopyWith<$Res> {
  __$$CLIVerificationImplCopyWithImpl(
      _$CLIVerificationImpl _value, $Res Function(_$CLIVerificationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? presentedCli = null,
    Object? actualCli = freezed,
    Object? networkCli = freezed,
    Object? spoofingDetected = null,
    Object? spoofingType = freezed,
    Object? confidenceScore = freezed,
    Object? verificationMethod = freezed,
    Object? ss7Analysis = freezed,
    Object? stirShakenResult = freezed,
    Object? carrierId = freezed,
    Object? callDirection = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$CLIVerificationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      presentedCli: null == presentedCli
          ? _value.presentedCli
          : presentedCli // ignore: cast_nullable_to_non_nullable
              as String,
      actualCli: freezed == actualCli
          ? _value.actualCli
          : actualCli // ignore: cast_nullable_to_non_nullable
              as String?,
      networkCli: freezed == networkCli
          ? _value.networkCli
          : networkCli // ignore: cast_nullable_to_non_nullable
              as String?,
      spoofingDetected: null == spoofingDetected
          ? _value.spoofingDetected
          : spoofingDetected // ignore: cast_nullable_to_non_nullable
              as bool,
      spoofingType: freezed == spoofingType
          ? _value.spoofingType
          : spoofingType // ignore: cast_nullable_to_non_nullable
              as String?,
      confidenceScore: freezed == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double?,
      verificationMethod: freezed == verificationMethod
          ? _value.verificationMethod
          : verificationMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      ss7Analysis: freezed == ss7Analysis
          ? _value._ss7Analysis
          : ss7Analysis // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      stirShakenResult: freezed == stirShakenResult
          ? _value._stirShakenResult
          : stirShakenResult // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      carrierId: freezed == carrierId
          ? _value.carrierId
          : carrierId // ignore: cast_nullable_to_non_nullable
              as String?,
      callDirection: freezed == callDirection
          ? _value.callDirection
          : callDirection // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CLIVerificationImpl implements _CLIVerification {
  const _$CLIVerificationImpl(
      {required this.id,
      required this.presentedCli,
      this.actualCli,
      this.networkCli,
      required this.spoofingDetected,
      this.spoofingType,
      this.confidenceScore,
      this.verificationMethod,
      final Map<String, dynamic>? ss7Analysis,
      final Map<String, dynamic>? stirShakenResult,
      this.carrierId,
      this.callDirection,
      required this.createdAt})
      : _ss7Analysis = ss7Analysis,
        _stirShakenResult = stirShakenResult;

  factory _$CLIVerificationImpl.fromJson(Map<String, dynamic> json) =>
      _$$CLIVerificationImplFromJson(json);

  @override
  final String id;
  @override
  final String presentedCli;
  @override
  final String? actualCli;
  @override
  final String? networkCli;
  @override
  final bool spoofingDetected;
  @override
  final String? spoofingType;
  @override
  final double? confidenceScore;
  @override
  final String? verificationMethod;
  final Map<String, dynamic>? _ss7Analysis;
  @override
  Map<String, dynamic>? get ss7Analysis {
    final value = _ss7Analysis;
    if (value == null) return null;
    if (_ss7Analysis is EqualUnmodifiableMapView) return _ss7Analysis;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final Map<String, dynamic>? _stirShakenResult;
  @override
  Map<String, dynamic>? get stirShakenResult {
    final value = _stirShakenResult;
    if (value == null) return null;
    if (_stirShakenResult is EqualUnmodifiableMapView) return _stirShakenResult;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? carrierId;
  @override
  final String? callDirection;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'CLIVerification(id: $id, presentedCli: $presentedCli, actualCli: $actualCli, networkCli: $networkCli, spoofingDetected: $spoofingDetected, spoofingType: $spoofingType, confidenceScore: $confidenceScore, verificationMethod: $verificationMethod, ss7Analysis: $ss7Analysis, stirShakenResult: $stirShakenResult, carrierId: $carrierId, callDirection: $callDirection, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CLIVerificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.presentedCli, presentedCli) ||
                other.presentedCli == presentedCli) &&
            (identical(other.actualCli, actualCli) ||
                other.actualCli == actualCli) &&
            (identical(other.networkCli, networkCli) ||
                other.networkCli == networkCli) &&
            (identical(other.spoofingDetected, spoofingDetected) ||
                other.spoofingDetected == spoofingDetected) &&
            (identical(other.spoofingType, spoofingType) ||
                other.spoofingType == spoofingType) &&
            (identical(other.confidenceScore, confidenceScore) ||
                other.confidenceScore == confidenceScore) &&
            (identical(other.verificationMethod, verificationMethod) ||
                other.verificationMethod == verificationMethod) &&
            const DeepCollectionEquality()
                .equals(other._ss7Analysis, _ss7Analysis) &&
            const DeepCollectionEquality()
                .equals(other._stirShakenResult, _stirShakenResult) &&
            (identical(other.carrierId, carrierId) ||
                other.carrierId == carrierId) &&
            (identical(other.callDirection, callDirection) ||
                other.callDirection == callDirection) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      presentedCli,
      actualCli,
      networkCli,
      spoofingDetected,
      spoofingType,
      confidenceScore,
      verificationMethod,
      const DeepCollectionEquality().hash(_ss7Analysis),
      const DeepCollectionEquality().hash(_stirShakenResult),
      carrierId,
      callDirection,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CLIVerificationImplCopyWith<_$CLIVerificationImpl> get copyWith =>
      __$$CLIVerificationImplCopyWithImpl<_$CLIVerificationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CLIVerificationImplToJson(
      this,
    );
  }
}

abstract class _CLIVerification implements CLIVerification {
  const factory _CLIVerification(
      {required final String id,
      required final String presentedCli,
      final String? actualCli,
      final String? networkCli,
      required final bool spoofingDetected,
      final String? spoofingType,
      final double? confidenceScore,
      final String? verificationMethod,
      final Map<String, dynamic>? ss7Analysis,
      final Map<String, dynamic>? stirShakenResult,
      final String? carrierId,
      final String? callDirection,
      required final DateTime createdAt}) = _$CLIVerificationImpl;

  factory _CLIVerification.fromJson(Map<String, dynamic> json) =
      _$CLIVerificationImpl.fromJson;

  @override
  String get id;
  @override
  String get presentedCli;
  @override
  String? get actualCli;
  @override
  String? get networkCli;
  @override
  bool get spoofingDetected;
  @override
  String? get spoofingType;
  @override
  double? get confidenceScore;
  @override
  String? get verificationMethod;
  @override
  Map<String, dynamic>? get ss7Analysis;
  @override
  Map<String, dynamic>? get stirShakenResult;
  @override
  String? get carrierId;
  @override
  String? get callDirection;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$CLIVerificationImplCopyWith<_$CLIVerificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$SpoofingType {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SpoofingTypeCopyWith<$Res> {
  factory $SpoofingTypeCopyWith(
          SpoofingType value, $Res Function(SpoofingType) then) =
      _$SpoofingTypeCopyWithImpl<$Res, SpoofingType>;
}

/// @nodoc
class _$SpoofingTypeCopyWithImpl<$Res, $Val extends SpoofingType>
    implements $SpoofingTypeCopyWith<$Res> {
  _$SpoofingTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$CLIManipulationImplCopyWith<$Res> {
  factory _$$CLIManipulationImplCopyWith(_$CLIManipulationImpl value,
          $Res Function(_$CLIManipulationImpl) then) =
      __$$CLIManipulationImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CLIManipulationImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$CLIManipulationImpl>
    implements _$$CLIManipulationImplCopyWith<$Res> {
  __$$CLIManipulationImplCopyWithImpl(
      _$CLIManipulationImpl _value, $Res Function(_$CLIManipulationImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$CLIManipulationImpl implements _CLIManipulation {
  const _$CLIManipulationImpl();

  @override
  String toString() {
    return 'SpoofingType.cliManipulation()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$CLIManipulationImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return cliManipulation();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return cliManipulation?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (cliManipulation != null) {
      return cliManipulation();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return cliManipulation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return cliManipulation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (cliManipulation != null) {
      return cliManipulation(this);
    }
    return orElse();
  }
}

abstract class _CLIManipulation implements SpoofingType {
  const factory _CLIManipulation() = _$CLIManipulationImpl;
}

/// @nodoc
abstract class _$$NumberSubstitutionImplCopyWith<$Res> {
  factory _$$NumberSubstitutionImplCopyWith(_$NumberSubstitutionImpl value,
          $Res Function(_$NumberSubstitutionImpl) then) =
      __$$NumberSubstitutionImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NumberSubstitutionImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$NumberSubstitutionImpl>
    implements _$$NumberSubstitutionImplCopyWith<$Res> {
  __$$NumberSubstitutionImplCopyWithImpl(_$NumberSubstitutionImpl _value,
      $Res Function(_$NumberSubstitutionImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$NumberSubstitutionImpl implements _NumberSubstitution {
  const _$NumberSubstitutionImpl();

  @override
  String toString() {
    return 'SpoofingType.numberSubstitution()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NumberSubstitutionImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return numberSubstitution();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return numberSubstitution?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (numberSubstitution != null) {
      return numberSubstitution();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return numberSubstitution(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return numberSubstitution?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (numberSubstitution != null) {
      return numberSubstitution(this);
    }
    return orElse();
  }
}

abstract class _NumberSubstitution implements SpoofingType {
  const factory _NumberSubstitution() = _$NumberSubstitutionImpl;
}

/// @nodoc
abstract class _$$NeighborSpoofingImplCopyWith<$Res> {
  factory _$$NeighborSpoofingImplCopyWith(_$NeighborSpoofingImpl value,
          $Res Function(_$NeighborSpoofingImpl) then) =
      __$$NeighborSpoofingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NeighborSpoofingImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$NeighborSpoofingImpl>
    implements _$$NeighborSpoofingImplCopyWith<$Res> {
  __$$NeighborSpoofingImplCopyWithImpl(_$NeighborSpoofingImpl _value,
      $Res Function(_$NeighborSpoofingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$NeighborSpoofingImpl implements _NeighborSpoofing {
  const _$NeighborSpoofingImpl();

  @override
  String toString() {
    return 'SpoofingType.neighborSpoofing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NeighborSpoofingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return neighborSpoofing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return neighborSpoofing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (neighborSpoofing != null) {
      return neighborSpoofing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return neighborSpoofing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return neighborSpoofing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (neighborSpoofing != null) {
      return neighborSpoofing(this);
    }
    return orElse();
  }
}

abstract class _NeighborSpoofing implements SpoofingType {
  const factory _NeighborSpoofing() = _$NeighborSpoofingImpl;
}

/// @nodoc
abstract class _$$TollFreeSpoofingImplCopyWith<$Res> {
  factory _$$TollFreeSpoofingImplCopyWith(_$TollFreeSpoofingImpl value,
          $Res Function(_$TollFreeSpoofingImpl) then) =
      __$$TollFreeSpoofingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$TollFreeSpoofingImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$TollFreeSpoofingImpl>
    implements _$$TollFreeSpoofingImplCopyWith<$Res> {
  __$$TollFreeSpoofingImplCopyWithImpl(_$TollFreeSpoofingImpl _value,
      $Res Function(_$TollFreeSpoofingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$TollFreeSpoofingImpl implements _TollFreeSpoofing {
  const _$TollFreeSpoofingImpl();

  @override
  String toString() {
    return 'SpoofingType.tollFreeSpoofing()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$TollFreeSpoofingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return tollFreeSpoofing();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return tollFreeSpoofing?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (tollFreeSpoofing != null) {
      return tollFreeSpoofing();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return tollFreeSpoofing(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return tollFreeSpoofing?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (tollFreeSpoofing != null) {
      return tollFreeSpoofing(this);
    }
    return orElse();
  }
}

abstract class _TollFreeSpoofing implements SpoofingType {
  const factory _TollFreeSpoofing() = _$TollFreeSpoofingImpl;
}

/// @nodoc
abstract class _$$GovernmentImpersonationImplCopyWith<$Res> {
  factory _$$GovernmentImpersonationImplCopyWith(
          _$GovernmentImpersonationImpl value,
          $Res Function(_$GovernmentImpersonationImpl) then) =
      __$$GovernmentImpersonationImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$GovernmentImpersonationImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$GovernmentImpersonationImpl>
    implements _$$GovernmentImpersonationImplCopyWith<$Res> {
  __$$GovernmentImpersonationImplCopyWithImpl(
      _$GovernmentImpersonationImpl _value,
      $Res Function(_$GovernmentImpersonationImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$GovernmentImpersonationImpl implements _GovernmentImpersonation {
  const _$GovernmentImpersonationImpl();

  @override
  String toString() {
    return 'SpoofingType.governmentImpersonation()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GovernmentImpersonationImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return governmentImpersonation();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return governmentImpersonation?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (governmentImpersonation != null) {
      return governmentImpersonation();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return governmentImpersonation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return governmentImpersonation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (governmentImpersonation != null) {
      return governmentImpersonation(this);
    }
    return orElse();
  }
}

abstract class _GovernmentImpersonation implements SpoofingType {
  const factory _GovernmentImpersonation() = _$GovernmentImpersonationImpl;
}

/// @nodoc
abstract class _$$BankImpersonationImplCopyWith<$Res> {
  factory _$$BankImpersonationImplCopyWith(_$BankImpersonationImpl value,
          $Res Function(_$BankImpersonationImpl) then) =
      __$$BankImpersonationImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$BankImpersonationImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$BankImpersonationImpl>
    implements _$$BankImpersonationImplCopyWith<$Res> {
  __$$BankImpersonationImplCopyWithImpl(_$BankImpersonationImpl _value,
      $Res Function(_$BankImpersonationImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$BankImpersonationImpl implements _BankImpersonation {
  const _$BankImpersonationImpl();

  @override
  String toString() {
    return 'SpoofingType.bankImpersonation()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$BankImpersonationImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return bankImpersonation();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return bankImpersonation?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (bankImpersonation != null) {
      return bankImpersonation();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return bankImpersonation(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return bankImpersonation?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (bankImpersonation != null) {
      return bankImpersonation(this);
    }
    return orElse();
  }
}

abstract class _BankImpersonation implements SpoofingType {
  const factory _BankImpersonation() = _$BankImpersonationImpl;
}

/// @nodoc
abstract class _$$NoneImplCopyWith<$Res> {
  factory _$$NoneImplCopyWith(
          _$NoneImpl value, $Res Function(_$NoneImpl) then) =
      __$$NoneImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$NoneImplCopyWithImpl<$Res>
    extends _$SpoofingTypeCopyWithImpl<$Res, _$NoneImpl>
    implements _$$NoneImplCopyWith<$Res> {
  __$$NoneImplCopyWithImpl(_$NoneImpl _value, $Res Function(_$NoneImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$NoneImpl implements _None {
  const _$NoneImpl();

  @override
  String toString() {
    return 'SpoofingType.none()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$NoneImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() cliManipulation,
    required TResult Function() numberSubstitution,
    required TResult Function() neighborSpoofing,
    required TResult Function() tollFreeSpoofing,
    required TResult Function() governmentImpersonation,
    required TResult Function() bankImpersonation,
    required TResult Function() none,
  }) {
    return none();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? cliManipulation,
    TResult? Function()? numberSubstitution,
    TResult? Function()? neighborSpoofing,
    TResult? Function()? tollFreeSpoofing,
    TResult? Function()? governmentImpersonation,
    TResult? Function()? bankImpersonation,
    TResult? Function()? none,
  }) {
    return none?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? cliManipulation,
    TResult Function()? numberSubstitution,
    TResult Function()? neighborSpoofing,
    TResult Function()? tollFreeSpoofing,
    TResult Function()? governmentImpersonation,
    TResult Function()? bankImpersonation,
    TResult Function()? none,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CLIManipulation value) cliManipulation,
    required TResult Function(_NumberSubstitution value) numberSubstitution,
    required TResult Function(_NeighborSpoofing value) neighborSpoofing,
    required TResult Function(_TollFreeSpoofing value) tollFreeSpoofing,
    required TResult Function(_GovernmentImpersonation value)
        governmentImpersonation,
    required TResult Function(_BankImpersonation value) bankImpersonation,
    required TResult Function(_None value) none,
  }) {
    return none(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CLIManipulation value)? cliManipulation,
    TResult? Function(_NumberSubstitution value)? numberSubstitution,
    TResult? Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult? Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult? Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult? Function(_BankImpersonation value)? bankImpersonation,
    TResult? Function(_None value)? none,
  }) {
    return none?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CLIManipulation value)? cliManipulation,
    TResult Function(_NumberSubstitution value)? numberSubstitution,
    TResult Function(_NeighborSpoofing value)? neighborSpoofing,
    TResult Function(_TollFreeSpoofing value)? tollFreeSpoofing,
    TResult Function(_GovernmentImpersonation value)? governmentImpersonation,
    TResult Function(_BankImpersonation value)? bankImpersonation,
    TResult Function(_None value)? none,
    required TResult orElse(),
  }) {
    if (none != null) {
      return none(this);
    }
    return orElse();
  }
}

abstract class _None implements SpoofingType {
  const factory _None() = _$NoneImpl;
}

IRSFIncident _$IRSFIncidentFromJson(Map<String, dynamic> json) {
  return _IRSFIncident.fromJson(json);
}

/// @nodoc
mixin _$IRSFIncident {
  String get id => throw _privateConstructorUsedError;
  String get sourceNumber => throw _privateConstructorUsedError;
  String get destinationNumber => throw _privateConstructorUsedError;
  String get destinationCountry => throw _privateConstructorUsedError;
  String? get destinationPrefix => throw _privateConstructorUsedError;
  double get riskScore => throw _privateConstructorUsedError;
  Map<String, dynamic> get irsfIndicators => throw _privateConstructorUsedError;
  String? get detectionMethod => throw _privateConstructorUsedError;
  String? get matchedPatternId => throw _privateConstructorUsedError;
  int? get callDurationSeconds => throw _privateConstructorUsedError;
  double? get ratePerMinute => throw _privateConstructorUsedError;
  double? get estimatedLoss => throw _privateConstructorUsedError;
  String? get actionTaken => throw _privateConstructorUsedError;
  DateTime? get blockedAt => throw _privateConstructorUsedError;
  String? get carrierId => throw _privateConstructorUsedError;
  String? get subscriberId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IRSFIncidentCopyWith<IRSFIncident> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IRSFIncidentCopyWith<$Res> {
  factory $IRSFIncidentCopyWith(
          IRSFIncident value, $Res Function(IRSFIncident) then) =
      _$IRSFIncidentCopyWithImpl<$Res, IRSFIncident>;
  @useResult
  $Res call(
      {String id,
      String sourceNumber,
      String destinationNumber,
      String destinationCountry,
      String? destinationPrefix,
      double riskScore,
      Map<String, dynamic> irsfIndicators,
      String? detectionMethod,
      String? matchedPatternId,
      int? callDurationSeconds,
      double? ratePerMinute,
      double? estimatedLoss,
      String? actionTaken,
      DateTime? blockedAt,
      String? carrierId,
      String? subscriberId,
      DateTime createdAt});
}

/// @nodoc
class _$IRSFIncidentCopyWithImpl<$Res, $Val extends IRSFIncident>
    implements $IRSFIncidentCopyWith<$Res> {
  _$IRSFIncidentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceNumber = null,
    Object? destinationNumber = null,
    Object? destinationCountry = null,
    Object? destinationPrefix = freezed,
    Object? riskScore = null,
    Object? irsfIndicators = null,
    Object? detectionMethod = freezed,
    Object? matchedPatternId = freezed,
    Object? callDurationSeconds = freezed,
    Object? ratePerMinute = freezed,
    Object? estimatedLoss = freezed,
    Object? actionTaken = freezed,
    Object? blockedAt = freezed,
    Object? carrierId = freezed,
    Object? subscriberId = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceNumber: null == sourceNumber
          ? _value.sourceNumber
          : sourceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      destinationNumber: null == destinationNumber
          ? _value.destinationNumber
          : destinationNumber // ignore: cast_nullable_to_non_nullable
              as String,
      destinationCountry: null == destinationCountry
          ? _value.destinationCountry
          : destinationCountry // ignore: cast_nullable_to_non_nullable
              as String,
      destinationPrefix: freezed == destinationPrefix
          ? _value.destinationPrefix
          : destinationPrefix // ignore: cast_nullable_to_non_nullable
              as String?,
      riskScore: null == riskScore
          ? _value.riskScore
          : riskScore // ignore: cast_nullable_to_non_nullable
              as double,
      irsfIndicators: null == irsfIndicators
          ? _value.irsfIndicators
          : irsfIndicators // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      detectionMethod: freezed == detectionMethod
          ? _value.detectionMethod
          : detectionMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      matchedPatternId: freezed == matchedPatternId
          ? _value.matchedPatternId
          : matchedPatternId // ignore: cast_nullable_to_non_nullable
              as String?,
      callDurationSeconds: freezed == callDurationSeconds
          ? _value.callDurationSeconds
          : callDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      ratePerMinute: freezed == ratePerMinute
          ? _value.ratePerMinute
          : ratePerMinute // ignore: cast_nullable_to_non_nullable
              as double?,
      estimatedLoss: freezed == estimatedLoss
          ? _value.estimatedLoss
          : estimatedLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      actionTaken: freezed == actionTaken
          ? _value.actionTaken
          : actionTaken // ignore: cast_nullable_to_non_nullable
              as String?,
      blockedAt: freezed == blockedAt
          ? _value.blockedAt
          : blockedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      carrierId: freezed == carrierId
          ? _value.carrierId
          : carrierId // ignore: cast_nullable_to_non_nullable
              as String?,
      subscriberId: freezed == subscriberId
          ? _value.subscriberId
          : subscriberId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IRSFIncidentImplCopyWith<$Res>
    implements $IRSFIncidentCopyWith<$Res> {
  factory _$$IRSFIncidentImplCopyWith(
          _$IRSFIncidentImpl value, $Res Function(_$IRSFIncidentImpl) then) =
      __$$IRSFIncidentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sourceNumber,
      String destinationNumber,
      String destinationCountry,
      String? destinationPrefix,
      double riskScore,
      Map<String, dynamic> irsfIndicators,
      String? detectionMethod,
      String? matchedPatternId,
      int? callDurationSeconds,
      double? ratePerMinute,
      double? estimatedLoss,
      String? actionTaken,
      DateTime? blockedAt,
      String? carrierId,
      String? subscriberId,
      DateTime createdAt});
}

/// @nodoc
class __$$IRSFIncidentImplCopyWithImpl<$Res>
    extends _$IRSFIncidentCopyWithImpl<$Res, _$IRSFIncidentImpl>
    implements _$$IRSFIncidentImplCopyWith<$Res> {
  __$$IRSFIncidentImplCopyWithImpl(
      _$IRSFIncidentImpl _value, $Res Function(_$IRSFIncidentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceNumber = null,
    Object? destinationNumber = null,
    Object? destinationCountry = null,
    Object? destinationPrefix = freezed,
    Object? riskScore = null,
    Object? irsfIndicators = null,
    Object? detectionMethod = freezed,
    Object? matchedPatternId = freezed,
    Object? callDurationSeconds = freezed,
    Object? ratePerMinute = freezed,
    Object? estimatedLoss = freezed,
    Object? actionTaken = freezed,
    Object? blockedAt = freezed,
    Object? carrierId = freezed,
    Object? subscriberId = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$IRSFIncidentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceNumber: null == sourceNumber
          ? _value.sourceNumber
          : sourceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      destinationNumber: null == destinationNumber
          ? _value.destinationNumber
          : destinationNumber // ignore: cast_nullable_to_non_nullable
              as String,
      destinationCountry: null == destinationCountry
          ? _value.destinationCountry
          : destinationCountry // ignore: cast_nullable_to_non_nullable
              as String,
      destinationPrefix: freezed == destinationPrefix
          ? _value.destinationPrefix
          : destinationPrefix // ignore: cast_nullable_to_non_nullable
              as String?,
      riskScore: null == riskScore
          ? _value.riskScore
          : riskScore // ignore: cast_nullable_to_non_nullable
              as double,
      irsfIndicators: null == irsfIndicators
          ? _value._irsfIndicators
          : irsfIndicators // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      detectionMethod: freezed == detectionMethod
          ? _value.detectionMethod
          : detectionMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      matchedPatternId: freezed == matchedPatternId
          ? _value.matchedPatternId
          : matchedPatternId // ignore: cast_nullable_to_non_nullable
              as String?,
      callDurationSeconds: freezed == callDurationSeconds
          ? _value.callDurationSeconds
          : callDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      ratePerMinute: freezed == ratePerMinute
          ? _value.ratePerMinute
          : ratePerMinute // ignore: cast_nullable_to_non_nullable
              as double?,
      estimatedLoss: freezed == estimatedLoss
          ? _value.estimatedLoss
          : estimatedLoss // ignore: cast_nullable_to_non_nullable
              as double?,
      actionTaken: freezed == actionTaken
          ? _value.actionTaken
          : actionTaken // ignore: cast_nullable_to_non_nullable
              as String?,
      blockedAt: freezed == blockedAt
          ? _value.blockedAt
          : blockedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      carrierId: freezed == carrierId
          ? _value.carrierId
          : carrierId // ignore: cast_nullable_to_non_nullable
              as String?,
      subscriberId: freezed == subscriberId
          ? _value.subscriberId
          : subscriberId // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IRSFIncidentImpl implements _IRSFIncident {
  const _$IRSFIncidentImpl(
      {required this.id,
      required this.sourceNumber,
      required this.destinationNumber,
      required this.destinationCountry,
      this.destinationPrefix,
      required this.riskScore,
      required final Map<String, dynamic> irsfIndicators,
      this.detectionMethod,
      this.matchedPatternId,
      this.callDurationSeconds,
      this.ratePerMinute,
      this.estimatedLoss,
      this.actionTaken,
      this.blockedAt,
      this.carrierId,
      this.subscriberId,
      required this.createdAt})
      : _irsfIndicators = irsfIndicators;

  factory _$IRSFIncidentImpl.fromJson(Map<String, dynamic> json) =>
      _$$IRSFIncidentImplFromJson(json);

  @override
  final String id;
  @override
  final String sourceNumber;
  @override
  final String destinationNumber;
  @override
  final String destinationCountry;
  @override
  final String? destinationPrefix;
  @override
  final double riskScore;
  final Map<String, dynamic> _irsfIndicators;
  @override
  Map<String, dynamic> get irsfIndicators {
    if (_irsfIndicators is EqualUnmodifiableMapView) return _irsfIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_irsfIndicators);
  }

  @override
  final String? detectionMethod;
  @override
  final String? matchedPatternId;
  @override
  final int? callDurationSeconds;
  @override
  final double? ratePerMinute;
  @override
  final double? estimatedLoss;
  @override
  final String? actionTaken;
  @override
  final DateTime? blockedAt;
  @override
  final String? carrierId;
  @override
  final String? subscriberId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'IRSFIncident(id: $id, sourceNumber: $sourceNumber, destinationNumber: $destinationNumber, destinationCountry: $destinationCountry, destinationPrefix: $destinationPrefix, riskScore: $riskScore, irsfIndicators: $irsfIndicators, detectionMethod: $detectionMethod, matchedPatternId: $matchedPatternId, callDurationSeconds: $callDurationSeconds, ratePerMinute: $ratePerMinute, estimatedLoss: $estimatedLoss, actionTaken: $actionTaken, blockedAt: $blockedAt, carrierId: $carrierId, subscriberId: $subscriberId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IRSFIncidentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceNumber, sourceNumber) ||
                other.sourceNumber == sourceNumber) &&
            (identical(other.destinationNumber, destinationNumber) ||
                other.destinationNumber == destinationNumber) &&
            (identical(other.destinationCountry, destinationCountry) ||
                other.destinationCountry == destinationCountry) &&
            (identical(other.destinationPrefix, destinationPrefix) ||
                other.destinationPrefix == destinationPrefix) &&
            (identical(other.riskScore, riskScore) ||
                other.riskScore == riskScore) &&
            const DeepCollectionEquality()
                .equals(other._irsfIndicators, _irsfIndicators) &&
            (identical(other.detectionMethod, detectionMethod) ||
                other.detectionMethod == detectionMethod) &&
            (identical(other.matchedPatternId, matchedPatternId) ||
                other.matchedPatternId == matchedPatternId) &&
            (identical(other.callDurationSeconds, callDurationSeconds) ||
                other.callDurationSeconds == callDurationSeconds) &&
            (identical(other.ratePerMinute, ratePerMinute) ||
                other.ratePerMinute == ratePerMinute) &&
            (identical(other.estimatedLoss, estimatedLoss) ||
                other.estimatedLoss == estimatedLoss) &&
            (identical(other.actionTaken, actionTaken) ||
                other.actionTaken == actionTaken) &&
            (identical(other.blockedAt, blockedAt) ||
                other.blockedAt == blockedAt) &&
            (identical(other.carrierId, carrierId) ||
                other.carrierId == carrierId) &&
            (identical(other.subscriberId, subscriberId) ||
                other.subscriberId == subscriberId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sourceNumber,
      destinationNumber,
      destinationCountry,
      destinationPrefix,
      riskScore,
      const DeepCollectionEquality().hash(_irsfIndicators),
      detectionMethod,
      matchedPatternId,
      callDurationSeconds,
      ratePerMinute,
      estimatedLoss,
      actionTaken,
      blockedAt,
      carrierId,
      subscriberId,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IRSFIncidentImplCopyWith<_$IRSFIncidentImpl> get copyWith =>
      __$$IRSFIncidentImplCopyWithImpl<_$IRSFIncidentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IRSFIncidentImplToJson(
      this,
    );
  }
}

abstract class _IRSFIncident implements IRSFIncident {
  const factory _IRSFIncident(
      {required final String id,
      required final String sourceNumber,
      required final String destinationNumber,
      required final String destinationCountry,
      final String? destinationPrefix,
      required final double riskScore,
      required final Map<String, dynamic> irsfIndicators,
      final String? detectionMethod,
      final String? matchedPatternId,
      final int? callDurationSeconds,
      final double? ratePerMinute,
      final double? estimatedLoss,
      final String? actionTaken,
      final DateTime? blockedAt,
      final String? carrierId,
      final String? subscriberId,
      required final DateTime createdAt}) = _$IRSFIncidentImpl;

  factory _IRSFIncident.fromJson(Map<String, dynamic> json) =
      _$IRSFIncidentImpl.fromJson;

  @override
  String get id;
  @override
  String get sourceNumber;
  @override
  String get destinationNumber;
  @override
  String get destinationCountry;
  @override
  String? get destinationPrefix;
  @override
  double get riskScore;
  @override
  Map<String, dynamic> get irsfIndicators;
  @override
  String? get detectionMethod;
  @override
  String? get matchedPatternId;
  @override
  int? get callDurationSeconds;
  @override
  double? get ratePerMinute;
  @override
  double? get estimatedLoss;
  @override
  String? get actionTaken;
  @override
  DateTime? get blockedAt;
  @override
  String? get carrierId;
  @override
  String? get subscriberId;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$IRSFIncidentImplCopyWith<_$IRSFIncidentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

IRSFDestination _$IRSFDestinationFromJson(Map<String, dynamic> json) {
  return _IRSFDestination.fromJson(json);
}

/// @nodoc
mixin _$IRSFDestination {
  String get id => throw _privateConstructorUsedError;
  String get countryCode => throw _privateConstructorUsedError;
  String get prefix => throw _privateConstructorUsedError;
  String? get countryName => throw _privateConstructorUsedError;
  String get riskLevel => throw _privateConstructorUsedError;
  List<String>? get fraudTypes => throw _privateConstructorUsedError;
  double? get averageFraudRate => throw _privateConstructorUsedError;
  int? get incidentCount => throw _privateConstructorUsedError;
  DateTime? get lastIncidentAt => throw _privateConstructorUsedError;
  bool get isBlacklisted => throw _privateConstructorUsedError;
  bool get isMonitored => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IRSFDestinationCopyWith<IRSFDestination> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IRSFDestinationCopyWith<$Res> {
  factory $IRSFDestinationCopyWith(
          IRSFDestination value, $Res Function(IRSFDestination) then) =
      _$IRSFDestinationCopyWithImpl<$Res, IRSFDestination>;
  @useResult
  $Res call(
      {String id,
      String countryCode,
      String prefix,
      String? countryName,
      String riskLevel,
      List<String>? fraudTypes,
      double? averageFraudRate,
      int? incidentCount,
      DateTime? lastIncidentAt,
      bool isBlacklisted,
      bool isMonitored,
      DateTime createdAt});
}

/// @nodoc
class _$IRSFDestinationCopyWithImpl<$Res, $Val extends IRSFDestination>
    implements $IRSFDestinationCopyWith<$Res> {
  _$IRSFDestinationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? countryCode = null,
    Object? prefix = null,
    Object? countryName = freezed,
    Object? riskLevel = null,
    Object? fraudTypes = freezed,
    Object? averageFraudRate = freezed,
    Object? incidentCount = freezed,
    Object? lastIncidentAt = freezed,
    Object? isBlacklisted = null,
    Object? isMonitored = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      prefix: null == prefix
          ? _value.prefix
          : prefix // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: freezed == countryName
          ? _value.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String?,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as String,
      fraudTypes: freezed == fraudTypes
          ? _value.fraudTypes
          : fraudTypes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      averageFraudRate: freezed == averageFraudRate
          ? _value.averageFraudRate
          : averageFraudRate // ignore: cast_nullable_to_non_nullable
              as double?,
      incidentCount: freezed == incidentCount
          ? _value.incidentCount
          : incidentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      lastIncidentAt: freezed == lastIncidentAt
          ? _value.lastIncidentAt
          : lastIncidentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isBlacklisted: null == isBlacklisted
          ? _value.isBlacklisted
          : isBlacklisted // ignore: cast_nullable_to_non_nullable
              as bool,
      isMonitored: null == isMonitored
          ? _value.isMonitored
          : isMonitored // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IRSFDestinationImplCopyWith<$Res>
    implements $IRSFDestinationCopyWith<$Res> {
  factory _$$IRSFDestinationImplCopyWith(_$IRSFDestinationImpl value,
          $Res Function(_$IRSFDestinationImpl) then) =
      __$$IRSFDestinationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String countryCode,
      String prefix,
      String? countryName,
      String riskLevel,
      List<String>? fraudTypes,
      double? averageFraudRate,
      int? incidentCount,
      DateTime? lastIncidentAt,
      bool isBlacklisted,
      bool isMonitored,
      DateTime createdAt});
}

/// @nodoc
class __$$IRSFDestinationImplCopyWithImpl<$Res>
    extends _$IRSFDestinationCopyWithImpl<$Res, _$IRSFDestinationImpl>
    implements _$$IRSFDestinationImplCopyWith<$Res> {
  __$$IRSFDestinationImplCopyWithImpl(
      _$IRSFDestinationImpl _value, $Res Function(_$IRSFDestinationImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? countryCode = null,
    Object? prefix = null,
    Object? countryName = freezed,
    Object? riskLevel = null,
    Object? fraudTypes = freezed,
    Object? averageFraudRate = freezed,
    Object? incidentCount = freezed,
    Object? lastIncidentAt = freezed,
    Object? isBlacklisted = null,
    Object? isMonitored = null,
    Object? createdAt = null,
  }) {
    return _then(_$IRSFDestinationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      countryCode: null == countryCode
          ? _value.countryCode
          : countryCode // ignore: cast_nullable_to_non_nullable
              as String,
      prefix: null == prefix
          ? _value.prefix
          : prefix // ignore: cast_nullable_to_non_nullable
              as String,
      countryName: freezed == countryName
          ? _value.countryName
          : countryName // ignore: cast_nullable_to_non_nullable
              as String?,
      riskLevel: null == riskLevel
          ? _value.riskLevel
          : riskLevel // ignore: cast_nullable_to_non_nullable
              as String,
      fraudTypes: freezed == fraudTypes
          ? _value._fraudTypes
          : fraudTypes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      averageFraudRate: freezed == averageFraudRate
          ? _value.averageFraudRate
          : averageFraudRate // ignore: cast_nullable_to_non_nullable
              as double?,
      incidentCount: freezed == incidentCount
          ? _value.incidentCount
          : incidentCount // ignore: cast_nullable_to_non_nullable
              as int?,
      lastIncidentAt: freezed == lastIncidentAt
          ? _value.lastIncidentAt
          : lastIncidentAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isBlacklisted: null == isBlacklisted
          ? _value.isBlacklisted
          : isBlacklisted // ignore: cast_nullable_to_non_nullable
              as bool,
      isMonitored: null == isMonitored
          ? _value.isMonitored
          : isMonitored // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IRSFDestinationImpl implements _IRSFDestination {
  const _$IRSFDestinationImpl(
      {required this.id,
      required this.countryCode,
      required this.prefix,
      this.countryName,
      required this.riskLevel,
      final List<String>? fraudTypes,
      this.averageFraudRate,
      this.incidentCount,
      this.lastIncidentAt,
      required this.isBlacklisted,
      required this.isMonitored,
      required this.createdAt})
      : _fraudTypes = fraudTypes;

  factory _$IRSFDestinationImpl.fromJson(Map<String, dynamic> json) =>
      _$$IRSFDestinationImplFromJson(json);

  @override
  final String id;
  @override
  final String countryCode;
  @override
  final String prefix;
  @override
  final String? countryName;
  @override
  final String riskLevel;
  final List<String>? _fraudTypes;
  @override
  List<String>? get fraudTypes {
    final value = _fraudTypes;
    if (value == null) return null;
    if (_fraudTypes is EqualUnmodifiableListView) return _fraudTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final double? averageFraudRate;
  @override
  final int? incidentCount;
  @override
  final DateTime? lastIncidentAt;
  @override
  final bool isBlacklisted;
  @override
  final bool isMonitored;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'IRSFDestination(id: $id, countryCode: $countryCode, prefix: $prefix, countryName: $countryName, riskLevel: $riskLevel, fraudTypes: $fraudTypes, averageFraudRate: $averageFraudRate, incidentCount: $incidentCount, lastIncidentAt: $lastIncidentAt, isBlacklisted: $isBlacklisted, isMonitored: $isMonitored, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IRSFDestinationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.countryCode, countryCode) ||
                other.countryCode == countryCode) &&
            (identical(other.prefix, prefix) || other.prefix == prefix) &&
            (identical(other.countryName, countryName) ||
                other.countryName == countryName) &&
            (identical(other.riskLevel, riskLevel) ||
                other.riskLevel == riskLevel) &&
            const DeepCollectionEquality()
                .equals(other._fraudTypes, _fraudTypes) &&
            (identical(other.averageFraudRate, averageFraudRate) ||
                other.averageFraudRate == averageFraudRate) &&
            (identical(other.incidentCount, incidentCount) ||
                other.incidentCount == incidentCount) &&
            (identical(other.lastIncidentAt, lastIncidentAt) ||
                other.lastIncidentAt == lastIncidentAt) &&
            (identical(other.isBlacklisted, isBlacklisted) ||
                other.isBlacklisted == isBlacklisted) &&
            (identical(other.isMonitored, isMonitored) ||
                other.isMonitored == isMonitored) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      countryCode,
      prefix,
      countryName,
      riskLevel,
      const DeepCollectionEquality().hash(_fraudTypes),
      averageFraudRate,
      incidentCount,
      lastIncidentAt,
      isBlacklisted,
      isMonitored,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IRSFDestinationImplCopyWith<_$IRSFDestinationImpl> get copyWith =>
      __$$IRSFDestinationImplCopyWithImpl<_$IRSFDestinationImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IRSFDestinationImplToJson(
      this,
    );
  }
}

abstract class _IRSFDestination implements IRSFDestination {
  const factory _IRSFDestination(
      {required final String id,
      required final String countryCode,
      required final String prefix,
      final String? countryName,
      required final String riskLevel,
      final List<String>? fraudTypes,
      final double? averageFraudRate,
      final int? incidentCount,
      final DateTime? lastIncidentAt,
      required final bool isBlacklisted,
      required final bool isMonitored,
      required final DateTime createdAt}) = _$IRSFDestinationImpl;

  factory _IRSFDestination.fromJson(Map<String, dynamic> json) =
      _$IRSFDestinationImpl.fromJson;

  @override
  String get id;
  @override
  String get countryCode;
  @override
  String get prefix;
  @override
  String? get countryName;
  @override
  String get riskLevel;
  @override
  List<String>? get fraudTypes;
  @override
  double? get averageFraudRate;
  @override
  int? get incidentCount;
  @override
  DateTime? get lastIncidentAt;
  @override
  bool get isBlacklisted;
  @override
  bool get isMonitored;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$IRSFDestinationImplCopyWith<_$IRSFDestinationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WangiriIncident _$WangiriIncidentFromJson(Map<String, dynamic> json) {
  return _WangiriIncident.fromJson(json);
}

/// @nodoc
mixin _$WangiriIncident {
  String get id => throw _privateConstructorUsedError;
  String get sourceNumber => throw _privateConstructorUsedError;
  String get targetNumber => throw _privateConstructorUsedError;
  int get ringDurationMs => throw _privateConstructorUsedError;
  Map<String, dynamic> get wangiriIndicators =>
      throw _privateConstructorUsedError;
  double get confidenceScore => throw _privateConstructorUsedError;
  bool get callbackAttempted => throw _privateConstructorUsedError;
  String? get callbackDestination => throw _privateConstructorUsedError;
  double? get callbackCost => throw _privateConstructorUsedError;
  int? get callbackDurationSeconds => throw _privateConstructorUsedError;
  String? get campaignId => throw _privateConstructorUsedError;
  bool get warningSent => throw _privateConstructorUsedError;
  bool get callbackBlocked => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WangiriIncidentCopyWith<WangiriIncident> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WangiriIncidentCopyWith<$Res> {
  factory $WangiriIncidentCopyWith(
          WangiriIncident value, $Res Function(WangiriIncident) then) =
      _$WangiriIncidentCopyWithImpl<$Res, WangiriIncident>;
  @useResult
  $Res call(
      {String id,
      String sourceNumber,
      String targetNumber,
      int ringDurationMs,
      Map<String, dynamic> wangiriIndicators,
      double confidenceScore,
      bool callbackAttempted,
      String? callbackDestination,
      double? callbackCost,
      int? callbackDurationSeconds,
      String? campaignId,
      bool warningSent,
      bool callbackBlocked,
      DateTime createdAt});
}

/// @nodoc
class _$WangiriIncidentCopyWithImpl<$Res, $Val extends WangiriIncident>
    implements $WangiriIncidentCopyWith<$Res> {
  _$WangiriIncidentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceNumber = null,
    Object? targetNumber = null,
    Object? ringDurationMs = null,
    Object? wangiriIndicators = null,
    Object? confidenceScore = null,
    Object? callbackAttempted = null,
    Object? callbackDestination = freezed,
    Object? callbackCost = freezed,
    Object? callbackDurationSeconds = freezed,
    Object? campaignId = freezed,
    Object? warningSent = null,
    Object? callbackBlocked = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceNumber: null == sourceNumber
          ? _value.sourceNumber
          : sourceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      targetNumber: null == targetNumber
          ? _value.targetNumber
          : targetNumber // ignore: cast_nullable_to_non_nullable
              as String,
      ringDurationMs: null == ringDurationMs
          ? _value.ringDurationMs
          : ringDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      wangiriIndicators: null == wangiriIndicators
          ? _value.wangiriIndicators
          : wangiriIndicators // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
      callbackAttempted: null == callbackAttempted
          ? _value.callbackAttempted
          : callbackAttempted // ignore: cast_nullable_to_non_nullable
              as bool,
      callbackDestination: freezed == callbackDestination
          ? _value.callbackDestination
          : callbackDestination // ignore: cast_nullable_to_non_nullable
              as String?,
      callbackCost: freezed == callbackCost
          ? _value.callbackCost
          : callbackCost // ignore: cast_nullable_to_non_nullable
              as double?,
      callbackDurationSeconds: freezed == callbackDurationSeconds
          ? _value.callbackDurationSeconds
          : callbackDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      campaignId: freezed == campaignId
          ? _value.campaignId
          : campaignId // ignore: cast_nullable_to_non_nullable
              as String?,
      warningSent: null == warningSent
          ? _value.warningSent
          : warningSent // ignore: cast_nullable_to_non_nullable
              as bool,
      callbackBlocked: null == callbackBlocked
          ? _value.callbackBlocked
          : callbackBlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WangiriIncidentImplCopyWith<$Res>
    implements $WangiriIncidentCopyWith<$Res> {
  factory _$$WangiriIncidentImplCopyWith(_$WangiriIncidentImpl value,
          $Res Function(_$WangiriIncidentImpl) then) =
      __$$WangiriIncidentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String sourceNumber,
      String targetNumber,
      int ringDurationMs,
      Map<String, dynamic> wangiriIndicators,
      double confidenceScore,
      bool callbackAttempted,
      String? callbackDestination,
      double? callbackCost,
      int? callbackDurationSeconds,
      String? campaignId,
      bool warningSent,
      bool callbackBlocked,
      DateTime createdAt});
}

/// @nodoc
class __$$WangiriIncidentImplCopyWithImpl<$Res>
    extends _$WangiriIncidentCopyWithImpl<$Res, _$WangiriIncidentImpl>
    implements _$$WangiriIncidentImplCopyWith<$Res> {
  __$$WangiriIncidentImplCopyWithImpl(
      _$WangiriIncidentImpl _value, $Res Function(_$WangiriIncidentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceNumber = null,
    Object? targetNumber = null,
    Object? ringDurationMs = null,
    Object? wangiriIndicators = null,
    Object? confidenceScore = null,
    Object? callbackAttempted = null,
    Object? callbackDestination = freezed,
    Object? callbackCost = freezed,
    Object? callbackDurationSeconds = freezed,
    Object? campaignId = freezed,
    Object? warningSent = null,
    Object? callbackBlocked = null,
    Object? createdAt = null,
  }) {
    return _then(_$WangiriIncidentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceNumber: null == sourceNumber
          ? _value.sourceNumber
          : sourceNumber // ignore: cast_nullable_to_non_nullable
              as String,
      targetNumber: null == targetNumber
          ? _value.targetNumber
          : targetNumber // ignore: cast_nullable_to_non_nullable
              as String,
      ringDurationMs: null == ringDurationMs
          ? _value.ringDurationMs
          : ringDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      wangiriIndicators: null == wangiriIndicators
          ? _value._wangiriIndicators
          : wangiriIndicators // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      confidenceScore: null == confidenceScore
          ? _value.confidenceScore
          : confidenceScore // ignore: cast_nullable_to_non_nullable
              as double,
      callbackAttempted: null == callbackAttempted
          ? _value.callbackAttempted
          : callbackAttempted // ignore: cast_nullable_to_non_nullable
              as bool,
      callbackDestination: freezed == callbackDestination
          ? _value.callbackDestination
          : callbackDestination // ignore: cast_nullable_to_non_nullable
              as String?,
      callbackCost: freezed == callbackCost
          ? _value.callbackCost
          : callbackCost // ignore: cast_nullable_to_non_nullable
              as double?,
      callbackDurationSeconds: freezed == callbackDurationSeconds
          ? _value.callbackDurationSeconds
          : callbackDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      campaignId: freezed == campaignId
          ? _value.campaignId
          : campaignId // ignore: cast_nullable_to_non_nullable
              as String?,
      warningSent: null == warningSent
          ? _value.warningSent
          : warningSent // ignore: cast_nullable_to_non_nullable
              as bool,
      callbackBlocked: null == callbackBlocked
          ? _value.callbackBlocked
          : callbackBlocked // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WangiriIncidentImpl implements _WangiriIncident {
  const _$WangiriIncidentImpl(
      {required this.id,
      required this.sourceNumber,
      required this.targetNumber,
      required this.ringDurationMs,
      required final Map<String, dynamic> wangiriIndicators,
      required this.confidenceScore,
      required this.callbackAttempted,
      this.callbackDestination,
      this.callbackCost,
      this.callbackDurationSeconds,
      this.campaignId,
      required this.warningSent,
      required this.callbackBlocked,
      required this.createdAt})
      : _wangiriIndicators = wangiriIndicators;

  factory _$WangiriIncidentImpl.fromJson(Map<String, dynamic> json) =>
      _$$WangiriIncidentImplFromJson(json);

  @override
  final String id;
  @override
  final String sourceNumber;
  @override
  final String targetNumber;
  @override
  final int ringDurationMs;
  final Map<String, dynamic> _wangiriIndicators;
  @override
  Map<String, dynamic> get wangiriIndicators {
    if (_wangiriIndicators is EqualUnmodifiableMapView)
      return _wangiriIndicators;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_wangiriIndicators);
  }

  @override
  final double confidenceScore;
  @override
  final bool callbackAttempted;
  @override
  final String? callbackDestination;
  @override
  final double? callbackCost;
  @override
  final int? callbackDurationSeconds;
  @override
  final String? campaignId;
  @override
  final bool warningSent;
  @override
  final bool callbackBlocked;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WangiriIncident(id: $id, sourceNumber: $sourceNumber, targetNumber: $targetNumber, ringDurationMs: $ringDurationMs, wangiriIndicators: $wangiriIndicators, confidenceScore: $confidenceScore, callbackAttempted: $callbackAttempted, callbackDestination: $callbackDestination, callbackCost: $callbackCost, callbackDurationSeconds: $callbackDurationSeconds, campaignId: $campaignId, warningSent: $warningSent, callbackBlocked: $callbackBlocked, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WangiriIncidentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sourceNumber, sourceNumber) ||
                other.sourceNumber == sourceNumber) &&
            (identical(other.targetNumber, targetNumber) ||
                other.targetNumber == targetNumber) &&
            (identical(other.ringDurationMs, ringDurationMs) ||
                other.ringDurationMs == ringDurationMs) &&
            const DeepCollectionEquality()
                .equals(other._wangiriIndicators, _wangiriIndicators) &&
            (identical(other.confidenceScore, confidenceScore) ||
                other.confidenceScore == confidenceScore) &&
            (identical(other.callbackAttempted, callbackAttempted) ||
                other.callbackAttempted == callbackAttempted) &&
            (identical(other.callbackDestination, callbackDestination) ||
                other.callbackDestination == callbackDestination) &&
            (identical(other.callbackCost, callbackCost) ||
                other.callbackCost == callbackCost) &&
            (identical(
                    other.callbackDurationSeconds, callbackDurationSeconds) ||
                other.callbackDurationSeconds == callbackDurationSeconds) &&
            (identical(other.campaignId, campaignId) ||
                other.campaignId == campaignId) &&
            (identical(other.warningSent, warningSent) ||
                other.warningSent == warningSent) &&
            (identical(other.callbackBlocked, callbackBlocked) ||
                other.callbackBlocked == callbackBlocked) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sourceNumber,
      targetNumber,
      ringDurationMs,
      const DeepCollectionEquality().hash(_wangiriIndicators),
      confidenceScore,
      callbackAttempted,
      callbackDestination,
      callbackCost,
      callbackDurationSeconds,
      campaignId,
      warningSent,
      callbackBlocked,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WangiriIncidentImplCopyWith<_$WangiriIncidentImpl> get copyWith =>
      __$$WangiriIncidentImplCopyWithImpl<_$WangiriIncidentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WangiriIncidentImplToJson(
      this,
    );
  }
}

abstract class _WangiriIncident implements WangiriIncident {
  const factory _WangiriIncident(
      {required final String id,
      required final String sourceNumber,
      required final String targetNumber,
      required final int ringDurationMs,
      required final Map<String, dynamic> wangiriIndicators,
      required final double confidenceScore,
      required final bool callbackAttempted,
      final String? callbackDestination,
      final double? callbackCost,
      final int? callbackDurationSeconds,
      final String? campaignId,
      required final bool warningSent,
      required final bool callbackBlocked,
      required final DateTime createdAt}) = _$WangiriIncidentImpl;

  factory _WangiriIncident.fromJson(Map<String, dynamic> json) =
      _$WangiriIncidentImpl.fromJson;

  @override
  String get id;
  @override
  String get sourceNumber;
  @override
  String get targetNumber;
  @override
  int get ringDurationMs;
  @override
  Map<String, dynamic> get wangiriIndicators;
  @override
  double get confidenceScore;
  @override
  bool get callbackAttempted;
  @override
  String? get callbackDestination;
  @override
  double? get callbackCost;
  @override
  int? get callbackDurationSeconds;
  @override
  String? get campaignId;
  @override
  bool get warningSent;
  @override
  bool get callbackBlocked;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$WangiriIncidentImplCopyWith<_$WangiriIncidentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WangiriCampaign _$WangiriCampaignFromJson(Map<String, dynamic> json) {
  return _WangiriCampaign.fromJson(json);
}

/// @nodoc
mixin _$WangiriCampaign {
  String get id => throw _privateConstructorUsedError;
  List<String> get sourceNumbers => throw _privateConstructorUsedError;
  String? get sourceCountry => throw _privateConstructorUsedError;
  String? get sourceCarrierId => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  DateTime? get endTime => throw _privateConstructorUsedError;
  List<String>? get targetedPrefixes => throw _privateConstructorUsedError;
  int? get avgRingDurationMs => throw _privateConstructorUsedError;
  int get totalCallAttempts => throw _privateConstructorUsedError;
  int get successfulCallbacks => throw _privateConstructorUsedError;
  double get estimatedRevenueLoss => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  List<String>? get blockedNumbers => throw _privateConstructorUsedError;
  int get alertsSent => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WangiriCampaignCopyWith<WangiriCampaign> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WangiriCampaignCopyWith<$Res> {
  factory $WangiriCampaignCopyWith(
          WangiriCampaign value, $Res Function(WangiriCampaign) then) =
      _$WangiriCampaignCopyWithImpl<$Res, WangiriCampaign>;
  @useResult
  $Res call(
      {String id,
      List<String> sourceNumbers,
      String? sourceCountry,
      String? sourceCarrierId,
      DateTime startTime,
      DateTime? endTime,
      List<String>? targetedPrefixes,
      int? avgRingDurationMs,
      int totalCallAttempts,
      int successfulCallbacks,
      double estimatedRevenueLoss,
      String status,
      List<String>? blockedNumbers,
      int alertsSent,
      DateTime createdAt});
}

/// @nodoc
class _$WangiriCampaignCopyWithImpl<$Res, $Val extends WangiriCampaign>
    implements $WangiriCampaignCopyWith<$Res> {
  _$WangiriCampaignCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceNumbers = null,
    Object? sourceCountry = freezed,
    Object? sourceCarrierId = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? targetedPrefixes = freezed,
    Object? avgRingDurationMs = freezed,
    Object? totalCallAttempts = null,
    Object? successfulCallbacks = null,
    Object? estimatedRevenueLoss = null,
    Object? status = null,
    Object? blockedNumbers = freezed,
    Object? alertsSent = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceNumbers: null == sourceNumbers
          ? _value.sourceNumbers
          : sourceNumbers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sourceCountry: freezed == sourceCountry
          ? _value.sourceCountry
          : sourceCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceCarrierId: freezed == sourceCarrierId
          ? _value.sourceCarrierId
          : sourceCarrierId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      targetedPrefixes: freezed == targetedPrefixes
          ? _value.targetedPrefixes
          : targetedPrefixes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      avgRingDurationMs: freezed == avgRingDurationMs
          ? _value.avgRingDurationMs
          : avgRingDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      totalCallAttempts: null == totalCallAttempts
          ? _value.totalCallAttempts
          : totalCallAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      successfulCallbacks: null == successfulCallbacks
          ? _value.successfulCallbacks
          : successfulCallbacks // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedRevenueLoss: null == estimatedRevenueLoss
          ? _value.estimatedRevenueLoss
          : estimatedRevenueLoss // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      blockedNumbers: freezed == blockedNumbers
          ? _value.blockedNumbers
          : blockedNumbers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      alertsSent: null == alertsSent
          ? _value.alertsSent
          : alertsSent // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WangiriCampaignImplCopyWith<$Res>
    implements $WangiriCampaignCopyWith<$Res> {
  factory _$$WangiriCampaignImplCopyWith(_$WangiriCampaignImpl value,
          $Res Function(_$WangiriCampaignImpl) then) =
      __$$WangiriCampaignImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      List<String> sourceNumbers,
      String? sourceCountry,
      String? sourceCarrierId,
      DateTime startTime,
      DateTime? endTime,
      List<String>? targetedPrefixes,
      int? avgRingDurationMs,
      int totalCallAttempts,
      int successfulCallbacks,
      double estimatedRevenueLoss,
      String status,
      List<String>? blockedNumbers,
      int alertsSent,
      DateTime createdAt});
}

/// @nodoc
class __$$WangiriCampaignImplCopyWithImpl<$Res>
    extends _$WangiriCampaignCopyWithImpl<$Res, _$WangiriCampaignImpl>
    implements _$$WangiriCampaignImplCopyWith<$Res> {
  __$$WangiriCampaignImplCopyWithImpl(
      _$WangiriCampaignImpl _value, $Res Function(_$WangiriCampaignImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sourceNumbers = null,
    Object? sourceCountry = freezed,
    Object? sourceCarrierId = freezed,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? targetedPrefixes = freezed,
    Object? avgRingDurationMs = freezed,
    Object? totalCallAttempts = null,
    Object? successfulCallbacks = null,
    Object? estimatedRevenueLoss = null,
    Object? status = null,
    Object? blockedNumbers = freezed,
    Object? alertsSent = null,
    Object? createdAt = null,
  }) {
    return _then(_$WangiriCampaignImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      sourceNumbers: null == sourceNumbers
          ? _value._sourceNumbers
          : sourceNumbers // ignore: cast_nullable_to_non_nullable
              as List<String>,
      sourceCountry: freezed == sourceCountry
          ? _value.sourceCountry
          : sourceCountry // ignore: cast_nullable_to_non_nullable
              as String?,
      sourceCarrierId: freezed == sourceCarrierId
          ? _value.sourceCarrierId
          : sourceCarrierId // ignore: cast_nullable_to_non_nullable
              as String?,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      targetedPrefixes: freezed == targetedPrefixes
          ? _value._targetedPrefixes
          : targetedPrefixes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      avgRingDurationMs: freezed == avgRingDurationMs
          ? _value.avgRingDurationMs
          : avgRingDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      totalCallAttempts: null == totalCallAttempts
          ? _value.totalCallAttempts
          : totalCallAttempts // ignore: cast_nullable_to_non_nullable
              as int,
      successfulCallbacks: null == successfulCallbacks
          ? _value.successfulCallbacks
          : successfulCallbacks // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedRevenueLoss: null == estimatedRevenueLoss
          ? _value.estimatedRevenueLoss
          : estimatedRevenueLoss // ignore: cast_nullable_to_non_nullable
              as double,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      blockedNumbers: freezed == blockedNumbers
          ? _value._blockedNumbers
          : blockedNumbers // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      alertsSent: null == alertsSent
          ? _value.alertsSent
          : alertsSent // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WangiriCampaignImpl implements _WangiriCampaign {
  const _$WangiriCampaignImpl(
      {required this.id,
      required final List<String> sourceNumbers,
      this.sourceCountry,
      this.sourceCarrierId,
      required this.startTime,
      this.endTime,
      final List<String>? targetedPrefixes,
      this.avgRingDurationMs,
      required this.totalCallAttempts,
      required this.successfulCallbacks,
      required this.estimatedRevenueLoss,
      required this.status,
      final List<String>? blockedNumbers,
      required this.alertsSent,
      required this.createdAt})
      : _sourceNumbers = sourceNumbers,
        _targetedPrefixes = targetedPrefixes,
        _blockedNumbers = blockedNumbers;

  factory _$WangiriCampaignImpl.fromJson(Map<String, dynamic> json) =>
      _$$WangiriCampaignImplFromJson(json);

  @override
  final String id;
  final List<String> _sourceNumbers;
  @override
  List<String> get sourceNumbers {
    if (_sourceNumbers is EqualUnmodifiableListView) return _sourceNumbers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sourceNumbers);
  }

  @override
  final String? sourceCountry;
  @override
  final String? sourceCarrierId;
  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  final List<String>? _targetedPrefixes;
  @override
  List<String>? get targetedPrefixes {
    final value = _targetedPrefixes;
    if (value == null) return null;
    if (_targetedPrefixes is EqualUnmodifiableListView)
      return _targetedPrefixes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int? avgRingDurationMs;
  @override
  final int totalCallAttempts;
  @override
  final int successfulCallbacks;
  @override
  final double estimatedRevenueLoss;
  @override
  final String status;
  final List<String>? _blockedNumbers;
  @override
  List<String>? get blockedNumbers {
    final value = _blockedNumbers;
    if (value == null) return null;
    if (_blockedNumbers is EqualUnmodifiableListView) return _blockedNumbers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final int alertsSent;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WangiriCampaign(id: $id, sourceNumbers: $sourceNumbers, sourceCountry: $sourceCountry, sourceCarrierId: $sourceCarrierId, startTime: $startTime, endTime: $endTime, targetedPrefixes: $targetedPrefixes, avgRingDurationMs: $avgRingDurationMs, totalCallAttempts: $totalCallAttempts, successfulCallbacks: $successfulCallbacks, estimatedRevenueLoss: $estimatedRevenueLoss, status: $status, blockedNumbers: $blockedNumbers, alertsSent: $alertsSent, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WangiriCampaignImpl &&
            (identical(other.id, id) || other.id == id) &&
            const DeepCollectionEquality()
                .equals(other._sourceNumbers, _sourceNumbers) &&
            (identical(other.sourceCountry, sourceCountry) ||
                other.sourceCountry == sourceCountry) &&
            (identical(other.sourceCarrierId, sourceCarrierId) ||
                other.sourceCarrierId == sourceCarrierId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            const DeepCollectionEquality()
                .equals(other._targetedPrefixes, _targetedPrefixes) &&
            (identical(other.avgRingDurationMs, avgRingDurationMs) ||
                other.avgRingDurationMs == avgRingDurationMs) &&
            (identical(other.totalCallAttempts, totalCallAttempts) ||
                other.totalCallAttempts == totalCallAttempts) &&
            (identical(other.successfulCallbacks, successfulCallbacks) ||
                other.successfulCallbacks == successfulCallbacks) &&
            (identical(other.estimatedRevenueLoss, estimatedRevenueLoss) ||
                other.estimatedRevenueLoss == estimatedRevenueLoss) &&
            (identical(other.status, status) || other.status == status) &&
            const DeepCollectionEquality()
                .equals(other._blockedNumbers, _blockedNumbers) &&
            (identical(other.alertsSent, alertsSent) ||
                other.alertsSent == alertsSent) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      const DeepCollectionEquality().hash(_sourceNumbers),
      sourceCountry,
      sourceCarrierId,
      startTime,
      endTime,
      const DeepCollectionEquality().hash(_targetedPrefixes),
      avgRingDurationMs,
      totalCallAttempts,
      successfulCallbacks,
      estimatedRevenueLoss,
      status,
      const DeepCollectionEquality().hash(_blockedNumbers),
      alertsSent,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WangiriCampaignImplCopyWith<_$WangiriCampaignImpl> get copyWith =>
      __$$WangiriCampaignImplCopyWithImpl<_$WangiriCampaignImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WangiriCampaignImplToJson(
      this,
    );
  }
}

abstract class _WangiriCampaign implements WangiriCampaign {
  const factory _WangiriCampaign(
      {required final String id,
      required final List<String> sourceNumbers,
      final String? sourceCountry,
      final String? sourceCarrierId,
      required final DateTime startTime,
      final DateTime? endTime,
      final List<String>? targetedPrefixes,
      final int? avgRingDurationMs,
      required final int totalCallAttempts,
      required final int successfulCallbacks,
      required final double estimatedRevenueLoss,
      required final String status,
      final List<String>? blockedNumbers,
      required final int alertsSent,
      required final DateTime createdAt}) = _$WangiriCampaignImpl;

  factory _WangiriCampaign.fromJson(Map<String, dynamic> json) =
      _$WangiriCampaignImpl.fromJson;

  @override
  String get id;
  @override
  List<String> get sourceNumbers;
  @override
  String? get sourceCountry;
  @override
  String? get sourceCarrierId;
  @override
  DateTime get startTime;
  @override
  DateTime? get endTime;
  @override
  List<String>? get targetedPrefixes;
  @override
  int? get avgRingDurationMs;
  @override
  int get totalCallAttempts;
  @override
  int get successfulCallbacks;
  @override
  double get estimatedRevenueLoss;
  @override
  String get status;
  @override
  List<String>? get blockedNumbers;
  @override
  int get alertsSent;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$WangiriCampaignImplCopyWith<_$WangiriCampaignImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CallbackFraudIncident _$CallbackFraudIncidentFromJson(
    Map<String, dynamic> json) {
  return _CallbackFraudIncident.fromJson(json);
}

/// @nodoc
mixin _$CallbackFraudIncident {
  String get id => throw _privateConstructorUsedError;
  String get triggerType => throw _privateConstructorUsedError;
  String? get triggerCallId => throw _privateConstructorUsedError;
  String get callbackSource => throw _privateConstructorUsedError;
  String get callbackDestination => throw _privateConstructorUsedError;
  int? get callbackDurationSeconds => throw _privateConstructorUsedError;
  String? get destinationRiskLevel => throw _privateConstructorUsedError;
  String? get fraudType => throw _privateConstructorUsedError;
  double get domesticCost => throw _privateConstructorUsedError;
  double get internationalCost => throw _privateConstructorUsedError;
  double get premiumCost => throw _privateConstructorUsedError;
  double get totalLoss => throw _privateConstructorUsedError;
  String? get detectionMethod => throw _privateConstructorUsedError;
  DateTime get detectionTime => throw _privateConstructorUsedError;
  String? get actionTaken => throw _privateConstructorUsedError;
  bool get subscriberNotified => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CallbackFraudIncidentCopyWith<CallbackFraudIncident> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CallbackFraudIncidentCopyWith<$Res> {
  factory $CallbackFraudIncidentCopyWith(CallbackFraudIncident value,
          $Res Function(CallbackFraudIncident) then) =
      _$CallbackFraudIncidentCopyWithImpl<$Res, CallbackFraudIncident>;
  @useResult
  $Res call(
      {String id,
      String triggerType,
      String? triggerCallId,
      String callbackSource,
      String callbackDestination,
      int? callbackDurationSeconds,
      String? destinationRiskLevel,
      String? fraudType,
      double domesticCost,
      double internationalCost,
      double premiumCost,
      double totalLoss,
      String? detectionMethod,
      DateTime detectionTime,
      String? actionTaken,
      bool subscriberNotified,
      DateTime createdAt});
}

/// @nodoc
class _$CallbackFraudIncidentCopyWithImpl<$Res,
        $Val extends CallbackFraudIncident>
    implements $CallbackFraudIncidentCopyWith<$Res> {
  _$CallbackFraudIncidentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? triggerType = null,
    Object? triggerCallId = freezed,
    Object? callbackSource = null,
    Object? callbackDestination = null,
    Object? callbackDurationSeconds = freezed,
    Object? destinationRiskLevel = freezed,
    Object? fraudType = freezed,
    Object? domesticCost = null,
    Object? internationalCost = null,
    Object? premiumCost = null,
    Object? totalLoss = null,
    Object? detectionMethod = freezed,
    Object? detectionTime = null,
    Object? actionTaken = freezed,
    Object? subscriberNotified = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      triggerType: null == triggerType
          ? _value.triggerType
          : triggerType // ignore: cast_nullable_to_non_nullable
              as String,
      triggerCallId: freezed == triggerCallId
          ? _value.triggerCallId
          : triggerCallId // ignore: cast_nullable_to_non_nullable
              as String?,
      callbackSource: null == callbackSource
          ? _value.callbackSource
          : callbackSource // ignore: cast_nullable_to_non_nullable
              as String,
      callbackDestination: null == callbackDestination
          ? _value.callbackDestination
          : callbackDestination // ignore: cast_nullable_to_non_nullable
              as String,
      callbackDurationSeconds: freezed == callbackDurationSeconds
          ? _value.callbackDurationSeconds
          : callbackDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      destinationRiskLevel: freezed == destinationRiskLevel
          ? _value.destinationRiskLevel
          : destinationRiskLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      fraudType: freezed == fraudType
          ? _value.fraudType
          : fraudType // ignore: cast_nullable_to_non_nullable
              as String?,
      domesticCost: null == domesticCost
          ? _value.domesticCost
          : domesticCost // ignore: cast_nullable_to_non_nullable
              as double,
      internationalCost: null == internationalCost
          ? _value.internationalCost
          : internationalCost // ignore: cast_nullable_to_non_nullable
              as double,
      premiumCost: null == premiumCost
          ? _value.premiumCost
          : premiumCost // ignore: cast_nullable_to_non_nullable
              as double,
      totalLoss: null == totalLoss
          ? _value.totalLoss
          : totalLoss // ignore: cast_nullable_to_non_nullable
              as double,
      detectionMethod: freezed == detectionMethod
          ? _value.detectionMethod
          : detectionMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      detectionTime: null == detectionTime
          ? _value.detectionTime
          : detectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      actionTaken: freezed == actionTaken
          ? _value.actionTaken
          : actionTaken // ignore: cast_nullable_to_non_nullable
              as String?,
      subscriberNotified: null == subscriberNotified
          ? _value.subscriberNotified
          : subscriberNotified // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CallbackFraudIncidentImplCopyWith<$Res>
    implements $CallbackFraudIncidentCopyWith<$Res> {
  factory _$$CallbackFraudIncidentImplCopyWith(
          _$CallbackFraudIncidentImpl value,
          $Res Function(_$CallbackFraudIncidentImpl) then) =
      __$$CallbackFraudIncidentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String triggerType,
      String? triggerCallId,
      String callbackSource,
      String callbackDestination,
      int? callbackDurationSeconds,
      String? destinationRiskLevel,
      String? fraudType,
      double domesticCost,
      double internationalCost,
      double premiumCost,
      double totalLoss,
      String? detectionMethod,
      DateTime detectionTime,
      String? actionTaken,
      bool subscriberNotified,
      DateTime createdAt});
}

/// @nodoc
class __$$CallbackFraudIncidentImplCopyWithImpl<$Res>
    extends _$CallbackFraudIncidentCopyWithImpl<$Res,
        _$CallbackFraudIncidentImpl>
    implements _$$CallbackFraudIncidentImplCopyWith<$Res> {
  __$$CallbackFraudIncidentImplCopyWithImpl(_$CallbackFraudIncidentImpl _value,
      $Res Function(_$CallbackFraudIncidentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? triggerType = null,
    Object? triggerCallId = freezed,
    Object? callbackSource = null,
    Object? callbackDestination = null,
    Object? callbackDurationSeconds = freezed,
    Object? destinationRiskLevel = freezed,
    Object? fraudType = freezed,
    Object? domesticCost = null,
    Object? internationalCost = null,
    Object? premiumCost = null,
    Object? totalLoss = null,
    Object? detectionMethod = freezed,
    Object? detectionTime = null,
    Object? actionTaken = freezed,
    Object? subscriberNotified = null,
    Object? createdAt = null,
  }) {
    return _then(_$CallbackFraudIncidentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      triggerType: null == triggerType
          ? _value.triggerType
          : triggerType // ignore: cast_nullable_to_non_nullable
              as String,
      triggerCallId: freezed == triggerCallId
          ? _value.triggerCallId
          : triggerCallId // ignore: cast_nullable_to_non_nullable
              as String?,
      callbackSource: null == callbackSource
          ? _value.callbackSource
          : callbackSource // ignore: cast_nullable_to_non_nullable
              as String,
      callbackDestination: null == callbackDestination
          ? _value.callbackDestination
          : callbackDestination // ignore: cast_nullable_to_non_nullable
              as String,
      callbackDurationSeconds: freezed == callbackDurationSeconds
          ? _value.callbackDurationSeconds
          : callbackDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
      destinationRiskLevel: freezed == destinationRiskLevel
          ? _value.destinationRiskLevel
          : destinationRiskLevel // ignore: cast_nullable_to_non_nullable
              as String?,
      fraudType: freezed == fraudType
          ? _value.fraudType
          : fraudType // ignore: cast_nullable_to_non_nullable
              as String?,
      domesticCost: null == domesticCost
          ? _value.domesticCost
          : domesticCost // ignore: cast_nullable_to_non_nullable
              as double,
      internationalCost: null == internationalCost
          ? _value.internationalCost
          : internationalCost // ignore: cast_nullable_to_non_nullable
              as double,
      premiumCost: null == premiumCost
          ? _value.premiumCost
          : premiumCost // ignore: cast_nullable_to_non_nullable
              as double,
      totalLoss: null == totalLoss
          ? _value.totalLoss
          : totalLoss // ignore: cast_nullable_to_non_nullable
              as double,
      detectionMethod: freezed == detectionMethod
          ? _value.detectionMethod
          : detectionMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      detectionTime: null == detectionTime
          ? _value.detectionTime
          : detectionTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      actionTaken: freezed == actionTaken
          ? _value.actionTaken
          : actionTaken // ignore: cast_nullable_to_non_nullable
              as String?,
      subscriberNotified: null == subscriberNotified
          ? _value.subscriberNotified
          : subscriberNotified // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CallbackFraudIncidentImpl implements _CallbackFraudIncident {
  const _$CallbackFraudIncidentImpl(
      {required this.id,
      required this.triggerType,
      this.triggerCallId,
      required this.callbackSource,
      required this.callbackDestination,
      this.callbackDurationSeconds,
      this.destinationRiskLevel,
      this.fraudType,
      required this.domesticCost,
      required this.internationalCost,
      required this.premiumCost,
      required this.totalLoss,
      this.detectionMethod,
      required this.detectionTime,
      this.actionTaken,
      required this.subscriberNotified,
      required this.createdAt});

  factory _$CallbackFraudIncidentImpl.fromJson(Map<String, dynamic> json) =>
      _$$CallbackFraudIncidentImplFromJson(json);

  @override
  final String id;
  @override
  final String triggerType;
  @override
  final String? triggerCallId;
  @override
  final String callbackSource;
  @override
  final String callbackDestination;
  @override
  final int? callbackDurationSeconds;
  @override
  final String? destinationRiskLevel;
  @override
  final String? fraudType;
  @override
  final double domesticCost;
  @override
  final double internationalCost;
  @override
  final double premiumCost;
  @override
  final double totalLoss;
  @override
  final String? detectionMethod;
  @override
  final DateTime detectionTime;
  @override
  final String? actionTaken;
  @override
  final bool subscriberNotified;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'CallbackFraudIncident(id: $id, triggerType: $triggerType, triggerCallId: $triggerCallId, callbackSource: $callbackSource, callbackDestination: $callbackDestination, callbackDurationSeconds: $callbackDurationSeconds, destinationRiskLevel: $destinationRiskLevel, fraudType: $fraudType, domesticCost: $domesticCost, internationalCost: $internationalCost, premiumCost: $premiumCost, totalLoss: $totalLoss, detectionMethod: $detectionMethod, detectionTime: $detectionTime, actionTaken: $actionTaken, subscriberNotified: $subscriberNotified, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CallbackFraudIncidentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.triggerType, triggerType) ||
                other.triggerType == triggerType) &&
            (identical(other.triggerCallId, triggerCallId) ||
                other.triggerCallId == triggerCallId) &&
            (identical(other.callbackSource, callbackSource) ||
                other.callbackSource == callbackSource) &&
            (identical(other.callbackDestination, callbackDestination) ||
                other.callbackDestination == callbackDestination) &&
            (identical(
                    other.callbackDurationSeconds, callbackDurationSeconds) ||
                other.callbackDurationSeconds == callbackDurationSeconds) &&
            (identical(other.destinationRiskLevel, destinationRiskLevel) ||
                other.destinationRiskLevel == destinationRiskLevel) &&
            (identical(other.fraudType, fraudType) ||
                other.fraudType == fraudType) &&
            (identical(other.domesticCost, domesticCost) ||
                other.domesticCost == domesticCost) &&
            (identical(other.internationalCost, internationalCost) ||
                other.internationalCost == internationalCost) &&
            (identical(other.premiumCost, premiumCost) ||
                other.premiumCost == premiumCost) &&
            (identical(other.totalLoss, totalLoss) ||
                other.totalLoss == totalLoss) &&
            (identical(other.detectionMethod, detectionMethod) ||
                other.detectionMethod == detectionMethod) &&
            (identical(other.detectionTime, detectionTime) ||
                other.detectionTime == detectionTime) &&
            (identical(other.actionTaken, actionTaken) ||
                other.actionTaken == actionTaken) &&
            (identical(other.subscriberNotified, subscriberNotified) ||
                other.subscriberNotified == subscriberNotified) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      triggerType,
      triggerCallId,
      callbackSource,
      callbackDestination,
      callbackDurationSeconds,
      destinationRiskLevel,
      fraudType,
      domesticCost,
      internationalCost,
      premiumCost,
      totalLoss,
      detectionMethod,
      detectionTime,
      actionTaken,
      subscriberNotified,
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CallbackFraudIncidentImplCopyWith<_$CallbackFraudIncidentImpl>
      get copyWith => __$$CallbackFraudIncidentImplCopyWithImpl<
          _$CallbackFraudIncidentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CallbackFraudIncidentImplToJson(
      this,
    );
  }
}

abstract class _CallbackFraudIncident implements CallbackFraudIncident {
  const factory _CallbackFraudIncident(
      {required final String id,
      required final String triggerType,
      final String? triggerCallId,
      required final String callbackSource,
      required final String callbackDestination,
      final int? callbackDurationSeconds,
      final String? destinationRiskLevel,
      final String? fraudType,
      required final double domesticCost,
      required final double internationalCost,
      required final double premiumCost,
      required final double totalLoss,
      final String? detectionMethod,
      required final DateTime detectionTime,
      final String? actionTaken,
      required final bool subscriberNotified,
      required final DateTime createdAt}) = _$CallbackFraudIncidentImpl;

  factory _CallbackFraudIncident.fromJson(Map<String, dynamic> json) =
      _$CallbackFraudIncidentImpl.fromJson;

  @override
  String get id;
  @override
  String get triggerType;
  @override
  String? get triggerCallId;
  @override
  String get callbackSource;
  @override
  String get callbackDestination;
  @override
  int? get callbackDurationSeconds;
  @override
  String? get destinationRiskLevel;
  @override
  String? get fraudType;
  @override
  double get domesticCost;
  @override
  double get internationalCost;
  @override
  double get premiumCost;
  @override
  double get totalLoss;
  @override
  String? get detectionMethod;
  @override
  DateTime get detectionTime;
  @override
  String? get actionTaken;
  @override
  bool get subscriberNotified;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$CallbackFraudIncidentImplCopyWith<_$CallbackFraudIncidentImpl>
      get copyWith => throw _privateConstructorUsedError;
}

FraudSummary _$FraudSummaryFromJson(Map<String, dynamic> json) {
  return _FraudSummary.fromJson(json);
}

/// @nodoc
mixin _$FraudSummary {
  int get cliSpoofingCount => throw _privateConstructorUsedError;
  int get irsfCount => throw _privateConstructorUsedError;
  int get wangiriCount => throw _privateConstructorUsedError;
  int get callbackFraudCount => throw _privateConstructorUsedError;
  double get totalRevenueProtected => throw _privateConstructorUsedError;
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FraudSummaryCopyWith<FraudSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FraudSummaryCopyWith<$Res> {
  factory $FraudSummaryCopyWith(
          FraudSummary value, $Res Function(FraudSummary) then) =
      _$FraudSummaryCopyWithImpl<$Res, FraudSummary>;
  @useResult
  $Res call(
      {int cliSpoofingCount,
      int irsfCount,
      int wangiriCount,
      int callbackFraudCount,
      double totalRevenueProtected,
      DateTime lastUpdated});
}

/// @nodoc
class _$FraudSummaryCopyWithImpl<$Res, $Val extends FraudSummary>
    implements $FraudSummaryCopyWith<$Res> {
  _$FraudSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cliSpoofingCount = null,
    Object? irsfCount = null,
    Object? wangiriCount = null,
    Object? callbackFraudCount = null,
    Object? totalRevenueProtected = null,
    Object? lastUpdated = null,
  }) {
    return _then(_value.copyWith(
      cliSpoofingCount: null == cliSpoofingCount
          ? _value.cliSpoofingCount
          : cliSpoofingCount // ignore: cast_nullable_to_non_nullable
              as int,
      irsfCount: null == irsfCount
          ? _value.irsfCount
          : irsfCount // ignore: cast_nullable_to_non_nullable
              as int,
      wangiriCount: null == wangiriCount
          ? _value.wangiriCount
          : wangiriCount // ignore: cast_nullable_to_non_nullable
              as int,
      callbackFraudCount: null == callbackFraudCount
          ? _value.callbackFraudCount
          : callbackFraudCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRevenueProtected: null == totalRevenueProtected
          ? _value.totalRevenueProtected
          : totalRevenueProtected // ignore: cast_nullable_to_non_nullable
              as double,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FraudSummaryImplCopyWith<$Res>
    implements $FraudSummaryCopyWith<$Res> {
  factory _$$FraudSummaryImplCopyWith(
          _$FraudSummaryImpl value, $Res Function(_$FraudSummaryImpl) then) =
      __$$FraudSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int cliSpoofingCount,
      int irsfCount,
      int wangiriCount,
      int callbackFraudCount,
      double totalRevenueProtected,
      DateTime lastUpdated});
}

/// @nodoc
class __$$FraudSummaryImplCopyWithImpl<$Res>
    extends _$FraudSummaryCopyWithImpl<$Res, _$FraudSummaryImpl>
    implements _$$FraudSummaryImplCopyWith<$Res> {
  __$$FraudSummaryImplCopyWithImpl(
      _$FraudSummaryImpl _value, $Res Function(_$FraudSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cliSpoofingCount = null,
    Object? irsfCount = null,
    Object? wangiriCount = null,
    Object? callbackFraudCount = null,
    Object? totalRevenueProtected = null,
    Object? lastUpdated = null,
  }) {
    return _then(_$FraudSummaryImpl(
      cliSpoofingCount: null == cliSpoofingCount
          ? _value.cliSpoofingCount
          : cliSpoofingCount // ignore: cast_nullable_to_non_nullable
              as int,
      irsfCount: null == irsfCount
          ? _value.irsfCount
          : irsfCount // ignore: cast_nullable_to_non_nullable
              as int,
      wangiriCount: null == wangiriCount
          ? _value.wangiriCount
          : wangiriCount // ignore: cast_nullable_to_non_nullable
              as int,
      callbackFraudCount: null == callbackFraudCount
          ? _value.callbackFraudCount
          : callbackFraudCount // ignore: cast_nullable_to_non_nullable
              as int,
      totalRevenueProtected: null == totalRevenueProtected
          ? _value.totalRevenueProtected
          : totalRevenueProtected // ignore: cast_nullable_to_non_nullable
              as double,
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FraudSummaryImpl implements _FraudSummary {
  const _$FraudSummaryImpl(
      {required this.cliSpoofingCount,
      required this.irsfCount,
      required this.wangiriCount,
      required this.callbackFraudCount,
      required this.totalRevenueProtected,
      required this.lastUpdated});

  factory _$FraudSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$FraudSummaryImplFromJson(json);

  @override
  final int cliSpoofingCount;
  @override
  final int irsfCount;
  @override
  final int wangiriCount;
  @override
  final int callbackFraudCount;
  @override
  final double totalRevenueProtected;
  @override
  final DateTime lastUpdated;

  @override
  String toString() {
    return 'FraudSummary(cliSpoofingCount: $cliSpoofingCount, irsfCount: $irsfCount, wangiriCount: $wangiriCount, callbackFraudCount: $callbackFraudCount, totalRevenueProtected: $totalRevenueProtected, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FraudSummaryImpl &&
            (identical(other.cliSpoofingCount, cliSpoofingCount) ||
                other.cliSpoofingCount == cliSpoofingCount) &&
            (identical(other.irsfCount, irsfCount) ||
                other.irsfCount == irsfCount) &&
            (identical(other.wangiriCount, wangiriCount) ||
                other.wangiriCount == wangiriCount) &&
            (identical(other.callbackFraudCount, callbackFraudCount) ||
                other.callbackFraudCount == callbackFraudCount) &&
            (identical(other.totalRevenueProtected, totalRevenueProtected) ||
                other.totalRevenueProtected == totalRevenueProtected) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, cliSpoofingCount, irsfCount,
      wangiriCount, callbackFraudCount, totalRevenueProtected, lastUpdated);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FraudSummaryImplCopyWith<_$FraudSummaryImpl> get copyWith =>
      __$$FraudSummaryImplCopyWithImpl<_$FraudSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FraudSummaryImplToJson(
      this,
    );
  }
}

abstract class _FraudSummary implements FraudSummary {
  const factory _FraudSummary(
      {required final int cliSpoofingCount,
      required final int irsfCount,
      required final int wangiriCount,
      required final int callbackFraudCount,
      required final double totalRevenueProtected,
      required final DateTime lastUpdated}) = _$FraudSummaryImpl;

  factory _FraudSummary.fromJson(Map<String, dynamic> json) =
      _$FraudSummaryImpl.fromJson;

  @override
  int get cliSpoofingCount;
  @override
  int get irsfCount;
  @override
  int get wangiriCount;
  @override
  int get callbackFraudCount;
  @override
  double get totalRevenueProtected;
  @override
  DateTime get lastUpdated;
  @override
  @JsonKey(ignore: true)
  _$$FraudSummaryImplCopyWith<_$FraudSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
