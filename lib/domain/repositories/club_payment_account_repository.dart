import '../../core/utils/repository_response.dart';
import '../entities/payment/club_payment_account_status.dart';

/// Vínculo de la cuenta de Mercado Pago del club del admin autenticado
/// (modelo marketplace: los turnos pagados online se acreditan en la cuenta
/// del club). Ver `turni_mono_be/docs/feature/MERCADOPAGO_CLUB_OAUTH.md`.
abstract class ClubPaymentAccountRepository {
  Future<RepositoryResponse<ClubPaymentAccountStatus>> getMercadoPagoStatus();

  /// URL de autorización de Mercado Pago a la que hay que mandar al admin.
  /// Vence a los 10 minutos.
  Future<RepositoryResponse<String>> startMercadoPagoLink();

  Future<RepositoryResponse<void>> unlinkMercadoPago();
}
