import 'package:intl/intl.dart';

import '../../../core/utils/physical_partition_naming.dart';
import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/bulk_sessions.dart';
import '../../../domain/entities/club_partition.dart';
import '../../../domain/entities/physical_partition.dart';
import 'cubit/bulk_edit_cubit.dart';

/// Textos derivados del estado de Gestión masiva (resúmenes, celdas de la
/// vista previa, barra inferior), juntos para que pantalla y diálogos digan
/// exactamente lo mismo.
class BulkEditTexts {
  BulkEditTexts({required this.state, required this.clubPartitions});

  final BulkEditState state;
  final List<ClubPartition> clubPartitions;

  static const dayLetters = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  static const dayNames = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
  static const _dayShort = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  static String price(double value) => '\$${ThousandsFormat.formatPrice(value)}';

  static String hm(DateTime value) => DateFormat('HH:mm').format(value);

  late final Map<int, (ClubPartition, PhysicalPartition)> _courtsById = {
    for (final partition in clubPartitions)
      for (final court in partition.physicalPartitions ?? const <PhysicalPartition>[])
        court.partitionPhysicalId: (partition, court),
  };

  /// "Pádel · Cancha 1".
  String courtLabel(int partitionPhysicalId) {
    final match = _courtsById[partitionPhysicalId];
    if (match == null) return 'Cancha sin identificador';
    final (partition, court) = match;
    return courtChipLabel(partition, court, withModality: true);
  }

  String courtChipLabel(ClubPartition partition, PhysicalPartition court, {required bool withModality}) {
    final unit = PhysicalPartitionNaming.labelFromPhysicalPartition(court, fallbackClubPartition: partition);
    final modality = partition.clubType?.name;
    if (!withModality || modality == null || modality.isEmpty) return unit;
    return '$modality · $unit';
  }

  /// "Lun 05/10".
  String rowDate(BulkPreviewRow row) =>
      '${_dayShort[row.startTime.weekday - 1]} ${DateFormat('dd/MM').format(row.startTime)}';

  /// "18:00 – 19:00".
  String rowHours(DateTime start, int duration) =>
      '${hm(start)} – ${hm(start.add(Duration(minutes: duration)))}';

  String get valueColumn {
    switch (state.actionKind) {
      case BulkActionKind.duration:
        return 'Duración';
      case BulkActionKind.shift:
        return 'Horario';
      case BulkActionKind.price:
      case BulkActionKind.delete:
        return 'Precio';
    }
  }

  /// Valor actual y nuevo de la columna de la acción (nuevo null = sin cambio).
  (String, String?) valueChange(BulkPreviewRow row) {
    switch (state.actionKind) {
      case BulkActionKind.price:
        return (price(row.price), row.newPrice == null ? null : price(row.newPrice!));
      case BulkActionKind.duration:
        return ('${row.duration} min', row.newDuration == null ? null : '${row.newDuration} min');
      case BulkActionKind.shift:
        return (
          rowHours(row.startTime, row.duration),
          row.newStartTime == null ? null : rowHours(row.newStartTime!, row.newDuration ?? row.duration),
        );
      case BulkActionKind.delete:
        return (price(row.price), null);
    }
  }

  static String excludedLabel(BulkRowResult result) {
    switch (result) {
      case BulkRowResult.booked:
        return 'Reservado · excluido';
      case BulkRowResult.pending:
        return 'Solicitud pendiente · excluido';
      case BulkRowResult.paid:
        return 'Con pagos · excluido';
      case BulkRowResult.overlap:
        return 'Se superpone · excluido';
      case BulkRowResult.unchanged:
        return 'Sin cambios';
      case BulkRowResult.ok:
        return '';
    }
  }

  /// Qué falta para poder calcular la vista previa (null = nada).
  String? get missingRequirement {
    if (state.physicalIds.isEmpty) return 'Elegí al menos una cancha para ver qué turnos se alcanzan.';
    if (state.daysOfWeek.isEmpty) return 'Elegí al menos un día de la semana.';
    if (state.to.isBefore(state.from)) return 'La fecha "Hasta" no puede ser anterior a "Desde".';
    switch (state.action.type) {
      case BulkActionType.priceFixed:
        return state.action.isComplete ? null : 'Completá el precio nuevo para ver la vista previa.';
      case BulkActionType.priceAdjust:
        return state.action.isComplete ? null : 'Completá el porcentaje de ajuste para ver la vista previa.';
      case BulkActionType.duration:
        return state.action.isComplete ? null : 'Completá la duración nueva para ver la vista previa.';
      case BulkActionType.shift:
        return state.action.isComplete ? null : 'Completá cuántos minutos mover el inicio.';
      case BulkActionType.priceTariff:
      case BulkActionType.delete:
        return null;
    }
  }

