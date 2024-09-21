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
  @JsonKey(
      name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)
  DateTime get startTime => throw _privateConstructorUsedError;
  @JsonKey(defaultValue: 90)
  int get duration => throw _privateConstructorUsedError;
  @JsonKey(name: "client_id")
  int? get clientId => throw _privateConstructorUsedError;
  @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
  double get price => throw _privateConstructorUsedError;
  @JsonKey(name: "admin_creator_id")
  int? get adminCreatorId => throw _privateConstructorUsedError;
  @JsonKey(name: "partition_physical_id")
  int get partitionPhysicalId => throw _privateConstructorUsedError;
  @JsonKey(name: "club_name")
  String? get clubName => throw _privateConstructorUsedError;
  @JsonKey(name: "club_type_name")
  String? get clubTypeName => throw _privateConstructorUsedError;
  @JsonKey(includeIfNull: false)
  Client? get client => throw _privateConstructorUsedError;

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
      @JsonKey(
          name: "start_time",
          fromJson: ValueTransformers.fromJsonDateTimeLocale)
      DateTime startTime,
      @JsonKey(defaultValue: 90) int duration,
      @JsonKey(name: "client_id") int? clientId,
      @JsonKey(fromJson: ValueTransformers.fromJsonDouble) double price,
      @JsonKey(name: "admin_creator_id") int? adminCreatorId,
      @JsonKey(name: "partition_physical_id") int partitionPhysicalId,
      @JsonKey(name: "club_name") String? clubName,
      @JsonKey(name: "club_type_name") String? clubTypeName,
      @JsonKey(includeIfNull: false) Client? client});

  $ClientCopyWith<$Res>? get client;
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
    Object? clubName = freezed,
    Object? clubTypeName = freezed,
    Object? client = freezed,
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
              as int,
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
      clubName: freezed == clubName
          ? _value.clubName
          : clubName // ignore: cast_nullable_to_non_nullable
              as String?,
      clubTypeName: freezed == clubTypeName
          ? _value.clubTypeName
          : clubTypeName // ignore: cast_nullable_to_non_nullable
              as String?,
      client: freezed == client
          ? _value.client
          : client // ignore: cast_nullable_to_non_nullable
              as Client?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ClientCopyWith<$Res>? get client {
    if (_value.client == null) {
      return null;
    }

    return $ClientCopyWith<$Res>(_value.client!, (value) {
      return _then(_value.copyWith(client: value) as $Val);
    });
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
      @JsonKey(
          name: "start_time",
          fromJson: ValueTransformers.fromJsonDateTimeLocale)
      DateTime startTime,
      @JsonKey(defaultValue: 90) int duration,
      @JsonKey(name: "client_id") int? clientId,
      @JsonKey(fromJson: ValueTransformers.fromJsonDouble) double price,
      @JsonKey(name: "admin_creator_id") int? adminCreatorId,
      @JsonKey(name: "partition_physical_id") int partitionPhysicalId,
      @JsonKey(name: "club_name") String? clubName,
      @JsonKey(name: "club_type_name") String? clubTypeName,
      @JsonKey(includeIfNull: false) Client? client});

  @override
  $ClientCopyWith<$Res>? get client;
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
    Object? clubName = freezed,
    Object? clubTypeName = freezed,
    Object? client = freezed,
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
              as int,
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
      clubName: freezed == clubName
          ? _value.clubName
          : clubName // ignore: cast_nullable_to_non_nullable
              as String?,
      clubTypeName: freezed == clubTypeName
          ? _value.clubTypeName
          : clubTypeName // ignore: cast_nullable_to_non_nullable
              as String?,
      client: freezed == client
          ? _value.client
          : client // ignore: cast_nullable_to_non_nullable
              as Client?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SessionImpl extends _Session {
  _$SessionImpl(
      {@JsonKey(name: "session_id") required this.sessionId,
      @JsonKey(name: "created_at") required this.createdAt,
      @JsonKey(
          name: "start_time",
          fromJson: ValueTransformers.fromJsonDateTimeLocale)
      required this.startTime,
      @JsonKey(defaultValue: 90) required this.duration,
      @JsonKey(name: "client_id") this.clientId,
      @JsonKey(fromJson: ValueTransformers.fromJsonDouble) required this.price,
      @JsonKey(name: "admin_creator_id") this.adminCreatorId,
      @JsonKey(name: "partition_physical_id") required this.partitionPhysicalId,
      @JsonKey(name: "club_name") this.clubName,
      @JsonKey(name: "club_type_name") this.clubTypeName,
      @JsonKey(includeIfNull: false) this.client})
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
  @JsonKey(
      name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)
  final DateTime startTime;
  @override
  @JsonKey(defaultValue: 90)
  final int duration;
  @override
  @JsonKey(name: "client_id")
  final int? clientId;
  @override
  @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
  final double price;
  @override
  @JsonKey(name: "admin_creator_id")
  final int? adminCreatorId;
  @override
  @JsonKey(name: "partition_physical_id")
  final int partitionPhysicalId;
  @override
  @JsonKey(name: "club_name")
  final String? clubName;
  @override
  @JsonKey(name: "club_type_name")
  final String? clubTypeName;
  @override
  @JsonKey(includeIfNull: false)
  final Client? client;

  @override
  String toString() {
    return 'Session(sessionId: $sessionId, createdAt: $createdAt, startTime: $startTime, duration: $duration, clientId: $clientId, price: $price, adminCreatorId: $adminCreatorId, partitionPhysicalId: $partitionPhysicalId, clubName: $clubName, clubTypeName: $clubTypeName, client: $client)';
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
                other.partitionPhysicalId == partitionPhysicalId) &&
            (identical(other.clubName, clubName) ||
                other.clubName == clubName) &&
            (identical(other.clubTypeName, clubTypeName) ||
                other.clubTypeName == clubTypeName) &&
            (identical(other.client, client) || other.client == client));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      sessionId,
      createdAt,
      startTime,
      duration,
      clientId,
      price,
      adminCreatorId,
      partitionPhysicalId,
      clubName,
      clubTypeName,
      client);

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
      @JsonKey(
          name: "start_time",
          fromJson: ValueTransformers.fromJsonDateTimeLocale)
      required final DateTime startTime,
      @JsonKey(defaultValue: 90) required final int duration,
      @JsonKey(name: "client_id") final int? clientId,
      @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
      required final double price,
      @JsonKey(name: "admin_creator_id") final int? adminCreatorId,
      @JsonKey(name: "partition_physical_id")
      required final int partitionPhysicalId,
      @JsonKey(name: "club_name") final String? clubName,
      @JsonKey(name: "club_type_name") final String? clubTypeName,
      @JsonKey(includeIfNull: false) final Client? client}) = _$SessionImpl;
  _Session._() : super._();

  factory _Session.fromJson(Map<String, dynamic> json) = _$SessionImpl.fromJson;

  @override
  @JsonKey(name: "session_id")
  int get sessionId;
  @override
  @JsonKey(name: "created_at")
  DateTime get createdAt;
  @override
  @JsonKey(
      name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)
  DateTime get startTime;
  @override
  @JsonKey(defaultValue: 90)
  int get duration;
  @override
  @JsonKey(name: "client_id")
  int? get clientId;
  @override
  @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
  double get price;
  @override
  @JsonKey(name: "admin_creator_id")
  int? get adminCreatorId;
  @override
  @JsonKey(name: "partition_physical_id")
  int get partitionPhysicalId;
  @override
  @JsonKey(name: "club_name")
  String? get clubName;
  @override
  @JsonKey(name: "club_type_name")
  String? get clubTypeName;
  @override
  @JsonKey(includeIfNull: false)
  Client? get client;
  @override
  @JsonKey(ignore: true)
  _$$SessionImplCopyWith<_$SessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
