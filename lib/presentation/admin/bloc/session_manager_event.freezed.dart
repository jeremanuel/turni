// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_manager_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SessionManagerEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DateTime newDate) changeDateEvent,
    required TResult Function() loadSessions,
    required TResult Function(ClubPartition newClubPartition)
        changeClubPartition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DateTime newDate)? changeDateEvent,
    TResult? Function()? loadSessions,
    TResult? Function(ClubPartition newClubPartition)? changeClubPartition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DateTime newDate)? changeDateEvent,
    TResult Function()? loadSessions,
    TResult Function(ClubPartition newClubPartition)? changeClubPartition,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionChangeDateEvent value) changeDateEvent,
    required TResult Function(SessionLoadEvent value) loadSessions,
    required TResult Function(ChangeClubPartitionEvent value)
        changeClubPartition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult? Function(SessionLoadEvent value)? loadSessions,
    TResult? Function(ChangeClubPartitionEvent value)? changeClubPartition,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult Function(SessionLoadEvent value)? loadSessions,
    TResult Function(ChangeClubPartitionEvent value)? changeClubPartition,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionManagerEventCopyWith<$Res> {
  factory $SessionManagerEventCopyWith(
          SessionManagerEvent value, $Res Function(SessionManagerEvent) then) =
      _$SessionManagerEventCopyWithImpl<$Res, SessionManagerEvent>;
}

/// @nodoc
class _$SessionManagerEventCopyWithImpl<$Res, $Val extends SessionManagerEvent>
    implements $SessionManagerEventCopyWith<$Res> {
  _$SessionManagerEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$SessionChangeDateEventImplCopyWith<$Res> {
  factory _$$SessionChangeDateEventImplCopyWith(
          _$SessionChangeDateEventImpl value,
          $Res Function(_$SessionChangeDateEventImpl) then) =
      __$$SessionChangeDateEventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DateTime newDate});
}

/// @nodoc
class __$$SessionChangeDateEventImplCopyWithImpl<$Res>
    extends _$SessionManagerEventCopyWithImpl<$Res,
        _$SessionChangeDateEventImpl>
    implements _$$SessionChangeDateEventImplCopyWith<$Res> {
  __$$SessionChangeDateEventImplCopyWithImpl(
      _$SessionChangeDateEventImpl _value,
      $Res Function(_$SessionChangeDateEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newDate = null,
  }) {
    return _then(_$SessionChangeDateEventImpl(
      null == newDate
          ? _value.newDate
          : newDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$SessionChangeDateEventImpl implements SessionChangeDateEvent {
  _$SessionChangeDateEventImpl(this.newDate);

  @override
  final DateTime newDate;

  @override
  String toString() {
    return 'SessionManagerEvent.changeDateEvent(newDate: $newDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionChangeDateEventImpl &&
            (identical(other.newDate, newDate) || other.newDate == newDate));
  }

  @override
  int get hashCode => Object.hash(runtimeType, newDate);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionChangeDateEventImplCopyWith<_$SessionChangeDateEventImpl>
      get copyWith => __$$SessionChangeDateEventImplCopyWithImpl<
          _$SessionChangeDateEventImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DateTime newDate) changeDateEvent,
    required TResult Function() loadSessions,
    required TResult Function(ClubPartition newClubPartition)
        changeClubPartition,
  }) {
    return changeDateEvent(newDate);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DateTime newDate)? changeDateEvent,
    TResult? Function()? loadSessions,
    TResult? Function(ClubPartition newClubPartition)? changeClubPartition,
  }) {
    return changeDateEvent?.call(newDate);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DateTime newDate)? changeDateEvent,
    TResult Function()? loadSessions,
    TResult Function(ClubPartition newClubPartition)? changeClubPartition,
    required TResult orElse(),
  }) {
    if (changeDateEvent != null) {
      return changeDateEvent(newDate);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionChangeDateEvent value) changeDateEvent,
    required TResult Function(SessionLoadEvent value) loadSessions,
    required TResult Function(ChangeClubPartitionEvent value)
        changeClubPartition,
  }) {
    return changeDateEvent(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult? Function(SessionLoadEvent value)? loadSessions,
    TResult? Function(ChangeClubPartitionEvent value)? changeClubPartition,
  }) {
    return changeDateEvent?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult Function(SessionLoadEvent value)? loadSessions,
    TResult Function(ChangeClubPartitionEvent value)? changeClubPartition,
    required TResult orElse(),
  }) {
    if (changeDateEvent != null) {
      return changeDateEvent(this);
    }
    return orElse();
  }
}

abstract class SessionChangeDateEvent implements SessionManagerEvent {
  factory SessionChangeDateEvent(final DateTime newDate) =
      _$SessionChangeDateEventImpl;

