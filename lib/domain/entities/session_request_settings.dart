/// Reglas de las solicitudes del club (`/admin/settings`).
class SessionRequestSettings {
  const SessionRequestSettings({required this.ttlMinutes, this.fixedRequestMinPlays});

  /// Minutos que una solicitud de turno espera antes de expirar.
  final int ttlMinutes;

  /// Veces que un cliente tiene que haber venido al mismo turno para poder
  /// pedirlo como fijo. `null`: el club no ofrece los pedidos.
  final int? fixedRequestMinPlays;

  factory SessionRequestSettings.fromJson(Map<String, dynamic> json) => SessionRequestSettings(
        ttlMinutes: (json['pending_request_ttl_minutes'] as num).toInt(),
        fixedRequestMinPlays: (json['fixed_session_request_min_plays'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'pending_request_ttl_minutes': ttlMinutes,
        'fixed_session_request_min_plays': fixedRequestMinPlays,
      };
}
