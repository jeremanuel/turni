import 'package:flutter/material.dart';
import 'package:trina_grid/trina_grid.dart';

import '../../../../domain/entities/label.dart';
import '../inputs/LabelChip.dart';
import '../paginated_table/paginated_table.dart';

class TrinaPaginatedTable extends StatefulWidget {

  const TrinaPaginatedTable({super.key, required this.columns, required this.loadPage, required this.getStateManager});

  final List<TrinaColumn> columns;
  final Function(int, int) loadPage;
  final Function(TrinaGridStateManager) getStateManager;

  @override
  State<TrinaPaginatedTable> createState() => _TrinaPaginatedTableState();
}

class _TrinaPaginatedTableState extends State<TrinaPaginatedTable> {


  TrinaGridStyleConfig buildStyle() {
    return TrinaGridStyleConfig(
      activatedBorderColor: Colors.transparent,
      cellActiveColor: Colors.transparent,
      activatedColor: Colors.transparent,
      enableColumnBorderHorizontal: false,
      enableColumnBorderVertical: false,
      
      gridBorderWidth: 0,
      gridBorderColor: Colors.transparent,
      borderColor: Colors.transparent,
      gridBackgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      rowColor: Theme.of(context).colorScheme.surfaceContainer
    );
  }

  @override
  Widget build(BuildContext context) {

    


    return TrinaGrid(
              onLoaded: (event) {
                widget.getStateManager(event.stateManager);
              },
              onRowChecked: (event) => print(event),
              onSelected: (event) => print(event),
              configuration: TrinaGridConfiguration(
                
                style: buildStyle()
              ),
              columns: widget.columns,
              rows: [
                TrinaRow(
                  cells: {
                    "name": TrinaCell(
                      renderer: (rendererContext) {
                        return Text("data");
                      },
                    ),
                    "email": TrinaCell(
                      renderer: (rendererContext) {
                        return Text("data");
                      }
                    ),
                          "phone": TrinaCell(
                      renderer: (rendererContext) {
                        return Text("data");
                      }
                    ),
                    "labels": TrinaCell(renderer: (rendererContext) {
                     
                        return SingleChildScrollView(
                          child: Row(
                            spacing: 4,
                            children: [
                              Labelchip(Label(1, "green", Colors.amberAccent, 1)),
                              Labelchip(Label(1, "pichon", Colors.redAccent, 1)),
                              Labelchip(Label(1, "1capoooo", Colors.greenAccent, 1))
                            ],
                          ),
                        );
                      }),
                  }
                ),
                TrinaRow(
                  
                  cells: {
                    "name": TrinaCell(
                      renderer: (rendererContext) {
                        return Text("data");
                      },
                    ),
                    "email": TrinaCell(
                      renderer: (rendererContext) {
                        return Text("data");
                      }
                    ),
                    "phone": TrinaCell(
                      renderer: (rendererContext) {
                        return Text("data");
                      }
                    ),
                    "labels": TrinaCell(renderer: (rendererContext) {
                        return Text("data");
                      }),
                  }
                )
              ],
              createFooter: (stateManager) {

                if(stateManager.showLoading) return const SizedBox();
                return PaginationContainer(pagesCount: stateManager.totalPage, currentPage: stateManager.page, onSelectPage: (page){ widget.loadPage(page, 1); });

              },
            );
  }
}