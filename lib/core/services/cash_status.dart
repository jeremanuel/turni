import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/cash/cash.dart';
import '../../domain/repositories/cash_repository.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../config/service_locator.dart';
import '../utils/either.dart';
import '../utils/permissions.dart';
import 'data_changes.dart';

/// Si el establecimiento usa caja. Decide si se muestran el menú Caja, la
/// columna de Pagos y la fila "Entra en" al cobrar. Se carga una vez por
/// sesión y se refresca cuando cambia la configuración o las cajas.
class CashStatus {
  CashStatus._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static int? _adminId;
  static StreamSubscription<DataChange>? _changes;

  /// Idempotente: solo carga cuando cambia quién está logueado.
  static void ensureStarted() {
    final adminId = sl<AuthCubit>().state.userCredential?.admin?.adminId;
    if (adminId == _adminId) return;
    _adminId = adminId;
    _changes?.cancel();
    _changes = null;
    enabled.value = false;
    if (adminId == null) return;
    _changes = DataChanges.stream.listen((change) {
      if (change.topics.contains(DataTopic.cash) || change.topics.contains(DataTopic.clubConfig)) refresh();
    });
    refresh();
  }

  static Future<void> refresh() async {
    final repository = sl<CashRepository>();
    if (Permissions.canAny(const [Permissions.CAJA_VER, Permissions.CONFIGURACION_CAJAS])) {
      if (await repository.getSettings() case Right(:final value)) enabled.value = value.enabled;
    } else if (Permissions.canAny(const [Permissions.AGENDA_COBRAR, Permissions.PAGOS_REGISTRAR, Permissions.TORNEOS_EDITAR])) {
      // Quien solo cobra no lee la configuración, pero sí a qué puesto entra el efectivo.
      if (await repository.resolveAccount() case Right(:final value)) enabled.value = value.enabled;
    }
  }

  /// Con caja, anular un cobro es de quien supervisa.
  static bool get canVoidPayment => Permissions.can(enabled.value ? Permissions.CAJA_SUPERVISAR : Permissions.PAGOS_REGISTRAR);

  /// Después de guardar la configuración, sin esperar el aviso del servidor.
  static void apply(CashSettings settings) => enabled.value = settings.enabled;
}
