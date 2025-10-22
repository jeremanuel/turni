// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Session {

@JsonKey(name: "session_id") int get sessionId;@JsonKey(name: "created_at") DateTime get createdAt;@JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale) DateTime get startTime;@JsonKey(defaultValue: 90) int get duration;@JsonKey(name: "client_id") int? get clientId;@JsonKey(fromJson: ValueTransformers.fromJsonDouble) double get price;@JsonKey(name: "admin_creator_id") int? get adminCreatorId;@JsonKey(name: "partition_physical_id") int get partitionPhysicalId;@JsonKey(name: "club_name") String? get clubName;@JsonKey(name: "club_type_name") String? get clubTypeName;@JsonKey(includeIfNull: false) Client? get client;@JsonKey(name: "partition_physical", includeIfNull: false) PhysicalPartition? get physicalPartition;
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionCopyWith<Session> get copyWith => _$SessionCopyWithImpl<Session>(this as Session, _$identity);

  /// Serializes this Session to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Session&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.price, price) || other.price == price)&&(identical(other.adminCreatorId, adminCreatorId) || other.adminCreatorId == adminCreatorId)&&(identical(other.partitionPhysicalId, partitionPhysicalId) || other.partitionPhysicalId == partitionPhysicalId)&&(identical(other.clubName, clubName) || other.clubName == clubName)&&(identical(other.clubTypeName, clubTypeName) || other.clubTypeName == clubTypeName)&&(identical(other.client, client) || other.client == client)&&(identical(other.physicalPartition, physicalPartition) || other.physicalPartition == physicalPartition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,createdAt,startTime,duration,clientId,price,adminCreatorId,partitionPhysicalId,clubName,clubTypeName,client,physicalPartition);

@override
String toString() {
  return 'Session(sessionId: $sessionId, createdAt: $createdAt, startTime: $startTime, duration: $duration, clientId: $clientId, price: $price, adminCreatorId: $adminCreatorId, partitionPhysicalId: $partitionPhysicalId, clubName: $clubName, clubTypeName: $clubTypeName, client: $client, physicalPartition: $physicalPartition)';
}


}

/// @nodoc
abstract mixin class $SessionCopyWith<$Res>  {
  factory $SessionCopyWith(Session value, $Res Function(Session) _then) = _$SessionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: "session_id") int sessionId,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale) DateTime startTime,@JsonKey(defaultValue: 90) int duration,@JsonKey(name: "client_id") int? clientId,@JsonKey(fromJson: ValueTransformers.fromJsonDouble) double price,@JsonKey(name: "admin_creator_id") int? adminCreatorId,@JsonKey(name: "partition_physical_id") int partitionPhysicalId,@JsonKey(name: "club_name") String? clubName,@JsonKey(name: "club_type_name") String? clubTypeName,@JsonKey(includeIfNull: false) Client? client,@JsonKey(name: "partition_physical", includeIfNull: false) PhysicalPartition? physicalPartition
});


$ClientCopyWith<$Res>? get client;$PhysicalPartitionCopyWith<$Res>? get physicalPartition;

}
/// @nodoc
class _$SessionCopyWithImpl<$Res>
    implements $SessionCopyWith<$Res> {
  _$SessionCopyWithImpl(this._self, this._then);

  final Session _self;
  final $Res Function(Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sessionId = null,Object? createdAt = null,Object? startTime = null,Object? duration = null,Object? clientId = freezed,Object? price = null,Object? adminCreatorId = freezed,Object? partitionPhysicalId = null,Object? clubName = freezed,Object? clubTypeName = freezed,Object? client = freezed,Object? physicalPartition = freezed,}) {
  return _then(_self.copyWith(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as int?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,adminCreatorId: freezed == adminCreatorId ? _self.adminCreatorId : adminCreatorId // ignore: cast_nullable_to_non_nullable
as int?,partitionPhysicalId: null == partitionPhysicalId ? _self.partitionPhysicalId : partitionPhysicalId // ignore: cast_nullable_to_non_nullable
as int,clubName: freezed == clubName ? _self.clubName : clubName // ignore: cast_nullable_to_non_nullable
as String?,clubTypeName: freezed == clubTypeName ? _self.clubTypeName : clubTypeName // ignore: cast_nullable_to_non_nullable
as String?,client: freezed == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as Client?,physicalPartition: freezed == physicalPartition ? _self.physicalPartition : physicalPartition // ignore: cast_nullable_to_non_nullable
as PhysicalPartition?,
  ));
}
/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClientCopyWith<$Res>? get client {
    if (_self.client == null) {
    return null;
  }

  return $ClientCopyWith<$Res>(_self.client!, (value) {
    return _then(_self.copyWith(client: value));
  });
}/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhysicalPartitionCopyWith<$Res>? get physicalPartition {
    if (_self.physicalPartition == null) {
    return null;
  }

  return $PhysicalPartitionCopyWith<$Res>(_self.physicalPartition!, (value) {
    return _then(_self.copyWith(physicalPartition: value));
  });
}
}


