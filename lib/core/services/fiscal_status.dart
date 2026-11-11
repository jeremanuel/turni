import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/repositories/fiscal_repository.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';
import '../config/service_locator.dart';
import '../utils/either.dart';
import '../utils/permissions.dart';
import 'data_changes.dart';

/// Si el establecimiento factura con ARCA. Decide si se ve Caja › Comprobantes
/// (y el menú Caja aunque no use caja). Igual que [CashStatus]: se carga una
/// vez por sesión y se refresca cuando cambia la configuración o la caja.
class FiscalStatus {
  FiscalStatus._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static int? _adminId;
  static StreamSubscription<DataChange>? _changes;

  static bool get _canRead => Permissions.canAny(const [Permissions.FACTURACION_VER, Permissions.CONFIGURACION_FACTURACION]);

  /// Idempotente: solo carga cuando cambia quién está logueado.
  static void ensureStarted() {
    final adminId = sl<AuthCubit>().state.userCredential?.admin?.adminId;
    if (adminId == _adminId) return;
    _adminId = adminId;
    _changes?.cancel();
    _changes = null;
    enabled.value = false;
    if (adminId == null || !_canRead) return;
    _changes = DataChanges.stream.listen((change) {
      if (change.topics.contains(DataTopic.cash) || change.topics.contains(DataTopic.clubConfig)) refresh();
    });
    refresh();
  }

  static Future<void> refresh() async {
    if (!_canRead) return;
    if (await sl<FiscalRepository>().getSettings() case Right(:final value)) enabled.value = value.profile?.enabled ?? false;
  }

  /// Después de guardar la configuración, sin esperar el aviso del servidor.
  static void apply(bool value) => enabled.value = value;
}
