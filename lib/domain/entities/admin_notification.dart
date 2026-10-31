/// Un aviso de la bandeja del admin (`GET /notifications?app=admin`): lo
/// mismo que llegó (o habría llegado) por push, guardado en el backend. Solo
/// los de su club (ver `turni_mono_be/docs/feature/NOTIFICATIONS.md`).
class AdminNotification {
  /// Id del aviso. Es un BigInt en el backend: viaja como string.
  final String id;

  /// Tipo del catálogo del backend (`SESSION_REQUESTED`, `SESSION_DEPOSIT_PAID`...).
  final String type;

  /// `SESSION`, `PAYMENT`, `TOURNAMENT` o `GYM`.
  final String category;
  final String title;
  final String body;

  /// Los ids de lo que cambió, como en el `data` del push.
  final Map<String, String> data;
  final DateTime? readAt;
  final DateTime createdAt;

  /// El turno, el cliente, el partido y el estado de la solicitud, con el
  /// estado actual. Null en avisos de pushes que todavía no se recargaron.
  final AdminNotificationContext? context;

  const AdminNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.data,
    required this.readAt,
    required this.createdAt,
    this.context,
  });

  bool get isRead => readAt != null;

  NotificationKind get kind => switch (type) {
    'SESSION_REQUESTED' => NotificationKind.request,
    'SESSION_DEPOSIT_PAID' => NotificationKind.deposit,
    _ when category == 'PAYMENT' => NotificationKind.deposit,
    _ when category == 'TOURNAMENT' => NotificationKind.tournament,
    _ when category == 'GYM' => NotificationKind.gym,
    _ => NotificationKind.other,
  };

  /// Una solicitud que todavía se puede aceptar o rechazar.
  bool get isPendingRequest => kind == NotificationKind.request && context?.request?.state == SessionRequestState.pending;

  bool get isDispute => type == 'TOURNAMENT_RESULT_DISPUTED';

  /// Lo que espera una respuesta del admin (filtro "Para resolver").
  bool get needsAction => isPendingRequest || (isDispute && !isRead);

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final context = json['context'];
    return AdminNotification(
      id: '${json['notification_id']}',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: data is Map ? data.map((key, value) => MapEntry('$key', '$value')) : const {},
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String).toLocal() : null,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      context: context is Map<String, dynamic> ? AdminNotificationContext.fromJson(context) : null,
    );
  }

  AdminNotification copyWith({DateTime? readAt, AdminNotificationContext? context}) => AdminNotification(
    id: id,
    type: type,
    category: category,
    title: title,
    body: body,
    data: data,
    readAt: readAt ?? this.readAt,
    createdAt: createdAt,
    context: context ?? this.context,
  );

  AdminNotification markedRead(DateTime at) => copyWith(readAt: readAt ?? at);
}

/// Cómo se muestra un aviso: color e ícono de su cuadrado y qué acciones tiene.
enum NotificationKind { request, deposit, tournament, gym, other }

/// Estado de una solicitud de turno (ver `AdminNotificationContext.ts` en el back).
enum SessionRequestState {
  pending,
  accepted,
  rejected,
  expired,
  cancelled,
  closed;

  static SessionRequestState fromApi(String? value) => switch (value) {
    'PENDING' => pending,
    'ACCEPTED' => accepted,
    'REJECTED' => rejected,
    'EXPIRED' => expired,
    'CANCELLED' => cancelled,
    _ => closed,
  };
}

class AdminNotificationContext {
  final ({int clientId, String name})? client;
  final ({int sessionId, String space, bool feminine, DateTime? startTime, int? duration})? session;
  final num? amount;
  final ({SessionRequestState state, String? resolvedBy, bool resolvedByMe})? request;
  final ({int tournamentId, String name, int? matchId, String? matchLabel, String? teamA, String? teamB})? tournament;

  const AdminNotificationContext({this.client, this.session, this.amount, this.request, this.tournament});

  factory AdminNotificationContext.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    final session = json['session'];
    final request = json['request'];
    final tournament = json['tournament'];
    return AdminNotificationContext(
      client: client is Map ? (clientId: (client['client_id'] as num).toInt(), name: '${client['name'] ?? ''}') : null,
      session: session is Map
          ? (
              sessionId: (session['session_id'] as num).toInt(),
              space: '${session['space'] ?? ''}',
              feminine: session['space_gender'] != 'm',
              startTime: session['start_time'] != null ? DateTime.parse(session['start_time'] as String).toLocal() : null,
              duration: (session['duration'] as num?)?.toInt(),
            )
          : null,
      amount: json['amount'] as num?,
      request: request is Map
          ? (
              state: SessionRequestState.fromApi(request['state'] as String?),
              resolvedBy: request['resolved_by'] as String?,
              resolvedByMe: request['resolved_by_me'] == true,
            )
          : null,
      tournament: tournament is Map
          ? (
              tournamentId: (tournament['tournament_id'] as num).toInt(),
              name: '${tournament['name'] ?? ''}',
              matchId: (tournament['match_id'] as num?)?.toInt(),
              matchLabel: tournament['match_label'] as String?,
              teamA: tournament['team_a'] as String?,
              teamB: tournament['team_b'] as String?,
            )
          : null,
    );
  }

  /// La solicitud quedó respondida por el admin que mira (aceptar/rechazar desde la bandeja).
  AdminNotificationContext resolvedByMe(SessionRequestState state) => AdminNotificationContext(
    client: client,
    session: session,
    amount: amount,
    request: (state: state, resolvedBy: request?.resolvedBy, resolvedByMe: true),
    tournament: tournament,
  );
}

/// Una página de la bandeja. [nextCursor] es null en la última.
class AdminNotificationPage {
  final List<AdminNotification> notifications;
  final String? nextCursor;

  const AdminNotificationPage({required this.notifications, this.nextCursor});

  factory AdminNotificationPage.fromJson(Map<String, dynamic> json) => AdminNotificationPage(
    notifications: (json['notifications'] as List? ?? const []).map((item) => AdminNotification.fromJson(item as Map<String, dynamic>)).toList(),
    nextCursor: json['next_cursor'] as String?,
  );
}