  String get footer {
    final preview = state.preview;
    if (!state.canPreview || preview == null) {
      return 'Definí las reglas y la acción para ver cuántos turnos se alcanzan.';
    }
    final kept = preview.matched - preview.affected;
    return state.actionKind == BulkActionKind.delete
        ? 'Se van a eliminar ${preview.affected} turnos libres. $kept quedan como están.'
        : 'Se van a modificar ${preview.affected} turnos. $kept quedan como están.';
  }

  // ---- Resúmenes (diálogos) ----

  /// "05/10/2026 – 03/11/2026".
  String get period {
    final format = DateFormat('dd/MM/yyyy');
    return '${format.format(state.from)} – ${format.format(state.to)}';
  }

  /// "Lunes a viernes", "Todos los días", "Lunes, miércoles y viernes".
  String get days {
    final sorted = state.daysOfWeek.toList()..sort();
    if (sorted.length == 7) return 'Todos los días';
    final consecutive = sorted.length >= 3 &&
        List.generate(sorted.length - 1, (i) => sorted[i + 1] - sorted[i]).every((d) => d == 1);
    String cap(String s) => s[0].toUpperCase() + s.substring(1);
    if (consecutive) return '${cap(dayNames[sorted.first - 1])} a ${dayNames[sorted.last - 1]}';
    final names = sorted.map((d) => dayNames[d - 1]).toList();
    if (names.length == 1) return cap(names.single);
    return cap('${names.sublist(0, names.length - 1).join(', ')} y ${names.last}');
  }

  /// "Inicio entre 18:00 y 23:00".
  String get hours => 'Inicio entre ${state.startFrom} y ${state.startTo}';

  /// "Pádel · Canchas 1, 2 y 3".
  String get courts {
    final byPartition = <ClubPartition, List<PhysicalPartition>>{};
    for (final id in state.physicalIds) {
      final match = _courtsById[id];
      if (match != null) byPartition.putIfAbsent(match.$1, () => []).add(match.$2);
    }
    return byPartition.entries.map((entry) {
      final courts = entry.value..sort((a, b) => (a.physicalIdentifier ?? 0).compareTo(b.physicalIdentifier ?? 0));
      final labels = courts
          .map((c) => PhysicalPartitionNaming.labelFromPhysicalPartition(c, fallbackClubPartition: entry.key))
          .toList();
      final list = labels.length == 1
          ? labels.single
          : '${labels.sublist(0, labels.length - 1).join(', ')} y ${labels.last}';
      final modality = entry.key.clubType?.name;
      return modality == null ? list : '$modality · $list';
    }).join(' / ');
  }

  /// Línea de la acción para el diálogo de resultado:
  /// "Precio fijo $12.000 · 05/10 – 03/11 · Pádel · Cancha 1, Cancha 2 y Cancha 3".
  String get resultSummary {
    final action = state.action;
    final String what;
    switch (action.type) {
      case BulkActionType.priceFixed:
        what = 'Precio fijo ${price(action.price ?? 0)}';
      case BulkActionType.priceTariff:
        what = 'Precio recalculado por tarifa';
      case BulkActionType.priceAdjust:
        final pct = action.percent ?? 0;
        what = 'Ajuste de precio ${pct > 0 ? '+' : ''}${ThousandsFormat.formatPrice(pct)} %';
      case BulkActionType.duration:
        what = 'Duración ${action.duration} min';
      case BulkActionType.shift:
        final m = action.shiftMinutes ?? 0;
        what = 'Inicio corrido ${m > 0 ? '+' : ''}$m min';
      case BulkActionType.delete:
        what = 'Eliminación';
    }
    final short = DateFormat('dd/MM');
    return '$what · ${short.format(state.from)} – ${short.format(state.to)} · $courts';
  }
}
