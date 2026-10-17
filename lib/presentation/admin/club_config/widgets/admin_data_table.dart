import 'package:flutter/material.dart';

import '../../../../core/utils/responsive_builder.dart';

/// Cómo se muestra una [AdminDataTable] en el celular.
enum AdminTableMobileLayout {
  /// Cada fila es una tarjeta: la primera columna como título y el resto como
  /// pares "columna: valor" (default).
  cards,

  /// Se mantiene la tabla, con scroll horizontal (tabla de posiciones,
  /// ranking: comparar filas es el punto de la tabla).
  scroll,
}

/// Tabla con grilla completa (header con fondo + bordes en cada celda),
/// igual al mockup de Ajustes. El `DataTable` nativo de Material solo
/// dibuja líneas horizontales entre filas, sin bordes verticales ni fondo
/// de header propio, así que no alcanza para el diseño aprobado.
///
/// En el celular se convierte según [mobileLayout] (diseño "Admin mobile").
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
    this.mobileLayout = AdminTableMobileLayout.cards,
  });

  final AdminTableMobileLayout mobileLayout;

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
    if (ResponsiveBuilder.isMobile(context)) {
      if (mobileLayout == AdminTableMobileLayout.cards) return _MobileCards(table: this);
      return LayoutBuilder(
        builder: (context, constraints) {
          final table = _buildTable(context);
          // Dentro de un scroll horizontal ya no hace falta otro.
          if (!constraints.hasBoundedWidth) return table;
          return SingleChildScrollView(scrollDirection: Axis.horizontal, child: table);
        },
      );
    }
    return _buildTable(context);
  }

  Widget _buildTable(BuildContext context) {
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

/// Scroll horizontal para una tabla ancha en escritorio. En el celular la
/// tabla ya se muestra como tarjetas a lo ancho, así que no scrollea.
class AdminTableScroll extends StatelessWidget {
  const AdminTableScroll({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBuilder.isMobile(context)) return child;
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
  }
}

/// Celular: una tarjeta por fila.
class _MobileCards extends StatelessWidget {
  const _MobileCards({required this.table});

  final AdminDataTable table;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final columns = table.columns;

    Widget card(int i) {
      final cells = table.rows[i];
      final color = table.rowTextColors?[i] ?? scheme.onSurface;
      final details = <Widget>[];
      final actions = <Widget>[];
      for (var c = 1; c < cells.length; c++) {
        final label = c < columns.length ? columns[c].trim() : '';
        // Columnas sin encabezado (acciones, íconos): van abajo a la derecha.
        if (label.isEmpty) {
          actions.add(cells[c]);
          continue;
        }
        details.add(Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 112,
                child: Text(label, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: table.cellFontSize, color: color),
                  child: Align(alignment: Alignment.centerLeft, child: cells[c]),
                ),
              ),
            ],
          ),
        ));
      }

      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cells.isNotEmpty)
                DefaultTextStyle.merge(
                  style: textTheme.titleSmall?.copyWith(color: color),
                  child: cells.first,
                ),
              ...details,
              if (actions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
                ),
            ],
          ),
        ),
      );
    }

    final list = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < table.rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          card(i),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content = list;
        final maxBodyHeight = table.maxBodyHeight;
        if (maxBodyHeight != null) {
          content = ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxBodyHeight),
            child: _ScrollableBody(child: list),
          );
        }
        // Dentro de un scroll horizontal el ancho no está acotado: las
        // tarjetas toman el ancho de la pantalla.
        if (!constraints.hasBoundedWidth) {
          return SizedBox(width: MediaQuery.sizeOf(context).width - 32, child: content);
        }
        return content;
      },
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
