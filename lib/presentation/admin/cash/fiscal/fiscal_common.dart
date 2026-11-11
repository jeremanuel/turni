import 'package:flutter/material.dart';

import '../../../../domain/entities/fiscal/fiscal.dart';
import '../cash_common.dart';

/// En camino a ARCA. "Verificando" (sin respuesta de ARCA) cuenta en "Para
/// resolver", igual que en el servidor.
const fiscalInProgressStatuses = ['PENDING', 'SENDING'];

/// Condiciones frente al IVA, por si quien cobra no puede leer la configuración.
const fiscalIvaConditions = [
  FiscalOption(5, 'Consumidor final'),
  FiscalOption(6, 'Monotributo'),
  FiscalOption(1, 'Responsable Inscripto'),
  FiscalOption(4, 'Exento'),
  FiscalOption(7, 'No categorizado'),
  FiscalOption(13, 'Monotributista social'),
  FiscalOption(15, 'No alcanzado'),
  FiscalOption(16, 'Monotributo trabajador independiente promovido'),
];

StatusTone fiscalStatusTone(ColorScheme scheme, String status) => switch (status) {
      'AUTHORIZED' => StatusTone.success(scheme),
      'PENDING' || 'SENDING' || 'UNKNOWN' => StatusTone.primary(scheme),
      'REJECTED' => StatusTone.danger(scheme),
      'NEEDS_DATA' || 'NEEDS_CONFIG' || 'BLOCKED' => StatusTone.warning(scheme),
      _ => StatusTone.neutral(scheme),
    };

/// Por qué está en ese estado, en una línea.
String? fiscalStatusReason(FiscalDocument doc) => switch (doc.status) {
      'DRAFT' => 'Emitilo cuando quieras desde acá',
      'PENDING' => 'Esperando su turno para ir a ARCA',
      'SENDING' => 'Enviándose a ARCA',
      'UNKNOWN' => 'ARCA no respondió. Confirmamos si salió antes de reintentar',
      'BLOCKED' => 'Sale cuando vuelva la conexión con ARCA',
      'NEEDS_DATA' || 'NEEDS_CONFIG' || 'REJECTED' => doc.errors.firstOrNull,
      'CANCELLED' => doc.cancelReason,
      'AUTHORIZED' when doc.observations.isNotEmpty => 'ARCA lo autorizó y dejó una observación',
      _ => null,
    };

/// "9 nov 2026".
String fiscalDate(DateTime date) => '${cashDay(date)} ${date.year}';

/// "Sin número todavía" mientras no salió.
String fiscalNumber(FiscalDocument doc) => doc.number ?? (doc.status == 'CANCELLED' ? 'Sin número' : 'Sin número todavía');

/// Monto con signo para las notas de crédito.
String fiscalAmount(FiscalDocument doc) => doc.isCreditNote ? '− ${cashMoney(doc.total)}' : cashMoney(doc.total);

/// Aviso de color (advertencia, error, información) dentro de una pantalla.
class FiscalNotice extends StatelessWidget {
  const FiscalNotice({super.key, required this.tone, this.title, required this.text, this.action});

  final StatusTone tone;
  final String? title;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title != null) Text(title!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tone.foreground)),
            Text(text, style: TextStyle(fontSize: 13, height: 18 / 13, color: tone.foreground)),
          ]),
        ),
        if (action != null) ...[const SizedBox(width: 12), action!],
      ]),
    );
  }
}
