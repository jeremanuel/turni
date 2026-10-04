import 'package:flutter/material.dart';

/// Tabla con grilla completa (header con fondo + bordes en cada celda),
/// igual al mockup de Ajustes. El `DataTable` nativo de Material solo
/// dibuja líneas horizontales entre filas, sin bordes verticales ni fondo
/// de header propio, así que no alcanza para el diseño aprobado.
class AdminDataTable extends StatelessWidget {
  const AdminDataTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<String> columns;
  final List<List<Widget>> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );
    final cellStyle = TextStyle(fontSize: 13.5, color: colorScheme.onSurface);

    Widget cell(Widget child, {bool isHeader = false}) {
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          color: isHeader ? colorScheme.surfaceContainerHighest : null,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: colorScheme.outlineVariant, width: 1),
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            for (final label in columns)
              cell(Text(label, style: headerStyle), isHeader: true),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (final widget in row)
                cell(DefaultTextStyle.merge(style: cellStyle, child: widget)),
            ],
          ),
      ],
    );
  }
}
