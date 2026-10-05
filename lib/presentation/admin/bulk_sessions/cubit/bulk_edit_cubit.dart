import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/either.dart';
import '../../../../domain/entities/bulk_sessions.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/repositories/bulk_session_repository.dart';

enum BulkPeriodPreset { thisWeek, next30, custom }

/// Acción elegida en "2. ¿Qué hacer con ellos?".
enum BulkActionKind { price, duration, shift, delete }

/// Modo de "Cambiar precio".
enum BulkPriceMode { fixed, tariff, adjust }

class BulkEditState {
  const BulkEditState({
    required this.preset,
    required this.from,
    required this.to,
    this.daysOfWeek = const {1, 2, 3, 4, 5, 6, 7},
    this.startFrom = '00:00',
    this.startTo = '23:59',
    this.clubPartitionIds = const {},
    this.physicalIds = const {},
    this.actionKind = BulkActionKind.price,
    this.priceMode = BulkPriceMode.fixed,
    this.fixedPrice,
    this.percent,
    this.roundTo,
    this.duration,
    this.shiftMinutes,
    this.preview,
    this.isLoadingPreview = false,
    this.previewError,
    this.view = BulkPreviewView.all,
    this.isApplying = false,
  });

  final BulkPeriodPreset preset;
  final DateTime from;
  final DateTime to;
  final Set<int> daysOfWeek;
  final String startFrom;
  final String startTo;
  final Set<int> clubPartitionIds;
  final Set<int> physicalIds;

  final BulkActionKind actionKind;
  final BulkPriceMode priceMode;
  final double? fixedPrice;
  final double? percent;
  final double? roundTo;
  final int? duration;
  final int? shiftMinutes;

  /// Última vista previa recibida (se mantiene mientras carga la próxima).
  final BulkPreview? preview;
  final bool isLoadingPreview;
  final String? previewError;
  final BulkPreviewView view;
  final bool isApplying;

  BulkSessionFilters get filters => BulkSessionFilters(
        from: from,
        to: to,
        daysOfWeek: daysOfWeek,
        startFrom: startFrom,
        startTo: startTo,
        partitionPhysicalIds: physicalIds,
      );

  BulkSessionAction get action {
    switch (actionKind) {
      case BulkActionKind.price:
        switch (priceMode) {
          case BulkPriceMode.fixed:
            return BulkSessionAction(type: BulkActionType.priceFixed, price: fixedPrice);
          case BulkPriceMode.tariff:
            return const BulkSessionAction(type: BulkActionType.priceTariff);
          case BulkPriceMode.adjust:
            return BulkSessionAction(type: BulkActionType.priceAdjust, percent: percent, roundTo: roundTo);
        }
      case BulkActionKind.duration:
        return BulkSessionAction(type: BulkActionType.duration, duration: duration);
      case BulkActionKind.shift:
        return BulkSessionAction(type: BulkActionType.shift, shiftMinutes: shiftMinutes);
      case BulkActionKind.delete:
        return const BulkSessionAction(type: BulkActionType.delete);
    }
  }

  bool get canPreview => filters.isComplete && action.isComplete;

  bool get canApply =>
      canPreview && !isLoadingPreview && !isApplying && (preview?.affected ?? 0) > 0;

  BulkEditState copyWith({
    BulkPeriodPreset? preset,
    DateTime? from,
    DateTime? to,
    Set<int>? daysOfWeek,
    String? startFrom,
    String? startTo,
    Set<int>? clubPartitionIds,
    Set<int>? physicalIds,
    BulkActionKind? actionKind,
    BulkPriceMode? priceMode,
    double? Function()? fixedPrice,
    double? Function()? percent,
    double? Function()? roundTo,
    int? Function()? duration,
    int? Function()? shiftMinutes,
    BulkPreview? Function()? preview,
    bool? isLoadingPreview,
    String? Function()? previewError,
    BulkPreviewView? view,
    bool? isApplying,
  }) {
    return BulkEditState(
      preset: preset ?? this.preset,
      from: from ?? this.from,
      to: to ?? this.to,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startFrom: startFrom ?? this.startFrom,
      startTo: startTo ?? this.startTo,
      clubPartitionIds: clubPartitionIds ?? this.clubPartitionIds,
      physicalIds: physicalIds ?? this.physicalIds,
      actionKind: actionKind ?? this.actionKind,
      priceMode: priceMode ?? this.priceMode,
      fixedPrice: fixedPrice != null ? fixedPrice() : this.fixedPrice,
      percent: percent != null ? percent() : this.percent,
      roundTo: roundTo != null ? roundTo() : this.roundTo,
      duration: duration != null ? duration() : this.duration,
      shiftMinutes: shiftMinutes != null ? shiftMinutes() : this.shiftMinutes,
      preview: preview != null ? preview() : this.preview,
      isLoadingPreview: isLoadingPreview ?? this.isLoadingPreview,
      previewError: previewError != null ? previewError() : this.previewError,
      view: view ?? this.view,
      isApplying: isApplying ?? this.isApplying,
    );
  }
}

