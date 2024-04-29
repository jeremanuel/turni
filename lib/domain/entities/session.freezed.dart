// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Session {
  int get sessionId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get startTime => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  int? get clientId => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  int get adminCreatorId => throw _privateConstructorUsedError;
  int get partitionPhysicalId => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SessionCopyWith<Session> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionCopyWith<$Res> {
  factory $SessionCopyWith(Session value, $Res Function(Session) then) =
      _$SessionCopyWithImpl<$Res, Session>;
  @useResult
  $Res call(
      {int sessionId,
      DateTime createdAt,
      DateTime startTime,
      String duration,
      int? clientId,
      double price,
      int adminCreatorId,
      int partitionPhysicalId});
}

/// @nodoc
class _$SessionCopyWithImpl<$Res, $Val extends Session>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? createdAt = null,
    Object? startTime = null,
    Object? duration = null,
    Object? clientId = freezed,
    Object? price = null,
    Object? adminCreatorId = null,
    Object? partitionPhysicalId = null,
  }) {
    return _then(_value.copyWith(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as int?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      adminCreatorId: null == adminCreatorId
          ? _value.adminCreatorId
          : adminCreatorId // ignore: cast_nullable_to_non_nullable
              as int,
      partitionPhysicalId: null == partitionPhysicalId
          ? _value.partitionPhysicalId
          : partitionPhysicalId // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SessionImplCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$$SessionImplCopyWith(
          _$SessionImpl value, $Res Function(_$SessionImpl) then) =
      __$$SessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int sessionId,
      DateTime createdAt,
      DateTime startTime,
      String duration,
      int? clientId,
      double price,
      int adminCreatorId,
      int partitionPhysicalId});
}

/// @nodoc
class __$$SessionImplCopyWithImpl<$Res>
    extends _$SessionCopyWithImpl<$Res, _$SessionImpl>
    implements _$$SessionImplCopyWith<$Res> {
  __$$SessionImplCopyWithImpl(
      _$SessionImpl _value, $Res Function(_$SessionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? createdAt = null,
    Object? startTime = null,
    Object? duration = null,
    Object? clientId = freezed,
    Object? price = null,
    Object? adminCreatorId = null,
    Object? partitionPhysicalId = null,
  }) {
    return _then(_$SessionImpl(
      sessionId: null == sessionId
          ? _value.sessionId
          : sessionId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as int?,
      price: null == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as double,
      adminCreatorId: null == adminCreatorId
          ? _value.adminCreatorId
          : adminCreatorId // ignore: cast_nullable_to_non_nullable
              as int,
      partitionPhysicalId: null == partitionPhysicalId
          ? _value.partitionPhysicalId
          : partitionPhysicalId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$SessionImpl extends _Session {
  _$SessionImpl(
      {required this.sessionId,
      required this.createdAt,
      required this.startTime,
      required this.duration,
      this.clientId,
      required this.price,
      required this.adminCreatorId,
      required this.partitionPhysicalId})
      : super._();

  @override
  final int sessionId;
  @override
  final DateTime createdAt;
  @override
  final DateTime startTime;
  @override
  final String duration;
  @override
  final int? clientId;
  @override
  final double price;
  @override
  final int adminCreatorId;
  @override
  final int partitionPhysicalId;

  @override
  String toString() {
    return 'Session(sessionId: $sessionId, createdAt: $createdAt, startTime: $startTime, duration: $duration, clientId: $clientId, price: $price, adminCreatorId: $adminCreatorId, partitionPhysicalId: $partitionPhysicalId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.adminCreatorId, adminCreatorId) ||
                other.adminCreatorId == adminCreatorId) &&
            (identical(other.partitionPhysicalId, partitionPhysicalId) ||
                other.partitionPhysicalId == partitionPhysicalId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, sessionId, createdAt, startTime,
      duration, clientId, price, adminCreatorId, partitionPhysicalId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      __$$SessionImplCopyWithImpl<_$SessionImpl>(this, _$identity);
}

abstract class _Session extends Session {
  factory _Session(
      {required final int sessionId,
      required final DateTime createdAt,
      required final DateTime startTime,
      required final String duration,
      final int? clientId,
      required final double price,
      required final int adminCreatorId,
      required final int partitionPhysicalId}) = _$SessionImpl;
  _Session._() : super._();

  @override
  int get sessionId;
  @override
  DateTime get createdAt;
  @override
  DateTime get startTime;
  @override
  String get duration;
  @override
  int? get clientId;
  @override
  double get price;
  @override
  int get adminCreatorId;
  @override
  int get partitionPhysicalId;
  @override
  @JsonKey(ignore: true)
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
