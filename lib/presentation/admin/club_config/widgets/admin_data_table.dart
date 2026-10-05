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
    this.columnWidths,
    this.defaultColumnWidth = const IntrinsicColumnWidth(),
    this.cellFontSize = 13.5,
    this.rowTextColors,
    this.maxBodyHeight,
  });

  /// Si viene, el encabezado queda fijo y las filas scrollean dentro de esa
  /// altura máxima (tablas largas, ej. la vista previa de gestión masiva).
  final double? maxBodyHeight;

  final List<String> columns;
  final List<List<Widget>> rows;

  /// Por defecto cada columna toma el ancho de su contenido; para una tabla
  /// que ocupa todo el ancho, pasar `FlexColumnWidth`s.
  final Map<int, TableColumnWidth>? columnWidths;
  final TableColumnWidth defaultColumnWidth;
  final double cellFontSize;

  /// Color de texto por fila (alineado con [rows]); null = `onSurface`. Ej.
  /// filas "apagadas" en la vista previa de gestión masiva.
  final List<Color?>? rowTextColors;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final headerStyle = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );

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

    final headerRow = TableRow(
      children: [
        for (final label in columns)
          cell(Text(label, style: headerStyle), isHeader: true),
      ],
    );
    final bodyRows = [
      for (var i = 0; i < rows.length; i++)
        TableRow(
          children: [
            for (final widget in rows[i])
              cell(DefaultTextStyle.merge(
                style: TextStyle(
                  fontSize: cellFontSize,
                  color: rowTextColors?[i] ?? colorScheme.onSurface,
                ),
                child: widget,
              )),
          ],
        ),
    ];

    Table table(List<TableRow> children, TableBorder border) => Table(
          border: border,
          columnWidths: columnWidths,
          defaultColumnWidth: defaultColumnWidth,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: children,
        );

    final side = BorderSide(color: colorScheme.outlineVariant, width: 1);
    final maxBodyHeight = this.maxBodyHeight;

    if (maxBodyHeight == null) {
      return table([headerRow, ...bodyRows], TableBorder.all(color: colorScheme.outlineVariant, width: 1));
    }

    // Encabezado fijo + cuerpo con scroll propio. Son dos `Table` con los
    // mismos anchos de columna; el cuerpo no repite la línea superior para
    // que la grilla se vea continua.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        table([headerRow], TableBorder.all(color: colorScheme.outlineVariant, width: 1)),
        if (bodyRows.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: _ScrollableBody(
              child: table(
                bodyRows,
                TableBorder(
                  left: side,
                  right: side,
                  bottom: side,
                  horizontalInside: side,
                  verticalInside: side,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScrollableBody extends StatefulWidget {
  const _ScrollableBody({required this.child});

  final Widget child;

  @override
  State<_ScrollableBody> createState() => _ScrollableBodyState();
}

class _ScrollableBodyState extends State<_ScrollableBody> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(controller: _controller, child: widget.child),
    );
  }
}
