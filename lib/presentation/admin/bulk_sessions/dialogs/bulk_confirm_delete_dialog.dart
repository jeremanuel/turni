import 'package:flutter/material.dart';

import '../../../../domain/entities/bulk_sessions.dart';
import '../widgets/bulk_widgets.dart';

/// "¿Eliminar N turnos?": resumen de las reglas, cuántos quedan protegidos y
/// un checkbox explícito antes de habilitar el botón destructivo.
/// Devuelve `true` si el admin confirma.
class BulkConfirmDeleteDialog extends StatefulWidget {
  const BulkConfirmDeleteDialog({
    super.key,
    required this.count,
    required this.period,
    required this.days,
    required this.hours,
    required this.courts,
    required this.excluded,
  });

  final int count;
  final String period;
  final String days;
  final String hours;
  final String courts;
  final BulkExcluded excluded;

  @override
  State<BulkConfirmDeleteDialog> createState() => _BulkConfirmDeleteDialogState();
}

class _BulkConfirmDeleteDialogState extends State<BulkConfirmDeleteDialog> {
  bool _understood = false;

  String get _protectedDetail {
    final parts = <String>[
      if (widget.excluded.booked > 0) '${widget.excluded.booked} reservados',
      if (widget.excluded.pending > 0) '${widget.excluded.pending} con solicitud pendiente',
      if (widget.excluded.paid > 0) '${widget.excluded.paid} con pagos registrados',
      if (widget.excluded.overlap > 0) '${widget.excluded.overlap} superpuestos',
    ];
    if (parts.length <= 1) return parts.join();
    return '${parts.sublist(0, parts.length - 1).join(', ')} y ${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    TableRow row(String term, String value) => TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(term, style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ]);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.delete_outline, size: 24, color: scheme.error),
              const SizedBox(height: 12),
              Text(
                '¿Eliminar ${widget.count} turnos?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, height: 32 / 24, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 12),
              Text(
                'Se borran definitivamente. No se puede deshacer.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 20 / 14, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Table(
                  columnWidths: const {0: FixedColumnWidth(132), 1: FlexColumnWidth()},
                  children: [
                    row('Período', widget.period),
                    row('Días', widget.days),
                    row('Horario', widget.hours),
                    row('Canchas', widget.courts),
                  ],
                ),
              ),
              if (widget.excluded.total > 0) ...[
                const SizedBox(height: 16),
                BulkInfoBox(
                  icon: Icons.lock_outline,
                  background: scheme.surfaceContainerHighest,
                  foreground: scheme.onSurfaceVariant,
                  iconColor: scheme.primary,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(
                      text: '${widget.excluded.total} turnos no se tocan',
                      style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500),
                    ),
                    TextSpan(text: ': $_protectedDetail.'),
                  ])),
                ),
              ],
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _understood = !_understood),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _understood,
                        onChanged: (value) => setState(() => _understood = value ?? false),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Entiendo que los ${widget.count} turnos se borran y no se pueden recuperar',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      textStyle: bulkButtonTextStyle(context),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _understood ? () => Navigator.of(context).pop(true) : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      textStyle: bulkButtonTextStyle(context),
                    ),
                    child: Text('Eliminar ${widget.count} turnos'),
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