  DateTime get newDate;
  @JsonKey(ignore: true)
  _$$SessionChangeDateEventImplCopyWith<_$SessionChangeDateEventImpl>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$SessionLoadEventImplCopyWith<$Res> {
  factory _$$SessionLoadEventImplCopyWith(_$SessionLoadEventImpl value,
          $Res Function(_$SessionLoadEventImpl) then) =
      __$$SessionLoadEventImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$SessionLoadEventImplCopyWithImpl<$Res>
    extends _$SessionManagerEventCopyWithImpl<$Res, _$SessionLoadEventImpl>
    implements _$$SessionLoadEventImplCopyWith<$Res> {
  __$$SessionLoadEventImplCopyWithImpl(_$SessionLoadEventImpl _value,
      $Res Function(_$SessionLoadEventImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$SessionLoadEventImpl implements SessionLoadEvent {
  _$SessionLoadEventImpl();

  @override
  String toString() {
    return 'SessionManagerEvent.loadSessions()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$SessionLoadEventImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DateTime newDate) changeDateEvent,
    required TResult Function() loadSessions,
    required TResult Function(ClubPartition newClubPartition)
        changeClubPartition,
  }) {
    return loadSessions();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DateTime newDate)? changeDateEvent,
    TResult? Function()? loadSessions,
    TResult? Function(ClubPartition newClubPartition)? changeClubPartition,
  }) {
    return loadSessions?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DateTime newDate)? changeDateEvent,
    TResult Function()? loadSessions,
    TResult Function(ClubPartition newClubPartition)? changeClubPartition,
    required TResult orElse(),
  }) {
    if (loadSessions != null) {
      return loadSessions();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionChangeDateEvent value) changeDateEvent,
    required TResult Function(SessionLoadEvent value) loadSessions,
    required TResult Function(ChangeClubPartitionEvent value)
        changeClubPartition,
  }) {
    return loadSessions(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult? Function(SessionLoadEvent value)? loadSessions,
    TResult? Function(ChangeClubPartitionEvent value)? changeClubPartition,
  }) {
    return loadSessions?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult Function(SessionLoadEvent value)? loadSessions,
    TResult Function(ChangeClubPartitionEvent value)? changeClubPartition,
    required TResult orElse(),
  }) {
    if (loadSessions != null) {
      return loadSessions(this);
    }
    return orElse();
  }
}

abstract class SessionLoadEvent implements SessionManagerEvent {
  factory SessionLoadEvent() = _$SessionLoadEventImpl;
}

/// @nodoc
abstract class _$$ChangeClubPartitionEventImplCopyWith<$Res> {
  factory _$$ChangeClubPartitionEventImplCopyWith(
          _$ChangeClubPartitionEventImpl value,
          $Res Function(_$ChangeClubPartitionEventImpl) then) =
      __$$ChangeClubPartitionEventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({ClubPartition newClubPartition});

  $ClubPartitionCopyWith<$Res> get newClubPartition;
}

/// @nodoc
class __$$ChangeClubPartitionEventImplCopyWithImpl<$Res>
    extends _$SessionManagerEventCopyWithImpl<$Res,
        _$ChangeClubPartitionEventImpl>
    implements _$$ChangeClubPartitionEventImplCopyWith<$Res> {
  __$$ChangeClubPartitionEventImplCopyWithImpl(
      _$ChangeClubPartitionEventImpl _value,
      $Res Function(_$ChangeClubPartitionEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? newClubPartition = null,
  }) {
    return _then(_$ChangeClubPartitionEventImpl(
      null == newClubPartition
          ? _value.newClubPartition
          : newClubPartition // ignore: cast_nullable_to_non_nullable
              as ClubPartition,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $ClubPartitionCopyWith<$Res> get newClubPartition {
    return $ClubPartitionCopyWith<$Res>(_value.newClubPartition, (value) {
      return _then(_value.copyWith(newClubPartition: value));
    });
  }
}

/// @nodoc

class _$ChangeClubPartitionEventImpl implements ChangeClubPartitionEvent {
  _$ChangeClubPartitionEventImpl(this.newClubPartition);

  @override
  final ClubPartition newClubPartition;

  @override
  String toString() {
    return 'SessionManagerEvent.changeClubPartition(newClubPartition: $newClubPartition)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChangeClubPartitionEventImpl &&
            (identical(other.newClubPartition, newClubPartition) ||
                other.newClubPartition == newClubPartition));
  }

  @override
  int get hashCode => Object.hash(runtimeType, newClubPartition);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChangeClubPartitionEventImplCopyWith<_$ChangeClubPartitionEventImpl>
      get copyWith => __$$ChangeClubPartitionEventImplCopyWithImpl<
          _$ChangeClubPartitionEventImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DateTime newDate) changeDateEvent,
    required TResult Function() loadSessions,
    required TResult Function(ClubPartition newClubPartition)
        changeClubPartition,
  }) {
    return changeClubPartition(newClubPartition);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DateTime newDate)? changeDateEvent,
    TResult? Function()? loadSessions,
    TResult? Function(ClubPartition newClubPartition)? changeClubPartition,
  }) {
    return changeClubPartition?.call(newClubPartition);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DateTime newDate)? changeDateEvent,
    TResult Function()? loadSessions,
    TResult Function(ClubPartition newClubPartition)? changeClubPartition,
    required TResult orElse(),
  }) {
    if (changeClubPartition != null) {
      return changeClubPartition(newClubPartition);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(SessionChangeDateEvent value) changeDateEvent,
    required TResult Function(SessionLoadEvent value) loadSessions,
    required TResult Function(ChangeClubPartitionEvent value)
        changeClubPartition,
  }) {
    return changeClubPartition(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult? Function(SessionLoadEvent value)? loadSessions,
    TResult? Function(ChangeClubPartitionEvent value)? changeClubPartition,
  }) {
    return changeClubPartition?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(SessionChangeDateEvent value)? changeDateEvent,
    TResult Function(SessionLoadEvent value)? loadSessions,
    TResult Function(ChangeClubPartitionEvent value)? changeClubPartition,
    required TResult orElse(),
  }) {
    if (changeClubPartition != null) {
      return changeClubPartition(this);
    }
    return orElse();
  }
}

abstract class ChangeClubPartitionEvent implements SessionManagerEvent {
  factory ChangeClubPartitionEvent(final ClubPartition newClubPartition) =
      _$ChangeClubPartitionEventImpl;

  ClubPartition get newClubPartition;
  @JsonKey(ignore: true)
  _$$ChangeClubPartitionEventImplCopyWith<_$ChangeClubPartitionEventImpl>
      get copyWith => throw _privateConstructorUsedError;
}
