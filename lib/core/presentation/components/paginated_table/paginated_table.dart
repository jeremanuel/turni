import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../domain/entities/request/page_response.dart';

class PaginatedTable<T> extends StatefulWidget {
  const PaginatedTable({
    super.key, 
    this.isPaginated = true, 
    required this.dataSource, 
    required this.onTap, 
    required this.columns
  });

  final bool isPaginated;
  final DataGridSourceCustomASource<T> dataSource;
  final Function(DataGridRow, T)? onTap;
  final List<GridColumn> columns;

  @override
  State<PaginatedTable> createState() => _PaginatedTableState<T>();
}

class _PaginatedTableState<T> extends State<PaginatedTable<T>> {

  late final DataGridSourceCustomASource<T> _dataSource;
  
  @override
  void initState() {
    _dataSource = widget.dataSource;
    
    _dataSource.addListener(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: [
          if(_dataSource.isLoading) const Center(child: CircularProgressIndicator()),

          Column(
            children: [
              Expanded(
                child: SfDataGrid(
                    onCellTap: (details) {
                      final rowIndex = details.rowColumnIndex.rowIndex - 1;
                    
                      widget.onTap?.call(_dataSource.rows[rowIndex], _dataSource.entities[rowIndex]);
                    },
                    headerGridLinesVisibility: GridLinesVisibility.none,
                    gridLinesVisibility: GridLinesVisibility.none,
                    shrinkWrapRows: true,  
                    source: _dataSource,
                    columns: widget.columns,            
                  ),
              ),

            if(widget.isPaginated) ... [
              const Divider(),
              PaginationContainer(currentPage: _dataSource.currentPage, pagesCount: _dataSource.pagesCount, onSelectPage: (page) => _dataSource.loadPage(page),)
            ]              
            ],
          ),
        ],
      );
  }
}

class PaginationContainer extends StatelessWidget {
  const PaginationContainer({
    super.key, required this.pagesCount, required this.currentPage, required this.onSelectPage,
  });

  final int pagesCount;
  final int currentPage;
  final Function(int) onSelectPage;

  @override
  Widget build(BuildContext context) {

    if(pagesCount == 0){
      return const SizedBox();
    }

    return Row(
     spacing: 8,
     children: [
      IconButton(onPressed: (){}, icon: const Icon(Icons.navigate_before)),
      
      if(currentPage == pagesCount && currentPage != 1 && (currentPage - 2) > 0 ) IconButton(onPressed: (){ onSelectPage.call(currentPage - 2); }, icon: Text((currentPage - 2).toString())),
      if(currentPage > 1) IconButton(onPressed: () => onSelectPage.call(currentPage - 1) , icon: Text((currentPage - 1).toString())),

      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.all(Radius.circular(25))
        ),
        child: IconButton(onPressed: null, icon: Text((currentPage).toString(), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),)  )),

      if(currentPage != pagesCount)  IconButton(onPressed: () => onSelectPage.call(currentPage + 1), icon: Text((currentPage + 1).toString()), color: Colors.red,),
      if(currentPage == 1 && currentPage + 2 <= pagesCount)  IconButton(onPressed: () => onSelectPage.call(currentPage + 2), icon: Text((currentPage + 2).toString()), color: Colors.red,),

       IconButton(onPressed: (){}, icon: const Icon(Icons.navigate_next)),
     ],
    );
  }
}

class ColumnWrapper extends StatelessWidget {
  const ColumnWrapper({super.key, 
    required this.child,
    this.padding = EdgeInsets.zero
  });


  final Widget child;
  final EdgeInsetsGeometry  padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Padding(
          padding: padding,
          child: child
        ),
        const Spacer(),
        const Divider(height: 1,),
    
      ],
    );
  }
}

abstract class DataGridSourceCustomASource<T> extends DataGridSource {

  @override
  List<DataGridRow> get rows => _dataGridRows;

  List<T> entities = [];

  int currentPage = 1;
  int pagesCount = 0;
  bool isLoading = false;
  abstract int rowsPerPage;

  Future<PageResponse<T>> getPaginatedData(int page);
  DataGridRow  dataGridRowFromValue(T value);

  List<DataGridRow> _dataGridRows = [];

  DataGridSourceCustomASource();


  Future loadPage(int page) async {

    isLoading = true;

    currentPage = page;
    
    notifyListeners();

    final response = await getPaginatedData(page);

    if(currentPage > response.total) currentPage = response.total;

    pagesCount = (response.total / rowsPerPage).ceil();
        
    isLoading = false;

    entities = response.data;

    _dataGridRows = response.data.map(dataGridRowFromValue).toList();
    
    notifyListeners();
  }
  


  @override
  DataGridRowAdapter? buildRow(DataGridRow row) {

    return DataGridRowAdapter(
      cells: [
        ColumnWrapper(child: Text(row.getCells()[0].value.toString())),
        ColumnWrapper(child: Text(row.getCells()[1].value.toString())),
        ColumnWrapper(child: Text(row.getCells()[2].value.toString())),      
        ColumnWrapper(child: Text(row.getCells()[0].value.toString())),
        ColumnWrapper(child: Text(row.getCells()[1].value.toString())),
        ColumnWrapper(child: Text(row.getCells()[2].value.toString())),      
      ]
    );
      
  }

}