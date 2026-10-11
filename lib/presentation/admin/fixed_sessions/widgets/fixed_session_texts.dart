import 'package:intl/intl.dart';

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
    }
  }

  /// "Ocupado (Ana López)".
  static String conflictLabel(FixedSessionOccurrence o) {
    switch (o.status) {
      case FixedSessionOccurrenceStatus.booked:
        return o.clientName == null ? 'Reservado' : 'Reservado por ${o.clientName}';
      case FixedSessionOccurrenceStatus.pending:
        return 'Solicitud pendiente';
      case FixedSessionOccurrenceStatus.paid:
        return 'Con pagos';
      default:
        return 'Ocupado';
    }
  }
}
