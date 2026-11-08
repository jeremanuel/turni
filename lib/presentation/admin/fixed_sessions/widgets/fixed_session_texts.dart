import 'package:intl/intl.dart';

import '../../../../core/presentation/components/loading/app_skeleton.dart';
import '../../../../domain/entities/fixed_session.dart';

class FixedSessionTexts {
  /// "mar 13/10" a partir de "2026-10-13".
  static String shortDate(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('EEE dd/MM', 'es').format(parsed);
  }

  static String occurrenceDetail(FixedSessionOccurrence o) {
    final who = o.clientName == null ? '' : ' (${o.clientName})';
    switch (o.status) {
      case FixedSessionOccurrenceStatus.created:
        return 'Libre: se crea el turno';
      case FixedSessionOccurrenceStatus.freeSession:
        return 'Ya hay un turno libre en ese horario: se usa ese';
      case FixedSessionOccurrenceStatus.booked:
        return 'Reservado por otro cliente$who: no se toca';
      case FixedSessionOccurrenceStatus.pending:
        return 'Tiene una solicitud pendiente: no se toca';
      case FixedSessionOccurrenceStatus.paid:
        return 'Tiene pagos: no se toca';
      case FixedSessionOccurrenceStatus.occupied:
        return 'Ocupado por otro turno: no se toca';
      case FixedSessionOccurrenceStatus.tournament:
        return 'Hay un partido de torneo$who: no se toca';
    }
  }

  /// "Los 8 martes están libres.", o cuáles ya están ocupados. [dayName] va
  /// en minúscula.
  static String previewSummary(List<FixedSessionOccurrence> preview, String dayName) {
    final days = dayName.endsWith('s') ? dayName : '${dayName}s';
    final free = preview.where((o) => !o.status.isConflict).length;
    final busy = preview.where((o) => o.status.isConflict).toList();
    if (busy.isEmpty) return 'Los $free $days están libres.';
    return '$free de ${preview.length} $days disponibles. '
        '${busy.map((o) => shortDate(o.date)).join(', ')} ya '
        '${busy.length == 1 ? 'está ocupado' : 'están ocupados'}: esos días no se tocan.';
  }

  /// "Vino 5 veces a este horario".
  static String playsLabel(int plays) => plays == 1 ? 'Vino una vez a este horario' : 'Vino $plays veces a este horario';

  /// "Ocupado (Ana López)".
  static String conflictLabel(FixedSessionOccurrence o) {
    switch (o.status) {
      case FixedSessionOccurrenceStatus.booked:
        return o.clientName == null ? 'Reservado' : 'Reservado por ${o.clientName}';
      case FixedSessionOccurrenceStatus.pending:
        return 'Solicitud pendiente';
      case FixedSessionOccurrenceStatus.paid:
        return 'Con pagos';
      case FixedSessionOccurrenceStatus.tournament:
        return o.clientName == null ? 'Partido de torneo' : 'Torneo: ${o.clientName}';
      default:
        return 'Ocupado';
    }
  }
}

/// Turnos fijos de mentira con la forma de los reales, para el esqueleto
/// mientras cargan. [clientId] es el titular (en la ficha, el cliente).
List<FixedSession> placeholderFixedSessions(int count, {int clientId = -1}) {
  final now = DateTime.now();
  FixedSessionPerson person(int id) => FixedSessionPerson(clientId: id, name: skeletonText(1), lastName: skeletonText(1));
  return [
    for (var i = 0; i < count; i++)
      FixedSession(
        id: -1 - i,
        client: person(clientId),
        participants: [person(-1)],
        partitionPhysicalId: -1,
        courtName: skeletonText(1),
        clubPartitionId: -1,
        sport: skeletonText(1),
        dayOfWeek: fixedSessionWeekOrder[i % fixedSessionWeekOrder.length],
        startTime: '00:00',
        duration: 60,
        startDate: '',
        upcoming: [for (var w = 0; w < 4; w++) FixedSessionUpcoming(sessionId: -1, startTime: now.add(Duration(days: 7 * w)))],
      ),
  ];
}
