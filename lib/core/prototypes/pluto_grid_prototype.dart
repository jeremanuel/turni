
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class PlutoGridPrototype extends StatelessWidget {
  const PlutoGridPrototype({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PlutoGrid(
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
            gridBorderColor: Theme.of(context).colorScheme.outlineVariant,
            borderColor: Theme.of(context).colorScheme.outlineVariant,
            enableGridBorderShadow: true,
            
            enableColumnBorderVertical: false,
            enableCellBorderVertical: false,
    
            gridBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            rowColor: Theme.of(context).colorScheme.surfaceContainer,
            columnTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            cellTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            cellColorInEditState: Theme.of(context).colorScheme.surface,
            activatedColor: Theme.of(context).colorScheme.surface,
            menuBackgroundColor: Theme.of(context).colorScheme.surface,
            iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
            activatedBorderColor: Theme.of(context).colorScheme.primaryContainer,
            columnAscendingIcon: const Icon(Icons.arrow_upward),
            columnDescendingIcon: const Icon(Icons.arrow_downward),
            rowHeight: 36,
    
            gridBorderRadius: BorderRadius.circular(10),
    )
      ),
      columns: [
        PlutoColumn(
          title: "Identificador", field: "id", type: PlutoColumnType.number(),
          readOnly: true,
          enableContextMenu: false,
          enableColumnDrag: false,
          enableDropToResize: false
          
        ),
        PlutoColumn(
          title: "Nombres", 
          field: "fullName", type: PlutoColumnType.text(),
          readOnly: true,
          enableContextMenu: false,
          enableColumnDrag: false,
          enableDropToResize: false
    
        ),
        PlutoColumn(
          title: "Estado", 
          field: "status", type: PlutoColumnType.text(),
          readOnly: true,
          enableContextMenu: false,
          enableColumnDrag: false,
          enableDropToResize: false
        ),
        PlutoColumn(
          title: "Etiquetas", 
          field: "labels", type: PlutoColumnType.text(),
          readOnly: true,
          enableContextMenu: false,
          enableColumnDrag: false,
          enableDropToResize: false
    
        )
    
      ], 
      rows: [
        PlutoRow(
          cells: {
            "id":PlutoCell(value: 35),
            "fullName":PlutoCell(value:"Jeremias Manuel"),
            "status":PlutoCell(value:"Al dia"),
            "labels":PlutoCell(value:"Un capo")
          } 
        ),
        PlutoRow(
          cells: {
            "id":PlutoCell(value: 35),
            "fullName":PlutoCell(value:"Jeremias Manuel"),
            "status":PlutoCell(value:"Al dia"),
            "labels":PlutoCell(value:"Un capo")
          } 
        ),
        PlutoRow(
          cells: {
            "id":PlutoCell(value: 35),
            "fullName":PlutoCell(value:"Jeremias Manuel"),
            "status":PlutoCell(value:"Al dia"),
            "labels":PlutoCell(value:"Un capo")
          } 
        ),
        PlutoRow(
          cells: {
            "id":PlutoCell(value: 35),
            "fullName":PlutoCell(value:"Jeremias Manuel"),
            "status":PlutoCell(value:"Al dia"),
            "labels":PlutoCell(value:"Un capo")
          } 
        ),                                          
      ]
    );
  }
}
