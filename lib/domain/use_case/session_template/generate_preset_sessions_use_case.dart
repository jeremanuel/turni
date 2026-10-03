import 'package:flutter/material.dart';

import '../../../core/utils/types/time_interval.dart';
import '../../entities/session.dart';

/// Caso de uso para generar sesiones de plantilla dentro de un rango horario.
///
/// Feature: session_template
///
/// Reglas principales:
/// - Genera sesiones de duracion fija dentro del rango [start, end].
/// - Respeta las sesiones existentes, evitando solapamientos.
/// - Si hay sesiones existentes superpuestas o contiguas, las unifica para
///   calcular correctamente los huecos libres.
/// - Solo crea sesiones completas (no fracciona en el tramo final del hueco).
class GeneratePresetSessionsUseCase {
  /// Ejecuta la generacion de sesiones para el preset seleccionado.
  ///
  /// [start] y [end] delimitan el periodo a completar.
  /// [durationMinutes] define la duracion de cada sesion a crear.
  /// [existingSessions] son las sesiones actualmente en la plantilla.
  ///
  /// Retorna la lista de sesiones nuevas a agregar.
  List<Session> execute({
    required TimeOfDay start,
    required TimeOfDay end,
    required int durationMinutes,
    required List<Session> existingSessions,
  }) {
    final startInMinutes = start.hour * 60 + start.minute;
    final endInMinutes = end.hour * 60 + end.minute;

    if (durationMinutes <= 0 || startInMinutes >= endInMinutes) {
      return const [];
    }

    final occupiedIntervals = _buildOccupiedIntervals(
      existingSessions: existingSessions,
      rangeStart: startInMinutes,
      rangeEnd: endInMinutes,
    );

    final mergedOccupied = _mergeOccupiedIntervals(occupiedIntervals);

    final sessions = <Session>[];
    var freeStart = startInMinutes;

    for (final occupied in mergedOccupied) {
      if (freeStart < occupied.start) {
        _fillGap(
          sessions: sessions,
          gapStart: freeStart,
          gapEnd: occupied.start,
          durationMinutes: durationMinutes,
        );
      }

      if (occupied.end > freeStart) {
        freeStart = occupied.end;
      }
    }

    if (freeStart < endInMinutes) {
      _fillGap(
        sessions: sessions,
        gapStart: freeStart,
        gapEnd: endInMinutes,
        durationMinutes: durationMinutes,
      );
    }

    return sessions;
  }

  List<({int start, int end})> _buildOccupiedIntervals({
    required List<Session> existingSessions,
    required int rangeStart,
    required int rangeEnd,
  }) {
    return existingSessions
        .map((session) {
          final sessionStart =
              session.startTime.hour * 60 + session.startTime.minute;
          final sessionEnd = sessionStart + session.duration;

          final clampedStart =
              sessionStart < rangeStart ? rangeStart : sessionStart;
          final clampedEnd = sessionEnd > rangeEnd ? rangeEnd : sessionEnd;

          if (clampedStart >= clampedEnd) {
            return null;
          }

          return (start: clampedStart, end: clampedEnd);
        })
        .whereType<({int start, int end})>()
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  List<({int start, int end})> _mergeOccupiedIntervals(
    List<({int start, int end})> occupiedIntervals,
  ) {
    final merged = <({int start, int end})>[];

    for (final interval in occupiedIntervals) {
      if (merged.isEmpty) {
        merged.add(interval);
        continue;
      }

      final last = merged.last;
      if (interval.start <= last.end) {
        merged[merged.length - 1] = (
          start: last.start,
          end: interval.end > last.end ? interval.end : last.end,
        );
      } else {
        merged.add(interval);
      }
    }

    return merged;
  }

  void _fillGap({
    required List<Session> sessions,
    required int gapStart,
    required int gapEnd,
    required int durationMinutes,
  }) {
    var cursor = gapStart;

    while (cursor + durationMinutes <= gapEnd) {
      final startTime = TimeOfDay(
        hour: cursor ~/ 60,
        minute: cursor % 60,
      );

      sessions.add(
        Session.fromDates(
          DateTime.now().applied(startTime),
          TimeOfDay(
            hour: durationMinutes ~/ 60,
            minute: durationMinutes % 60,
          ),
        ),
      );

      cursor += durationMinutes;
    }
  }
}
