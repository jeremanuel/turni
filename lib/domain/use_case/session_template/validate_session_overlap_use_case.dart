import '../../entities/session.dart';

/// Caso de uso para detectar si un turno nuevo se solapa con la plantilla actual.
///
/// Feature: session_template
class ValidateSessionOverlapUseCase {
  /// Devuelve `true` si [candidate] se solapa con cualquier turno de
  /// [existingSessions].
  bool execute({
    required Session candidate,
    required List<Session> existingSessions,
  }) {
    final candidateStart = candidate.startTime;
    final candidateEnd = candidate.endTime;

    for (final current in existingSessions) {
      final currentStart = current.startTime;
      final currentEnd = current.endTime;

      final overlaps =
          candidateStart.isBefore(currentEnd) && candidateEnd.isAfter(currentStart);

      if (overlaps) {
        return true;
      }
    }

    return false;
  }
}