/// Adds pattern-matching-related methods to [Session].
extension SessionPatterns on Session {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Session value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Session value)  $default,){
final _that = this;
switch (_that) {
case _Session():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Session value)?  $default,){
final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: "session_id")  int sessionId, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)  DateTime startTime, @JsonKey(defaultValue: 90)  int duration, @JsonKey(name: "client_id")  int? clientId, @JsonKey(fromJson: ValueTransformers.fromJsonDouble)  double price, @JsonKey(name: "admin_creator_id")  int? adminCreatorId, @JsonKey(name: "partition_physical_id")  int partitionPhysicalId, @JsonKey(name: "club_name")  String? clubName, @JsonKey(name: "club_type_name")  String? clubTypeName, @JsonKey(includeIfNull: false)  Client? client, @JsonKey(name: "partition_physical", includeIfNull: false)  PhysicalPartition? physicalPartition)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.sessionId,_that.createdAt,_that.startTime,_that.duration,_that.clientId,_that.price,_that.adminCreatorId,_that.partitionPhysicalId,_that.clubName,_that.clubTypeName,_that.client,_that.physicalPartition);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: "session_id")  int sessionId, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)  DateTime startTime, @JsonKey(defaultValue: 90)  int duration, @JsonKey(name: "client_id")  int? clientId, @JsonKey(fromJson: ValueTransformers.fromJsonDouble)  double price, @JsonKey(name: "admin_creator_id")  int? adminCreatorId, @JsonKey(name: "partition_physical_id")  int partitionPhysicalId, @JsonKey(name: "club_name")  String? clubName, @JsonKey(name: "club_type_name")  String? clubTypeName, @JsonKey(includeIfNull: false)  Client? client, @JsonKey(name: "partition_physical", includeIfNull: false)  PhysicalPartition? physicalPartition)  $default,) {final _that = this;
switch (_that) {
case _Session():
return $default(_that.sessionId,_that.createdAt,_that.startTime,_that.duration,_that.clientId,_that.price,_that.adminCreatorId,_that.partitionPhysicalId,_that.clubName,_that.clubTypeName,_that.client,_that.physicalPartition);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: "session_id")  int sessionId, @JsonKey(name: "created_at")  DateTime createdAt, @JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale)  DateTime startTime, @JsonKey(defaultValue: 90)  int duration, @JsonKey(name: "client_id")  int? clientId, @JsonKey(fromJson: ValueTransformers.fromJsonDouble)  double price, @JsonKey(name: "admin_creator_id")  int? adminCreatorId, @JsonKey(name: "partition_physical_id")  int partitionPhysicalId, @JsonKey(name: "club_name")  String? clubName, @JsonKey(name: "club_type_name")  String? clubTypeName, @JsonKey(includeIfNull: false)  Client? client, @JsonKey(name: "partition_physical", includeIfNull: false)  PhysicalPartition? physicalPartition)?  $default,) {final _that = this;
switch (_that) {
case _Session() when $default != null:
return $default(_that.sessionId,_that.createdAt,_that.startTime,_that.duration,_that.clientId,_that.price,_that.adminCreatorId,_that.partitionPhysicalId,_that.clubName,_that.clubTypeName,_that.client,_that.physicalPartition);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Session extends Session {
   _Session({@JsonKey(name: "session_id") required this.sessionId, @JsonKey(name: "created_at") required this.createdAt, @JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale) required this.startTime, @JsonKey(defaultValue: 90) required this.duration, @JsonKey(name: "client_id") this.clientId, @JsonKey(fromJson: ValueTransformers.fromJsonDouble) required this.price, @JsonKey(name: "admin_creator_id") this.adminCreatorId, @JsonKey(name: "partition_physical_id") required this.partitionPhysicalId, @JsonKey(name: "club_name") this.clubName, @JsonKey(name: "club_type_name") this.clubTypeName, @JsonKey(includeIfNull: false) this.client, @JsonKey(name: "partition_physical", includeIfNull: false) this.physicalPartition}): super._();
  factory _Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);

@override@JsonKey(name: "session_id") final  int sessionId;
@override@JsonKey(name: "created_at") final  DateTime createdAt;
@override@JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale) final  DateTime startTime;
@override@JsonKey(defaultValue: 90) final  int duration;
@override@JsonKey(name: "client_id") final  int? clientId;
@override@JsonKey(fromJson: ValueTransformers.fromJsonDouble) final  double price;
@override@JsonKey(name: "admin_creator_id") final  int? adminCreatorId;
@override@JsonKey(name: "partition_physical_id") final  int partitionPhysicalId;
@override@JsonKey(name: "club_name") final  String? clubName;
@override@JsonKey(name: "club_type_name") final  String? clubTypeName;
@override@JsonKey(includeIfNull: false) final  Client? client;
@override@JsonKey(name: "partition_physical", includeIfNull: false) final  PhysicalPartition? physicalPartition;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SessionCopyWith<_Session> get copyWith => __$SessionCopyWithImpl<_Session>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Session&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.clientId, clientId) || other.clientId == clientId)&&(identical(other.price, price) || other.price == price)&&(identical(other.adminCreatorId, adminCreatorId) || other.adminCreatorId == adminCreatorId)&&(identical(other.partitionPhysicalId, partitionPhysicalId) || other.partitionPhysicalId == partitionPhysicalId)&&(identical(other.clubName, clubName) || other.clubName == clubName)&&(identical(other.clubTypeName, clubTypeName) || other.clubTypeName == clubTypeName)&&(identical(other.client, client) || other.client == client)&&(identical(other.physicalPartition, physicalPartition) || other.physicalPartition == physicalPartition));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sessionId,createdAt,startTime,duration,clientId,price,adminCreatorId,partitionPhysicalId,clubName,clubTypeName,client,physicalPartition);

