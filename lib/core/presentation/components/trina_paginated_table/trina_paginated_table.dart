import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';
import '../paginated_table/paginated_table.dart';

class TrinaPaginatedTable extends StatefulWidget {

  const TrinaPaginatedTable({super.key, required this.columns, this.loadPage, required this.getStateManager, required this.totalRows, this.rowsPerPage = 15});

  final List<TrinaColumn> columns;
  final Function(int, int)? loadPage;
  final Function(TrinaGridStateManager) getStateManager;
  final int totalRows;
  final int rowsPerPage;

  @override
  State<TrinaPaginatedTable> createState() => _TrinaPaginatedTableState();
}

class _TrinaPaginatedTableState extends State<TrinaPaginatedTable> {

  int currentPage = 1;

  TrinaGridStyleConfig buildStyle() {
    return TrinaGridStyleConfig(
      columnTextStyle: Theme.of(context).textTheme.bodyMedium!,
      activatedBorderColor: Colors.transparent,
      cellActiveColor: Colors.transparent,
      activatedColor: Colors.transparent,
      enableColumnBorderHorizontal: false,
      enableColumnBorderVertical: false,
      gridBorderRadius: BorderRadius.circular(16),
      gridBorderColor: Colors.transparent,
      enableCellBorderVertical: false,
      borderColor: Theme.of(context).colorScheme.outlineVariant,
      gridBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      rowColor: Theme.of(context).colorScheme.surfaceContainer
    );
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Expanded(
          child: TrinaGrid(
                    mode: TrinaGridMode.readOnly,
                    onRowChecked: (event) {
                      print(event);
                    },
                    onLoaded: (event) {
                      widget.getStateManager(event.stateManager);
                    },
                    configuration: TrinaGridConfiguration(
                      
                      columnSize: const TrinaGridColumnSizeConfig(
                        autoSizeMode: TrinaAutoSizeMode.scale,
                        
                      ),
                      style: buildStyle()
                    ),
                    columns: widget.columns,
                    rows: [],
                    
                  ),
                  
        ),
        PaginationContainer(
                        pagesCount: (widget.totalRows / widget.rowsPerPage).ceil(), 
                        currentPage: currentPage, 
                        onSelectPage: (page){ 
                          widget.loadPage?.call(page, 1);
                          currentPage = page;
                          setState(() {});
                        }
                      )
      ],
    );
  }
}
