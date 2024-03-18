// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'club_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ClubType _$ClubTypeFromJson(Map<String, dynamic> json) {
  return _ClubType.fromJson(json);
}

/// @nodoc
mixin _$ClubType {
  int get club_type_id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ClubTypeCopyWith<ClubType> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClubTypeCopyWith<$Res> {
  factory $ClubTypeCopyWith(ClubType value, $Res Function(ClubType) then) =
      _$ClubTypeCopyWithImpl<$Res, ClubType>;
  @useResult
  $Res call({int club_type_id, String name});
}

/// @nodoc
class _$ClubTypeCopyWithImpl<$Res, $Val extends ClubType>
    implements $ClubTypeCopyWith<$Res> {
  _$ClubTypeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? club_type_id = null,
    Object? name = null,
  }) {
    return _then(_value.copyWith(
      club_type_id: null == club_type_id
          ? _value.club_type_id
          : club_type_id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClubTypeImplCopyWith<$Res>
    implements $ClubTypeCopyWith<$Res> {
  factory _$$ClubTypeImplCopyWith(
          _$ClubTypeImpl value, $Res Function(_$ClubTypeImpl) then) =
      __$$ClubTypeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int club_type_id, String name});
}

/// @nodoc
class __$$ClubTypeImplCopyWithImpl<$Res>
    extends _$ClubTypeCopyWithImpl<$Res, _$ClubTypeImpl>
    implements _$$ClubTypeImplCopyWith<$Res> {
  __$$ClubTypeImplCopyWithImpl(
      _$ClubTypeImpl _value, $Res Function(_$ClubTypeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? club_type_id = null,
    Object? name = null,
  }) {
    return _then(_$ClubTypeImpl(
      club_type_id: null == club_type_id
          ? _value.club_type_id
          : club_type_id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClubTypeImpl implements _ClubType {
  _$ClubTypeImpl({required this.club_type_id, required this.name});

  factory _$ClubTypeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClubTypeImplFromJson(json);

  @override
  final int club_type_id;
  @override
  final String name;

  @override
  String toString() {
    return 'ClubType(club_type_id: $club_type_id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClubTypeImpl &&
            (identical(other.club_type_id, club_type_id) ||
                other.club_type_id == club_type_id) &&
            (identical(other.name, name) || other.name == name));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, club_type_id, name);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ClubTypeImplCopyWith<_$ClubTypeImpl> get copyWith =>
      __$$ClubTypeImplCopyWithImpl<_$ClubTypeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClubTypeImplToJson(
      this,
    );
  }
}

abstract class _ClubType implements ClubType {
  factory _ClubType(
      {required final int club_type_id,
      required final String name}) = _$ClubTypeImpl;

  factory _ClubType.fromJson(Map<String, dynamic> json) =
      _$ClubTypeImpl.fromJson;

  @override
  int get club_type_id;
  @override
  String get name;
  @override
  @JsonKey(ignore: true)
  _$$ClubTypeImplCopyWith<_$ClubTypeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