class BulkEditCubit extends Cubit<BulkEditState> {
  BulkEditCubit(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now,
        super(_initial((now ?? DateTime.now)()));

  final BulkSessionRepository _repository;
  final DateTime Function() _now;
  Timer? _debounce;
  int _requestId = 0;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static BulkEditState _initial(DateTime now) {
    final today = _day(now);
    return BulkEditState(
      preset: BulkPeriodPreset.next30,
      from: today,
      to: today.add(const Duration(days: 29)),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }

  /// Selección inicial: la primera modalidad activa con todas sus canchas
  /// activas. Solo si todavía no hay nada elegido.
  void initPartitions(List<ClubPartition> clubPartitions) {
    if (state.clubPartitionIds.isNotEmpty) return;
    final first = clubPartitions.where((p) => p.active && p.club_partition_id != null).firstOrNull;
    if (first == null) return;
    emit(state.copyWith(
      clubPartitionIds: {first.club_partition_id!},
      physicalIds: _activeCourts(first).map((p) => p.partitionPhysicalId).toSet(),
    ));
    _schedulePreview();
  }

  static Iterable<PhysicalPartition> _activeCourts(ClubPartition partition) =>
      (partition.physicalPartitions ?? const <PhysicalPartition>[]).where((p) => p.active);

  // ---- 1. ¿Qué turnos? ----

  void setPreset(BulkPeriodPreset preset) {
    final today = _day(_now());
    switch (preset) {
      case BulkPeriodPreset.thisWeek:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        _update(state.copyWith(preset: preset, from: today, to: monday.add(const Duration(days: 6))));
      case BulkPeriodPreset.next30:
        _update(state.copyWith(preset: preset, from: today, to: today.add(const Duration(days: 29))));
      case BulkPeriodPreset.custom:
        emit(state.copyWith(preset: preset));
    }
  }

  void setRange(DateTime from, DateTime to) {
    _update(state.copyWith(preset: BulkPeriodPreset.custom, from: _day(from), to: _day(to)));
  }

  void toggleDay(int day) {
    final days = {...state.daysOfWeek};
    days.contains(day) ? days.remove(day) : days.add(day);
    _update(state.copyWith(daysOfWeek: days));
  }

  void setStartFrom(String value) => _update(state.copyWith(startFrom: value));

  void setStartTo(String value) => _update(state.copyWith(startTo: value));

  void toggleClubPartition(ClubPartition partition) {
    final id = partition.club_partition_id;
    if (id == null || !partition.active) return;
    final ids = {...state.clubPartitionIds};
    final courts = {...state.physicalIds};
    final partitionCourts = (partition.physicalPartitions ?? const <PhysicalPartition>[])
        .map((p) => p.partitionPhysicalId);
    if (ids.remove(id)) {
      courts.removeAll(partitionCourts);
    } else {
      ids.add(id);
      courts.addAll(_activeCourts(partition).map((p) => p.partitionPhysicalId));
    }
    _update(state.copyWith(clubPartitionIds: ids, physicalIds: courts));
  }

  void toggleCourt(PhysicalPartition court) {
    if (!court.active) return;
    final courts = {...state.physicalIds};
    courts.contains(court.partitionPhysicalId)
        ? courts.remove(court.partitionPhysicalId)
        : courts.add(court.partitionPhysicalId);
    _update(state.copyWith(physicalIds: courts));
  }

  void selectAllCourts(List<PhysicalPartition> courts) {
    _update(state.copyWith(
      physicalIds: courts.where((c) => c.active).map((c) => c.partitionPhysicalId).toSet(),
    ));
  }

  // ---- 2. ¿Qué hacer con ellos? ----

  void setActionKind(BulkActionKind kind) => _update(state.copyWith(actionKind: kind));

  void setPriceMode(BulkPriceMode mode) => _update(state.copyWith(priceMode: mode));

  void setFixedPrice(double? value) => _update(state.copyWith(fixedPrice: () => value));

  void setPercent(double? value) => _update(state.copyWith(percent: () => value));

  void setRoundTo(double? value) => _update(state.copyWith(roundTo: () => value));

  void setDuration(int? value) => _update(state.copyWith(duration: () => value));

  void setShiftMinutes(int? value) => _update(state.copyWith(shiftMinutes: () => value));

  // ---- 3. Vista previa ----

  /// "Ver solo excluidos".
  void showExcluded() => _update(state.copyWith(view: BulkPreviewView.excluded), immediate: true);

  /// "Ver todos": todos los turnos que cumplen las reglas.
  void showAllRows() => _update(state.copyWith(view: BulkPreviewView.all), immediate: true);

  void refreshPreview() => _schedulePreview(immediate: true);

  void _update(BulkEditState next, {bool immediate = false}) {
    emit(next);
    _schedulePreview(immediate: immediate);
  }

  void _schedulePreview({bool immediate = false}) {
    _debounce?.cancel();
    if (!state.canPreview) {
      _requestId++;
      emit(state.copyWith(preview: () => null, isLoadingPreview: false, previewError: () => null));
      return;
    }
    emit(state.copyWith(isLoadingPreview: true));
    _debounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 400), _loadPreview);
  }

  Future<void> _loadPreview() async {
    final requestId = ++_requestId;
    final result = await _repository.preview(
      state.filters,
      state.action,
      // Sin límite: la tabla muestra todos los turnos, con scroll propio.
      view: state.view,
    );
    // Una respuesta vieja (las reglas cambiaron mientras viajaba) se descarta.
    if (isClosed || requestId != _requestId) return;

    switch (result) {
      case Right(:final value):
        emit(state.copyWith(preview: () => value, isLoadingPreview: false, previewError: () => null));
      case Left(:final failure):
        emit(state.copyWith(isLoadingPreview: false, previewError: () => failure.message));
    }
  }

  /// Aplica la operación. Devuelve el resultado, o null si falló (el error
  /// queda en [BulkEditState.previewError]).
  Future<BulkApplyResult?> apply() async {
    if (!state.canApply) return null;
    emit(state.copyWith(isApplying: true));
    final result = await _repository.apply(state.filters, state.action);
    if (isClosed) return null;

    switch (result) {
      case Right(:final value):
        emit(state.copyWith(isApplying: false));
        _schedulePreview(immediate: true);
        return value;
      case Left(:final failure):
        emit(state.copyWith(isApplying: false, previewError: () => failure.message));
        return null;
    }
  }
}
