// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'club_partition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ClubPartition {
  int? get club_partition_id => throw _privateConstructorUsedError;
  int get club_id => throw _privateConstructorUsedError;
  int get club_type_id => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError; // Relations
  List<PhysicalPartition>? get physicalPartitions =>
      throw _privateConstructorUsedError;
  ClubType? get clubType => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ClubPartitionCopyWith<ClubPartition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClubPartitionCopyWith<$Res> {
  factory $ClubPartitionCopyWith(
          ClubPartition value, $Res Function(ClubPartition) then) =
      _$ClubPartitionCopyWithImpl<$Res, ClubPartition>;
  @useResult
  $Res call(
      {int? club_partition_id,
      int club_id,
      int club_type_id,
      String phone,
      List<PhysicalPartition>? physicalPartitions,
      ClubType? clubType});

  $ClubTypeCopyWith<$Res>? get clubType;
}

/// @nodoc
class _$ClubPartitionCopyWithImpl<$Res, $Val extends ClubPartition>
    implements $ClubPartitionCopyWith<$Res> {
  _$ClubPartitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? club_partition_id = freezed,
    Object? club_id = null,
    Object? club_type_id = null,
    Object? phone = null,
    Object? physicalPartitions = freezed,
    Object? clubType = freezed,
  }) {
    return _then(_value.copyWith(
      club_partition_id: freezed == club_partition_id
          ? _value.club_partition_id
          : club_partition_id // ignore: cast_nullable_to_non_nullable
              as int?,
      club_id: null == club_id
          ? _value.club_id
          : club_id // ignore: cast_nullable_to_non_nullable
              as int,
      club_type_id: null == club_type_id
          ? _value.club_type_id
          : club_type_id // ignore: cast_nullable_to_non_nullable
              as int,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      physicalPartitions: freezed == physicalPartitions
          ? _value.physicalPartitions
          : physicalPartitions // ignore: cast_nullable_to_non_nullable
              as List<PhysicalPartition>?,
      clubType: freezed == clubType
          ? _value.clubType
          : clubType // ignore: cast_nullable_to_non_nullable
              as ClubType?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ClubTypeCopyWith<$Res>? get clubType {
    if (_value.clubType == null) {
      return null;
    }

    return $ClubTypeCopyWith<$Res>(_value.clubType!, (value) {
      return _then(_value.copyWith(clubType: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClubPartitionImplCopyWith<$Res>
    implements $ClubPartitionCopyWith<$Res> {
  factory _$$ClubPartitionImplCopyWith(
          _$ClubPartitionImpl value, $Res Function(_$ClubPartitionImpl) then) =
      __$$ClubPartitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? club_partition_id,
      int club_id,
      int club_type_id,
      String phone,
      List<PhysicalPartition>? physicalPartitions,
      ClubType? clubType});

  @override
  $ClubTypeCopyWith<$Res>? get clubType;
}

/// @nodoc
class __$$ClubPartitionImplCopyWithImpl<$Res>
    extends _$ClubPartitionCopyWithImpl<$Res, _$ClubPartitionImpl>
    implements _$$ClubPartitionImplCopyWith<$Res> {
  __$$ClubPartitionImplCopyWithImpl(
      _$ClubPartitionImpl _value, $Res Function(_$ClubPartitionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? club_partition_id = freezed,
    Object? club_id = null,
    Object? club_type_id = null,
    Object? phone = null,
    Object? physicalPartitions = freezed,
    Object? clubType = freezed,
  }) {
    return _then(_$ClubPartitionImpl(
      club_partition_id: freezed == club_partition_id
          ? _value.club_partition_id
          : club_partition_id // ignore: cast_nullable_to_non_nullable
              as int?,
      club_id: null == club_id
          ? _value.club_id
          : club_id // ignore: cast_nullable_to_non_nullable
              as int,
      club_type_id: null == club_type_id
          ? _value.club_type_id
          : club_type_id // ignore: cast_nullable_to_non_nullable
              as int,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      physicalPartitions: freezed == physicalPartitions
          ? _value._physicalPartitions
          : physicalPartitions // ignore: cast_nullable_to_non_nullable
              as List<PhysicalPartition>?,
      clubType: freezed == clubType
          ? _value.clubType
          : clubType // ignore: cast_nullable_to_non_nullable
              as ClubType?,
    ));
  }
}

/// @nodoc

class _$ClubPartitionImpl implements _ClubPartition {
  const _$ClubPartitionImpl(
      {this.club_partition_id,
      required this.club_id,
      required this.club_type_id,
      required this.phone,
      final List<PhysicalPartition>? physicalPartitions,
      this.clubType})
      : _physicalPartitions = physicalPartitions;

  @override
  final int? club_partition_id;
  @override
  final int club_id;
  @override
  final int club_type_id;
  @override
  final String phone;
// Relations
  final List<PhysicalPartition>? _physicalPartitions;
// Relations
  @override
  List<PhysicalPartition>? get physicalPartitions {
    final value = _physicalPartitions;
    if (value == null) return null;
    if (_physicalPartitions is EqualUnmodifiableListView)
      return _physicalPartitions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final ClubType? clubType;

  @override
  String toString() {
    return 'ClubPartition(club_partition_id: $club_partition_id, club_id: $club_id, club_type_id: $club_type_id, phone: $phone, physicalPartitions: $physicalPartitions, clubType: $clubType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClubPartitionImpl &&
            (identical(other.club_partition_id, club_partition_id) ||
                other.club_partition_id == club_partition_id) &&
            (identical(other.club_id, club_id) || other.club_id == club_id) &&
            (identical(other.club_type_id, club_type_id) ||
                other.club_type_id == club_type_id) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            const DeepCollectionEquality()
                .equals(other._physicalPartitions, _physicalPartitions) &&
            (identical(other.clubType, clubType) ||
                other.clubType == clubType));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      club_partition_id,
      club_id,
      club_type_id,
      phone,
      const DeepCollectionEquality().hash(_physicalPartitions),
      clubType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ClubPartitionImplCopyWith<_$ClubPartitionImpl> get copyWith =>
      __$$ClubPartitionImplCopyWithImpl<_$ClubPartitionImpl>(this, _$identity);
}

abstract class _ClubPartition implements ClubPartition {
  const factory _ClubPartition(
      {final int? club_partition_id,
      required final int club_id,
      required final int club_type_id,
      required final String phone,
      final List<PhysicalPartition>? physicalPartitions,
      final ClubType? clubType}) = _$ClubPartitionImpl;

  @override
  int? get club_partition_id;
  @override
  int get club_id;
  @override
  int get club_type_id;
  @override
  String get phone;
  @override // Relations
  List<PhysicalPartition>? get physicalPartitions;
  @override
  ClubType? get clubType;
  @override
  @JsonKey(ignore: true)
  _$$ClubPartitionImplCopyWith<_$ClubPartitionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
