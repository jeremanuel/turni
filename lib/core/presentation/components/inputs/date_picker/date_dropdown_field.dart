import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dropdown_widget.dart';

/// Campo de una fecha con el calendario propio, que se despliega debajo del
/// campo (el mismo `DropdownWidget` + `CalendarDatePicker2` del "Rango
/// personalizado"). Nunca usar `showDatePicker`: abre el calendario de
/// Material en un diálogo aparte, que no es el del diseño.
///
/// Se ve como los demás campos del formulario: borde `outline`, fondo
/// transparente, 48 de alto y el ícono de calendario a la derecha.
class DateDropdownField extends StatefulWidget {
  const DateDropdownField({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.format,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Cómo se muestra la fecha. Por defecto "Hoy, dom 1 nov" / "mié 21 oct".
  final String Function(DateTime)? format;

  @override
  State<DateDropdownField> createState() => _DateDropdownFieldState();
}

class _DateDropdownFieldState extends State<DateDropdownField> {
  final _dropdown = DropdownController();

  static String _defaultFormat(DateTime date) {
    final now = DateTime.now();
    final label = DateFormat('EEE d MMM', 'es').format(date).replaceAll('.', '');
    final today = date.year == now.year && date.month == now.month && date.day == now.day;
    return today ? 'Hoy, $label' : label;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DropdownWidget(
      dropdownController: _dropdown,
      obscureBackground: false,
      width: 320,
      menuWidget: SizedBox(
        width: 320,
        height: 340,
        child: CalendarDatePicker2(
          config: CalendarDatePicker2Config(
            calendarType: CalendarDatePicker2Type.single,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            currentDate: widget.value,
          ),
          value: [widget.value],
          onValueChanged: (dates) {
            final picked = dates.whereType<DateTime>().firstOrNull;
            if (picked != null) widget.onChanged(picked);
            _dropdown.hide?.call();
          },
        ),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: scheme.outline)),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _dropdown.toggle?.call(),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Expanded(
                  child: Text(
                    (widget.format ?? _defaultFormat)(widget.value),
                    style: TextStyle(fontSize: 15, color: scheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.calendar_today_outlined, size: 18, color: scheme.onSurfaceVariant),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
