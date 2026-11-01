import 'package:intl/intl.dart';

import '../../../core/utils/thousands_format.dart';
import '../../../domain/entities/admin_notification.dart';

/// Los textos de un aviso en la bandeja y en el aviso flotante (diseño
/// "Bandeja de notificaciones"). Se arman con el contexto que manda el back;
/// si un aviso no lo trae (viejo o de otro tipo), se usa su título y cuerpo.

const _weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

DateTime _day(DateTime at) => DateTime(at.year, at.month, at.day);

String _capitalized(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// Título: "Solicitud de turno", "Seña acreditada", "Resultado en disputa"...
String notificationTitle(AdminNotification n) => switch (n.type) {
  'SESSION_REQUESTED' => 'Solicitud de turno',
  'SESSION_DEPOSIT_PAID' => 'Seña acreditada',
  'TOURNAMENT_RESULT_DISPUTED' => 'Resultado en disputa',
  _ => n.title,
};

/// El cuerpo en dos partes: quién (en negrita) y el resto.
/// "**Martina López** pidió la Cancha 2 para hoy a las 19:00."
({String who, String rest}) notificationSentence(AdminNotification n, DateTime now) {
  final context = n.context;
  final client = context?.client?.name;
  final session = context?.session;
  switch (n.type) {
    case 'SESSION_REQUESTED' when client != null && session != null:
      final article = session.feminine ? 'la' : 'el';
      final when = session.startTime;
      final whenText = when == null ? '' : ' para ${_requestDay(when, now)} a las ${DateFormat('HH:mm').format(when)}';
      return (who: client, rest: ' pidió $article ${session.space}$whenText.');
    case 'SESSION_DEPOSIT_PAID' when client != null:
      final confirmed = n.title.toLowerCase().contains('confirmado');
      return (who: client, rest: confirmed ? ' pagó la seña y el turno quedó confirmado.' : ' pagó la seña por Mercado Pago.');
    case 'TOURNAMENT_RESULT_DISPUTED':
      final t = context?.tournament;
      if (t?.teamA != null && t?.teamB != null) {
        return (who: '', rest: '${t!.teamA} y ${t.teamB} cargaron resultados distintos.');
      }
  }
  return (who: '', rest: n.body);
}

/// "hoy", "mañana", "el sábado" (en la semana), "el 27/10".
String _requestDay(DateTime at, DateTime now) {
  final days = _day(at).difference(_day(now)).inDays;
  if (days == 0) return 'hoy';
  if (days == 1) return 'mañana';
  if (days == -1) return 'ayer';
  if (days > 1 && days < 7) return 'el ${_weekdays[at.weekday - 1]}';
  return 'el ${DateFormat('dd/MM').format(at)}';
}

/// "Hoy 19:00", "Mañana 10:00", "Sáb 10:00" (en la semana), "Mar 27/10 18:00".
String _chipDay(DateTime at, DateTime now) {
  final days = _day(at).difference(_day(now)).inDays;
  final hhmm = DateFormat('HH:mm').format(at);
  if (days == 0) return 'Hoy $hhmm';
  if (days == 1) return 'Mañana $hhmm';
  if (days == -1) return 'Ayer $hhmm';
  final weekday = _capitalized(_weekdays[at.weekday - 1].substring(0, 3));
  if (days > 1 && days < 7) return '$weekday $hhmm';
  return '$weekday ${DateFormat('dd/MM').format(at)} $hhmm';
}

/// La etiqueta de contexto: "Cancha 2 · Hoy 19:00 · 90 min" o "Torneo Apertura · Cuartos de final".
String? notificationContextLabel(AdminNotification n, DateTime now) {
  final context = n.context;
  final session = context?.session;
  if (session != null) {
    return [
      session.space,
      if (session.startTime != null) _chipDay(session.startTime!, now),
      if (n.kind == NotificationKind.request && session.duration != null) '${session.duration} min',
    ].join(' · ');
  }
  final tournament = context?.tournament;
  if (tournament != null) {
    return [tournament.name, if (tournament.matchLabel != null) tournament.matchLabel!].join(' · ');
  }
  return null;
}

/// "$ 8.000" en las señas.
String? notificationAmountLabel(AdminNotification n) {
  final amount = n.context?.amount;
  return amount == null ? null : '\$ ${ThousandsFormat.formatPrice(amount)}';
}

/// Cómo terminó una solicitud: "Aceptada por Sol Paz", "Venció sin respuesta".
/// `ok`: se muestra con el check y en el color primario. Null si sigue pendiente.
({String text, bool ok})? notificationStatus(AdminNotification n) {
  final request = n.context?.request;
  if (n.kind != NotificationKind.request || request == null) return null;
  final by = request.resolvedByMe ? 'vos' : request.resolvedBy;
  return switch (request.state) {
    SessionRequestState.pending => null,
    SessionRequestState.accepted => (text: by != null ? 'Aceptada por $by' : 'Confirmada', ok: true),
    SessionRequestState.rejected => (text: by != null ? 'Rechazada por $by' : 'Rechazada', ok: false),
    SessionRequestState.expired => (text: 'Venció sin respuesta', ok: false),
    SessionRequestState.cancelled => (text: 'El cliente la canceló', ok: false),
    SessionRequestState.closed => (text: 'Ya no está pendiente', ok: false),
  };
}

/// El grupo de la bandeja: "Hoy", "Ayer" o "Antes".
String notificationGroup(DateTime at, DateTime now) {
  final days = _day(now).difference(_day(at)).inDays;
  if (days <= 0) return 'Hoy';
  if (days == 1) return 'Ayer';
  return 'Antes';
}
