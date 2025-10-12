import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

/// Widget reutilizable para TrinaGrid con estilos centralizados.
/// Parametriza columnas, filas, paginación y callbacks.
class CustomTrinaGrid extends StatelessWidget {
	final List<TrinaColumn> columns;
	final List<TrinaRow> rows;
	final TrinaOnLoadedEventCallback? onLoaded;
	final Widget Function(TrinaGridStateManager stateManager)? createFooter;
	final TrinaGridConfiguration? configuration;

	/// Si usas paginación, pasa el builder en [createFooter].
	const CustomTrinaGrid({
		super.key,
		required this.columns,
		required this.rows,
		this.onLoaded,
		this.createFooter,
		this.configuration,
	});

	@override
	Widget build(BuildContext context) {
		final colorScheme = Theme.of(context).colorScheme;
		return TrinaGrid(
      noRowsWidget: Center(
        child: Text("No hay registros"),
      ),
			configuration: configuration ?? TrinaGridConfiguration.dark(
				localeText: const TrinaGridLocaleText.spanish(),
				style: TrinaGridStyleConfig(
					iconColor: colorScheme.onSurfaceVariant,
					gridBorderColor: Colors.transparent,
					gridBorderWidth: 0,
					enableCellBorderVertical: false,
					enableColumnBorderVertical: false,
					enableColumnBorderHorizontal: false,
					activatedColor: colorScheme.primary.withAlpha(25),
					cellActiveColor: Colors.transparent,
					activatedBorderColor: colorScheme.primary,
					borderColor: colorScheme.outlineVariant,
					gridBackgroundColor: colorScheme.surfaceContainer,
					menuBackgroundColor: colorScheme.surface,
					rowColor: colorScheme.surfaceContainer,
					cellTextStyle: TextStyle(color: colorScheme.onSurface),
					columnTextStyle: TextStyle(color: colorScheme.onSurface),
					columnAscendingIcon: Icon(Icons.arrow_upward),
					columnDescendingIcon: Icon(Icons.arrow_downward),
					evenRowColor: colorScheme.surfaceContainerLow,
					dragTargetColumnColor: colorScheme.primary,
				),
				columnSize: TrinaGridColumnSizeConfig(autoSizeMode: TrinaAutoSizeMode.scale),
			),
			columns: columns,
			rows: rows,
			onLoaded: onLoaded,
			createFooter: createFooter,
		);
	}
}