@override
String toString() {
  return 'Session(sessionId: $sessionId, createdAt: $createdAt, startTime: $startTime, duration: $duration, clientId: $clientId, price: $price, adminCreatorId: $adminCreatorId, partitionPhysicalId: $partitionPhysicalId, clubName: $clubName, clubTypeName: $clubTypeName, client: $client, physicalPartition: $physicalPartition)';
}


}

/// @nodoc
abstract mixin class _$SessionCopyWith<$Res> implements $SessionCopyWith<$Res> {
  factory _$SessionCopyWith(_Session value, $Res Function(_Session) _then) = __$SessionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: "session_id") int sessionId,@JsonKey(name: "created_at") DateTime createdAt,@JsonKey(name: "start_time", fromJson: ValueTransformers.fromJsonDateTimeLocale) DateTime startTime,@JsonKey(defaultValue: 90) int duration,@JsonKey(name: "client_id") int? clientId,@JsonKey(fromJson: ValueTransformers.fromJsonDouble) double price,@JsonKey(name: "admin_creator_id") int? adminCreatorId,@JsonKey(name: "partition_physical_id") int partitionPhysicalId,@JsonKey(name: "club_name") String? clubName,@JsonKey(name: "club_type_name") String? clubTypeName,@JsonKey(includeIfNull: false) Client? client,@JsonKey(name: "partition_physical", includeIfNull: false) PhysicalPartition? physicalPartition
});


@override $ClientCopyWith<$Res>? get client;@override $PhysicalPartitionCopyWith<$Res>? get physicalPartition;

}
/// @nodoc
class __$SessionCopyWithImpl<$Res>
    implements _$SessionCopyWith<$Res> {
  __$SessionCopyWithImpl(this._self, this._then);

  final _Session _self;
  final $Res Function(_Session) _then;

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sessionId = null,Object? createdAt = null,Object? startTime = null,Object? duration = null,Object? clientId = freezed,Object? price = null,Object? adminCreatorId = freezed,Object? partitionPhysicalId = null,Object? clubName = freezed,Object? clubTypeName = freezed,Object? client = freezed,Object? physicalPartition = freezed,}) {
  return _then(_Session(
sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,clientId: freezed == clientId ? _self.clientId : clientId // ignore: cast_nullable_to_non_nullable
as int?,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as double,adminCreatorId: freezed == adminCreatorId ? _self.adminCreatorId : adminCreatorId // ignore: cast_nullable_to_non_nullable
as int?,partitionPhysicalId: null == partitionPhysicalId ? _self.partitionPhysicalId : partitionPhysicalId // ignore: cast_nullable_to_non_nullable
as int,clubName: freezed == clubName ? _self.clubName : clubName // ignore: cast_nullable_to_non_nullable
as String?,clubTypeName: freezed == clubTypeName ? _self.clubTypeName : clubTypeName // ignore: cast_nullable_to_non_nullable
as String?,client: freezed == client ? _self.client : client // ignore: cast_nullable_to_non_nullable
as Client?,physicalPartition: freezed == physicalPartition ? _self.physicalPartition : physicalPartition // ignore: cast_nullable_to_non_nullable
as PhysicalPartition?,
  ));
}

/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClientCopyWith<$Res>? get client {
    if (_self.client == null) {
    return null;
  }

  return $ClientCopyWith<$Res>(_self.client!, (value) {
    return _then(_self.copyWith(client: value));
  });
}/// Create a copy of Session
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PhysicalPartitionCopyWith<$Res>? get physicalPartition {
    if (_self.physicalPartition == null) {
    return null;
  }

  return $PhysicalPartitionCopyWith<$Res>(_self.physicalPartition!, (value) {
    return _then(_self.copyWith(physicalPartition: value));
  });
}
}

// dart format on
