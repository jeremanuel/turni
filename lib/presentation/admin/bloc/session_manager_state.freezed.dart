// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_manager_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SessionManagerState {
  DateTime get currentDate => throw _privateConstructorUsedError;
  List<Session> get sessions => throw _privateConstructorUsedError;
  List<ClubPartition> get clubPartitions => throw _privateConstructorUsedError;
  ClubPartition? get selectedClubPartition =>
      throw _privateConstructorUsedError;
  dynamic get isFirstLoad => throw _privateConstructorUsedError;
  dynamic get isLoadingSessions => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SessionManagerStateCopyWith<SessionManagerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SessionManagerStateCopyWith<$Res> {
  factory $SessionManagerStateCopyWith(
          SessionManagerState value, $Res Function(SessionManagerState) then) =
      _$SessionManagerStateCopyWithImpl<$Res, SessionManagerState>;
  @useResult
  $Res call(
      {DateTime currentDate,
      List<Session> sessions,
      List<ClubPartition> clubPartitions,
      ClubPartition? selectedClubPartition,
      dynamic isFirstLoad,
      dynamic isLoadingSessions});

  $ClubPartitionCopyWith<$Res>? get selectedClubPartition;
}

/// @nodoc
class _$SessionManagerStateCopyWithImpl<$Res, $Val extends SessionManagerState>
    implements $SessionManagerStateCopyWith<$Res> {
  _$SessionManagerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentDate = null,
    Object? sessions = null,
    Object? clubPartitions = null,
    Object? selectedClubPartition = freezed,
    Object? isFirstLoad = freezed,
    Object? isLoadingSessions = freezed,
  }) {
    return _then(_value.copyWith(
      currentDate: null == currentDate
          ? _value.currentDate
          : currentDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sessions: null == sessions
          ? _value.sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<Session>,
      clubPartitions: null == clubPartitions
          ? _value.clubPartitions
          : clubPartitions // ignore: cast_nullable_to_non_nullable
              as List<ClubPartition>,
      selectedClubPartition: freezed == selectedClubPartition
          ? _value.selectedClubPartition
          : selectedClubPartition // ignore: cast_nullable_to_non_nullable
              as ClubPartition?,
      isFirstLoad: freezed == isFirstLoad
          ? _value.isFirstLoad
          : isFirstLoad // ignore: cast_nullable_to_non_nullable
              as dynamic,
      isLoadingSessions: freezed == isLoadingSessions
          ? _value.isLoadingSessions
          : isLoadingSessions // ignore: cast_nullable_to_non_nullable
              as dynamic,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ClubPartitionCopyWith<$Res>? get selectedClubPartition {
    if (_value.selectedClubPartition == null) {
      return null;
    }

    return $ClubPartitionCopyWith<$Res>(_value.selectedClubPartition!, (value) {
      return _then(_value.copyWith(selectedClubPartition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SessionManagerStateImplCopyWith<$Res>
    implements $SessionManagerStateCopyWith<$Res> {
  factory _$$SessionManagerStateImplCopyWith(_$SessionManagerStateImpl value,
          $Res Function(_$SessionManagerStateImpl) then) =
      __$$SessionManagerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime currentDate,
      List<Session> sessions,
      List<ClubPartition> clubPartitions,
      ClubPartition? selectedClubPartition,
      dynamic isFirstLoad,
      dynamic isLoadingSessions});

  @override
  $ClubPartitionCopyWith<$Res>? get selectedClubPartition;
}

/// @nodoc
class __$$SessionManagerStateImplCopyWithImpl<$Res>
    extends _$SessionManagerStateCopyWithImpl<$Res, _$SessionManagerStateImpl>
    implements _$$SessionManagerStateImplCopyWith<$Res> {
  __$$SessionManagerStateImplCopyWithImpl(_$SessionManagerStateImpl _value,
      $Res Function(_$SessionManagerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentDate = null,
    Object? sessions = null,
    Object? clubPartitions = null,
    Object? selectedClubPartition = freezed,
    Object? isFirstLoad = freezed,
    Object? isLoadingSessions = freezed,
  }) {
    return _then(_$SessionManagerStateImpl(
      currentDate: null == currentDate
          ? _value.currentDate
          : currentDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sessions: null == sessions
          ? _value._sessions
          : sessions // ignore: cast_nullable_to_non_nullable
              as List<Session>,
      clubPartitions: null == clubPartitions
          ? _value._clubPartitions
          : clubPartitions // ignore: cast_nullable_to_non_nullable
              as List<ClubPartition>,
      selectedClubPartition: freezed == selectedClubPartition
          ? _value.selectedClubPartition
          : selectedClubPartition // ignore: cast_nullable_to_non_nullable
              as ClubPartition?,
      isFirstLoad: freezed == isFirstLoad ? _value.isFirstLoad! : isFirstLoad,
      isLoadingSessions: freezed == isLoadingSessions
          ? _value.isLoadingSessions!
          : isLoadingSessions,
    ));
  }
}

/// @nodoc

class _$SessionManagerStateImpl implements _SessionManagerState {
  _$SessionManagerStateImpl(
      {required this.currentDate,
      required final List<Session> sessions,
      required final List<ClubPartition> clubPartitions,
      this.selectedClubPartition,
      this.isFirstLoad = false,
      this.isLoadingSessions = false})
      : _sessions = sessions,
        _clubPartitions = clubPartitions;

  @override
  final DateTime currentDate;
  final List<Session> _sessions;
  @override
  List<Session> get sessions {
    if (_sessions is EqualUnmodifiableListView) return _sessions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sessions);
  }

  final List<ClubPartition> _clubPartitions;
  @override
  List<ClubPartition> get clubPartitions {
    if (_clubPartitions is EqualUnmodifiableListView) return _clubPartitions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clubPartitions);
  }

  @override
  final ClubPartition? selectedClubPartition;
  @override
  @JsonKey()
  final dynamic isFirstLoad;
  @override
  @JsonKey()
  final dynamic isLoadingSessions;

  @override
  String toString() {
    return 'SessionManagerState(currentDate: $currentDate, sessions: $sessions, clubPartitions: $clubPartitions, selectedClubPartition: $selectedClubPartition, isFirstLoad: $isFirstLoad, isLoadingSessions: $isLoadingSessions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SessionManagerStateImpl &&
            (identical(other.currentDate, currentDate) ||
                other.currentDate == currentDate) &&
            const DeepCollectionEquality().equals(other._sessions, _sessions) &&
            const DeepCollectionEquality()
                .equals(other._clubPartitions, _clubPartitions) &&
            (identical(other.selectedClubPartition, selectedClubPartition) ||
                other.selectedClubPartition == selectedClubPartition) &&
            const DeepCollectionEquality()
                .equals(other.isFirstLoad, isFirstLoad) &&
            const DeepCollectionEquality()
                .equals(other.isLoadingSessions, isLoadingSessions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentDate,
      const DeepCollectionEquality().hash(_sessions),
      const DeepCollectionEquality().hash(_clubPartitions),
      selectedClubPartition,
      const DeepCollectionEquality().hash(isFirstLoad),
      const DeepCollectionEquality().hash(isLoadingSessions));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SessionManagerStateImplCopyWith<_$SessionManagerStateImpl> get copyWith =>
      __$$SessionManagerStateImplCopyWithImpl<_$SessionManagerStateImpl>(
          this, _$identity);
}

abstract class _SessionManagerState implements SessionManagerState {
  factory _SessionManagerState(
      {required final DateTime currentDate,
      required final List<Session> sessions,
      required final List<ClubPartition> clubPartitions,
      final ClubPartition? selectedClubPartition,
      final dynamic isFirstLoad,
      final dynamic isLoadingSessions}) = _$SessionManagerStateImpl;

  @override
  DateTime get currentDate;
  @override
  List<Session> get sessions;
  @override
  List<ClubPartition> get clubPartitions;
  @override
  ClubPartition? get selectedClubPartition;
  @override
  dynamic get isFirstLoad;
  @override
  dynamic get isLoadingSessions;
  @override
  @JsonKey(ignore: true)
  _$$SessionManagerStateImplCopyWith<_$SessionManagerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
