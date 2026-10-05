/// Estado de la cuenta de Mercado Pago vinculada al club del admin
/// (`GET /admin/payment-account/mercadopago`). El backend nunca devuelve los
/// tokens, solo este resumen.
enum ClubPaymentAccountState {
  /// Nunca se vinculó, o se desvinculó.
  notLinked,

  /// Vinculada: los turnos se cobran a la cuenta del club.
  active,

  /// La renovación del permiso falló: hay que volver a vincular.
  refreshFailed,
}

class ClubPaymentAccountStatus {
  final ClubPaymentAccountState state;

  /// Id del usuario de Mercado Pago vinculado.
  final String? providerUserId;

  /// `false` = credenciales de prueba (sandbox).
  final bool? liveMode;

  /// Vencimiento del permiso actual. El backend lo renueva solo antes de
  /// que venza; es informativo.
  final DateTime? expiresAt;

  const ClubPaymentAccountStatus({
    required this.state,
    this.providerUserId,
    this.liveMode,
    this.expiresAt,
  });

  const ClubPaymentAccountStatus.notLinked() : this(state: ClubPaymentAccountState.notLinked);

  factory ClubPaymentAccountStatus.fromJson(Map<String, dynamic> json) {
    final rawExpiresAt = json['expiresAt'] as String?;

    return ClubPaymentAccountStatus(
      state: _stateFrom(json['status'] as String?),
      providerUserId: json['providerUserId'] as String?,
      liveMode: json['liveMode'] as bool?,
      expiresAt: rawExpiresAt != null ? DateTime.tryParse(rawExpiresAt)?.toLocal() : null,
    );
  }

  static ClubPaymentAccountState _stateFrom(String? status) {
    switch (status) {
      case 'ACTIVE':
        return ClubPaymentAccountState.active;
      case 'REFRESH_FAILED':
        return ClubPaymentAccountState.refreshFailed;
      default:
        // null (nunca vinculada) o REVOKED (desvinculada).
        return ClubPaymentAccountState.notLinked;
    }
  }
}
