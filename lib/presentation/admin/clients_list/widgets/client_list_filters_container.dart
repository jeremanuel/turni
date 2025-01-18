import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../core/presentation/components/inputs/LabelChip.dart';
import '../../../../core/presentation/components/inputs/dropdown_menu_form.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/label.dart';
import '../bloc/clients_list_bloc.dart';
import '../list_utils/client_list_filters.dart';

class ClientListFiltersContainer extends StatefulWidget {
  const ClientListFiltersContainer({
    super.key,
  });

  @override
  State<ClientListFiltersContainer> createState() => _ClientListFiltersContainerState();
}

class _ClientListFiltersContainerState extends State<ClientListFiltersContainer> {

  final _focusNode = FocusNode();

  unFocus(){
    _focusNode.unfocus();
    setState(() {});
  }

  focus(){
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    final clientsBloc = BlocProvider.of<ClientsListBloc>(context);

    onSearch(){

      if(!clientsBloc.isDirty(clientsBloc.filtersFormKey.currentState?.instantValue ?? {})) return;

      final filters = clientsBloc.filtersFormKey.currentState?.instantValue;

      if(filters == null) return;

      clientsBloc.add(ClientsListEvent.changeFilters(ClientListFilters.fromJson(filters)));
      
      _focusNode.unfocus();

      setState(() {});

    }
    final colorSchenme = Theme.of(context).colorScheme;
    
    return FormBuilder(
      initialValue: clientsBloc.state.dataSource.filters.toJson(),
      key: clientsBloc.filtersFormKey,
      onChanged: () => setState(() {}),
      child: CallbackShortcuts(
        bindings: {
            LogicalKeySet(LogicalKeyboardKey.enter): () => onSearch(),
            LogicalKeySet(LogicalKeyboardKey.escape): () => unFocus()
        },
        child: Focus(
          focusNode: _focusNode,
          child: TapRegion(
            onTapInside: (event) => focus(),
            onTapOutside: (event) => unFocus(),
            child: Column(
              children: [
                Container( 
                  padding:const EdgeInsets.all(12),
                  height: 102,
                  decoration: BoxDecoration(
                    color: colorSchenme.surfaceContainerLow,
                    border: Border.symmetric(horizontal: getBorder(colorSchenme))
                  ),
                  child: Row(
                    spacing: 10,
                    children: [
                      const _SearchBarFilter(),
                      if(ResponsiveBuilder.isDesktop(context)) ...[
                        const SizedBox(width: 100),
                        const _StatusFilter(),
                        const SizedBox(width: 20),
                        const LabelsFilter(),
                        const Spacer(),
                        _ClearFiltersButton(clientsBloc: clientsBloc, filtersFormKey: clientsBloc.filtersFormKey),
                
                      ] 
                      else ...[const Spacer(), IconButton(onPressed: (){}, icon: const Icon(Icons.filter_alt_outlined), tooltip: "Mas filtros",)], 
                      const VerticalDivider(),
                      Tooltip(
                        message: "Buscar",
                        child: FilledButton(
                          onPressed: clientsBloc.isDirty(clientsBloc.filtersFormKey.currentState?.instantValue ?? {})  ? onSearch : null, 
                          child: const Row(
                            spacing: 8,
                            children: [
                              Icon(Icons.person_search_sharp),
                            ],
                          )
                        ),
                      )
                      
                    ],
                  ),
                ),
                if(ResponsiveBuilder.isMobile(context) && !clientsBloc.hasDefaultFilters())
                  Container(
                    height: 40,
                    color: colorSchenme.onPrimary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ClearFiltersButton(clientsBloc: clientsBloc, filtersFormKey: clientsBloc.filtersFormKey)
                      ],
                    ),
                  )                
              ],
            ),
          ),
        ),
      ),
    );
  }



  BorderSide getBorder(ColorScheme colorSchenme) {
    if(_focusNode.hasFocus){
      return BorderSide(color: colorSchenme.primary);
    }

    return BorderSide(color: colorSchenme.outlineVariant);
  }
}

