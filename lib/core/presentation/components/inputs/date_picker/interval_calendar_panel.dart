import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../utils/types/time_interval.dart';

/// Calendario de rango (inicio – fin) con "Cancelar" / "Aplicar": el mismo
/// panel que abre el "Rango personalizado" del agregador de turnos
/// (`FilterChipIntervalDate`). Pensado para ir dentro de un `DropdownWidget`.
class IntervalCalendarPanel extends StatefulWidget {
  const IntervalCalendarPanel({
    super.key,
    required this.initialValue,
    required this.onApply,
    required this.onCancel,
  });

  final TimeInterval? initialValue;
  final ValueChanged<TimeInterval> onApply;
  final VoidCallback onCancel;

  @override
  State<IntervalCalendarPanel> createState() => _IntervalCalendarPanelState();
}

class _IntervalCalendarPanelState extends State<IntervalCalendarPanel> {
  late TimeInterval? interval = widget.initialValue;

  @override
  void didUpdateWidget(covariant IntervalCalendarPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue?.initialDate != widget.initialValue?.initialDate ||
        oldWidget.initialValue?.endDate != widget.initialValue?.endDate) {
      interval = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      width: 300,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            height: 60,
            child: Row(
              children: [
                Text(interval?.initialDate == null ? 'Inicio' : DateFormat.MMMd().format(interval!.initialDate!)),
                const Text(' - '),
                Text(interval?.endDate == null ? 'Fin' : DateFormat.MMMd().format(interval!.endDate!)),
              ],
            ),
          ),
          Expanded(
            child: CalendarDatePicker2(
              config: CalendarDatePicker2Config(calendarType: CalendarDatePicker2Type.range),
              value: interval?.toArray() ?? [],
              onValueChanged: (value) => setState(() => interval = TimeInterval.fromArray(value)),
            ),
          ),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => interval = widget.initialValue);
                    widget.onCancel();
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: interval == null || interval!.endDate == null && interval!.initialDate == null
                      ? null
                      : () => widget.onApply(interval!),
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
