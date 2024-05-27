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

Session _$SessionFromJson(Map<String, dynamic> json) {
  return _Session.fromJson(json);
}

/// @nodoc
mixin _$Session {
  @JsonKey(name: "session_id")
  int get sessionId => throw _privateConstructorUsedError;
  @JsonKey(name: "created_at")
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: "start_time")
  DateTime get startTime => throw _privateConstructorUsedError;
  String get duration => throw _privateConstructorUsedError;
  @JsonKey(name: "client_id")
  int? get clientId => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  @JsonKey(name: "admin_creator_id")
  int? get adminCreatorId => throw _privateConstructorUsedError;
  @JsonKey(name: "partition_physical_id")
  int get partitionPhysicalId => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SessionCopyWith<Session> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionCopyWith<$Res> {
  factory $SessionCopyWith(Session value, $Res Function(Session) then) =
      _$SessionCopyWithImpl<$Res, Session>;
  @useResult
  $Res call(
      {@JsonKey(name: "session_id") int sessionId,
      @JsonKey(name: "created_at") DateTime createdAt,
      @JsonKey(name: "start_time") DateTime startTime,
      String duration,
      @JsonKey(name: "client_id") int? clientId,
      double price,
      @JsonKey(name: "admin_creator_id") int? adminCreatorId,
      @JsonKey(name: "partition_physical_id") int partitionPhysicalId});
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
    Object? adminCreatorId = freezed,
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
      adminCreatorId: freezed == adminCreatorId
          ? _value.adminCreatorId
          : adminCreatorId // ignore: cast_nullable_to_non_nullable
              as int?,
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
      {@JsonKey(name: "session_id") int sessionId,
      @JsonKey(name: "created_at") DateTime createdAt,
      @JsonKey(name: "start_time") DateTime startTime,
      String duration,
      @JsonKey(name: "client_id") int? clientId,
      double price,
      @JsonKey(name: "admin_creator_id") int? adminCreatorId,
      @JsonKey(name: "partition_physical_id") int partitionPhysicalId});
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
    Object? adminCreatorId = freezed,
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
      adminCreatorId: freezed == adminCreatorId
          ? _value.adminCreatorId
          : adminCreatorId // ignore: cast_nullable_to_non_nullable
              as int?,
      partitionPhysicalId: null == partitionPhysicalId
          ? _value.partitionPhysicalId
          : partitionPhysicalId // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionImpl extends _Session {
  _$SessionImpl(
      {@JsonKey(name: "session_id") required this.sessionId,
      @JsonKey(name: "created_at") required this.createdAt,
      @JsonKey(name: "start_time") required this.startTime,
      required this.duration,
      @JsonKey(name: "client_id") this.clientId,
      required this.price,
      @JsonKey(name: "admin_creator_id") this.adminCreatorId,
      @JsonKey(name: "partition_physical_id")
      required this.partitionPhysicalId})
      : super._();

  factory _$SessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$SessionImplFromJson(json);

  @override
  @JsonKey(name: "session_id")
  final int sessionId;
  @override
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @override
  @JsonKey(name: "start_time")
  final DateTime startTime;
  @override
  final String duration;
  @override
  @JsonKey(name: "client_id")
  final int? clientId;
  @override
  final double price;
  @override
  @JsonKey(name: "admin_creator_id")
  final int? adminCreatorId;
  @override
  @JsonKey(name: "partition_physical_id")
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

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, sessionId, createdAt, startTime,
      duration, clientId, price, adminCreatorId, partitionPhysicalId);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      __$$SessionImplCopyWithImpl<_$SessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SessionImplToJson(
      this,
    );
  }
}

abstract class _Session extends Session {
  factory _Session(
      {@JsonKey(name: "session_id") required final int sessionId,
      @JsonKey(name: "created_at") required final DateTime createdAt,
      @JsonKey(name: "start_time") required final DateTime startTime,
      required final String duration,
      @JsonKey(name: "client_id") final int? clientId,
      required final double price,
      @JsonKey(name: "admin_creator_id") final int? adminCreatorId,
      @JsonKey(name: "partition_physical_id")
      required final int partitionPhysicalId}) = _$SessionImpl;
  _Session._() : super._();

  factory _Session.fromJson(Map<String, dynamic> json) = _$SessionImpl.fromJson;

  @override
  @JsonKey(name: "session_id")
  int get sessionId;
  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;
  @override
  @JsonKey(name: "start_time")
  DateTime get startTime;
  @override
  String get duration;
  @override
  @JsonKey(name: "client_id")
  int? get clientId;
  @override
  double get price;
  @override
  @JsonKey(name: "admin_creator_id")
  int? get adminCreatorId;
  @override
  @JsonKey(name: "partition_physical_id")
  int get partitionPhysicalId;
  @override
  @JsonKey(ignore: true)
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