class _ClearFiltersButton extends StatelessWidget {
  const _ClearFiltersButton({
    required this.clientsBloc,
    required this.filtersFormKey,
  });

  final ClientsListBloc clientsBloc;
  final GlobalKey<FormBuilderState> filtersFormKey;

  @override
  Widget build(BuildContext context) {
    
    return TextButton(
    onPressed: !clientsBloc.hasDefaultFilters() ? (){ filtersFormKey.currentState?.patchValue(ClientListFilters().toJson()); clientsBloc.add(ClientsListEvent.changeFilters(ClientListFilters())); } : null, 
    child: const Row(
      spacing: 8,
      children: [
        Icon(Icons.filter_alt_off_sharp),
        Text("Limpiar Filtros")
      ],
    ));
  }
}

class LabelsFilter extends StatelessWidget {
  const LabelsFilter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    var options = [
      Label(1, "Crack", Colors.amber), 
      Label(2, "Pro", Colors.blue),
      Label(3, "No paga a tiempo", Colors.red.shade300),
      Label(4, "No contesta el teléfono", Colors.green),
      Label(5, "No guarda Discos", Colors.purple),
      Label(6, "Cliente frecuente", Colors.orange),
      Label(7, "Recomienda a otros", Colors.cyan),
      Label(8, "Siempre puntual", Colors.teal),
      Label(9, "Cliente VIP", Colors.deepOrange),
      Label(10, "Requiere seguimiento", Colors.brown),
      Label(11, "Nuevo", Colors.lime),
      Label(12, "Internacional", Colors.indigo),
      Label(13, "Local", Colors.pink),
      Label(14, "Premium", Colors.deepPurple),
      Label(15, "Estándar", Colors.grey),
    ];
    return  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text("Etiquetas"),
            DropdownMenuForm(
              name: "labelId",
              dropdownMenuEntries: [
                ...options.map((e) => DropdownMenuEntry(value: e.labelId, labelWidget: Align(alignment: Alignment.centerLeft, child: Labelchip(e)), label: e.value)).toList(),
              ])
          ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter();

  @override
  Widget build(BuildContext context) {
    return  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const Text("Estado"),
            DropdownMenuForm(
             name: "statusId",
             dropdownMenuEntries: [
                 DropdownMenuEntry(value: 1, labelWidget: Chip(label: Text("Activo"), backgroundColor: Colors.green.shade600, side: BorderSide.none,), label: "Activo"),
                 DropdownMenuEntry(value: 1, labelWidget: Chip(label: Text("Inactivo"), backgroundColor: Colors.red.shade600, side: BorderSide.none,), label: "Inactivo")
             ],
            )
          ],
    );
  }
}

class _SearchBarFilter extends StatefulWidget {
  const _SearchBarFilter();

  @override
  State<_SearchBarFilter> createState() => _SearchBarFilterState();
}

class _SearchBarFilterState extends State<_SearchBarFilter> {

  TextEditingController? _controller;

  @override
  Widget build(BuildContext context) {


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Row(
          children: [
            SizedBox(width: 8,),
            Text("A quien estás bucando?"),
          ],
        ),
        SizedBox(
          width: ResponsiveBuilder.isMobile(context) ? 200 : 300,
          height: 48,
          child: FormBuilderField<String>(
            onChanged: (value){
              print("${_controller?.text} | $value");
              if(_controller?.text == value) return;
                
              _controller?.text = value ?? '';
            },
            name: "search",
            builder: (field) {

              _controller ??= TextEditingController(text: field.value);

              return SearchBar(
                controller: _controller,
                autoFocus: true,
                hintText: "ID, Nombres, Telefono, Email",
                hintStyle: WidgetStateProperty.all(const TextStyle(fontSize: 14)),
                textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 14)),
                onChanged:field.didChange
              );
            
            }
          ),
        )
      ],
    );
  }
}