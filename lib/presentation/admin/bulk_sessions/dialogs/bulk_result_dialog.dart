import 'package:flutter/material.dart';

import '../../../../domain/entities/bulk_sessions.dart';
import '../../club_config/widgets/admin_data_table.dart';
import '../widgets/bulk_widgets.dart';

/// Qué hacer después de cerrar el resultado.
enum BulkResultNext { newOperation, goToManager, showExcluded }

/// "Cambios aplicados" / "Turnos eliminados": cuántos se tocaron, cuántos no
/// y por qué. Devuelve el siguiente paso elegido.
class BulkResultDialog extends StatelessWidget {
  const BulkResultDialog({
    super.key,
    required this.isDelete,
    required this.summary,
    required this.result,
  });

  final bool isDelete;
  final String summary;
  final BulkApplyResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final excluded = result.excluded;
    final reasons = [
      if (excluded.booked > 0) ('Reservados por un cliente', excluded.booked),
      if (excluded.pending > 0) ('Solicitud pendiente de aprobación', excluded.pending),
      if (excluded.paid > 0) ('Con pagos registrados', excluded.paid),
      if (excluded.overlap > 0) ('Se superponen con otro turno', excluded.overlap),
      if (excluded.unchanged > 0) ('Ya tenían ese valor', excluded.unchanged),
    ];

    Widget metric(String label, int value, Color valueColor) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('$value', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w500, color: valueColor)),
              ],
            ),
          ),
        );

    final buttonStyle = (ButtonStyle style) => style.copyWith(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
          textStyle: WidgetStatePropertyAll(bulkButtonTextStyle(context)),
        );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.check, size: 22, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelete ? 'Turnos eliminados' : 'Cambios aplicados',
                          style: const TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(height: 4),
                        Text(summary, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(children: [
                metric(isDelete ? 'Eliminados' : 'Modificados', result.affected, scheme.primary),
                const SizedBox(width: 12),
                metric('Sin cambios', excluded.total, scheme.onSurface),
              ]),
              if (reasons.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Por qué quedaron afuera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                AdminDataTable(
                  cellFontSize: 14,
                  columnWidths: const {0: FlexColumnWidth(), 1: FixedColumnWidth(100)},
                  columns: const ['Motivo', 'Turnos'],
                  rows: [
                    for (final (reason, count) in reasons) [Text(reason), Text('$count')],
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(BulkResultNext.showExcluded),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: EdgeInsets.zero,
                      textStyle: bulkButtonTextStyle(context),
                    ),
                    child: Text('Ver el detalle de los ${excluded.total} turnos'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(BulkResultNext.newOperation),
                    style: buttonStyle(OutlinedButton.styleFrom(foregroundColor: scheme.primary)),
                    child: const Text('Nueva operación'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(BulkResultNext.goToManager),
                    style: buttonStyle(FilledButton.styleFrom()),
                    child: const Text('Ir al gestor de turnos'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
