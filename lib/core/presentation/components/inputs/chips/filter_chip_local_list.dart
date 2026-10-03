import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../utils/responsive_builder.dart';
import '../dropdown_widget.dart';

class FilterChipLocalList<T> extends StatefulWidget {
  const FilterChipLocalList({
    super.key,
    required this.items, 
    required this.label, 
    required this.buildItem, 
    required this.searchable, 
    required this.onItemSelected, 
    this.searchFunction, 
    required this.buildSelectedLabel, 
    this.selectedItem, 
    this.chipMaxWidth
  });
  
  final List<T> items;
  final Widget label;
  final Widget Function(T) buildItem;
  final Function(T) onItemSelected;
  final bool searchable;
  final List<T> Function(String)? searchFunction;
  final Widget Function(T) buildSelectedLabel;
  final  T? selectedItem;
  final double? chipMaxWidth;

  @override
  State<FilterChipLocalList<T>> createState() => _FilterChipLocalListState<T>();
}

class _FilterChipLocalListState<T> extends State<FilterChipLocalList<T>> {

  final DropdownController _dropdownController = DropdownController();
  late List<T> filteredItems;
  TextEditingController searchController = TextEditingController();
  final GlobalKey formKey = GlobalKey();
  int _focusedIndex = 0;
  final FocusNode _menuFocusNode = FocusNode();

  @override
  void initState() {
    if (widget.selectedItem != null) {
      filteredItems = [
        widget.selectedItem as T,
        ...widget.items.where((item) => item != widget.selectedItem)
      ];
      _focusedIndex = 1;
    } else {
      filteredItems = widget.items;
      _focusedIndex = 0;
    }
    super.initState();
  }

  @override
  void dispose() {
    _menuFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _focusedIndex = (_focusedIndex + 1) % filteredItems.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _focusedIndex = (_focusedIndex - 1 + filteredItems.length) % filteredItems.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        final item = filteredItems[_focusedIndex];
        widget.onItemSelected(item);
        _dropdownController.hide!();
        setState(() {
          filteredItems = widget.items;
          searchController.clear();
          _focusedIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      menuWidget: buildMenu(),
      dropdownController: _dropdownController,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.chipMaxWidth ?? double.infinity,
        ),
        child: FilterChip(
          visualDensity: VisualDensity(vertical: -4, horizontal: -4),
          label: buildSelectedLabel(), 
          onSelected: (value) {
            _dropdownController.toggle!();
          
        },),
      ),
    );
  }

  SizedBox buildMenu() {
    return SizedBox(
      height: 300,
      child: KeyboardListener(
        focusNode: _menuFocusNode,
        onKeyEvent: _handleKeyEvent,
        
        child: Column(
          children: [
            ListTile(
              title: TextField(
                key: formKey,
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Buscar...",
                  border: OutlineInputBorder()
                ),
                onChanged: (value) {
                  print(value);
                  setState(() {
                    filteredItems = widget.searchFunction!(value);
                    
                    _focusedIndex = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final currentItem = filteredItems[index];
                        final isFocused = _focusedIndex == index;
                        return ListTile(
                          trailing: widget.selectedItem == currentItem ? const Icon(Icons.check, size: 16,) : null,
                          selected: widget.selectedItem == currentItem,
                          focusColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          hoverColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          tileColor: isFocused ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
                          dense: true,
                          title: widget.buildItem(currentItem),
                          onTap: () {
                            setState(() {
                            widget.onItemSelected(currentItem);
                            _dropdownController.hide!();
                            filteredItems = filteredItems = [
                              currentItem,
                              ...widget.items.where((item) => item != currentItem)
                            ];
                            searchController.clear();
                            _focusedIndex = 0;
                            });   
                          },
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildSelectedLabel() {
    return Row(
      spacing:4,
      children: [
        Expanded(child: widget.selectedItem != null ? widget.buildSelectedLabel(widget.selectedItem as T) : widget.label),
        const Icon(Icons.arrow_drop_down),
      ],
    );
  }
}



