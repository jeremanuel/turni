import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/label_chip.dart';
import '../../../../core/presentation/components/inputs/dropdown_menu_form.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../states/global_data/global_data_cubit.dart';
import '../bloc/clients_list_bloc.dart';
import '../list_utils/client_list_filters.dart';

class ClientListFiltersContainer extends StatefulWidget {
  const ClientListFiltersContainer({
    super.key,
  });

  @override
  State<ClientListFiltersContainer> createState() =>
      _ClientListFiltersContainerState();
}

class _ClientListFiltersContainerState extends State<ClientListFiltersContainer> {
  final _focusNode = FocusNode();

  unFocus() {
    _focusNode.unfocus();
    setState(() {});
  }

  focus() {
    _focusNode.requestFocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final clientsBloc = BlocProvider.of<ClientsListBloc>(context);

    onSearch() {
      if (!clientsBloc.isDirty(clientsBloc.filtersFormKey.currentState?.instantValue ?? {})) return;

      final filters = clientsBloc.filtersFormKey.currentState?.instantValue;

      if (filters == null) return;

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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 102,
                  decoration: BoxDecoration(
                      color: colorSchenme.surfaceContainerLow,
                      border: Border.symmetric(
                          horizontal: getBorder(colorSchenme))),
                  child: Row(
                    spacing: 10,
                    children: [
                      const _SearchBarFilter(),
                      if (ResponsiveBuilder.isDesktop(context)) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: VerticalDivider()),
                        TextButton(
                          onPressed: () {},
                          child: const Row(
                            spacing: 4,
                            children: [
                              Icon(Icons.filter_alt_outlined),
                              Text("Filtros avanzados"),
                            ],
                          ),
                         
                        ),
                        const Spacer(),
                        _ClearFiltersButton(
                            clientsBloc: clientsBloc,
                            filtersFormKey: clientsBloc.filtersFormKey),
                      ] else ...[
                        const Spacer(),
                        const Text("data5"),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.filter_alt_outlined),
                          tooltip: "Mas filtros",
                        )
                      ],
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: VerticalDivider()
                      ),
                      Tooltip(
                        message: "Buscar",
                        child: FilledButton(
                            onPressed: clientsBloc.isDirty(clientsBloc
                                        .filtersFormKey
                                        .currentState
                                        ?.instantValue ??
                                    {})
                                ? onSearch
                                : null,
                            child: const Row(
                              spacing: 8,
                              children: [
                                Icon(Icons.person_search_sharp),
                              ],
                            )),
                      )
                    ],
                  ),
                ),
                if (ResponsiveBuilder.isMobile(context) &&
                    !clientsBloc.hasDefaultFilters())
                  Container(
                    height: 40,
                    color: colorSchenme.onPrimary,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _ClearFiltersButton(
                            clientsBloc: clientsBloc,
                            filtersFormKey: clientsBloc.filtersFormKey)
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
    if (_focusNode.hasFocus) {
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
        onPressed: !clientsBloc.hasDefaultFilters()
            ? () {
                filtersFormKey.currentState
                    ?.patchValue(ClientListFilters().toJson());
                clientsBloc
                    .add(ClientsListEvent.changeFilters(ClientListFilters()));
              }
            : null,
        child: const Row(
          spacing: 8,
          children: [Icon(Icons.filter_alt_off_sharp), Text("Limpiar Filtros")],
        ));
  }
}

class LabelsFilter extends StatelessWidget {
  const LabelsFilter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var options = sl<GlobalDataCubit>().state.labels.data ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Text("Etiquetas"),
        DropdownMenuForm(name: "labelId", dropdownMenuEntries: [
          ...options.map((e) => DropdownMenuEntry(
              value: e.labelId,
              labelWidget:
                  Align(alignment: Alignment.centerLeft, child: Labelchip(e)),
              label: e.value)),
        ])
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
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const Row(
         children: [
           SizedBox(
             width: 8,
           ),
           Text("A quien estás bucando?"),
         ],
                  ), 
        SizedBox(
          width: ResponsiveBuilder.isMobile(context) ? 200 : 300,
          height: 48,
          child: FormBuilderField<String>(
              onChanged: (value) {
                if (_controller?.text == value) return;
              
                _controller?.text = value ?? '';
              },
              name: "search",
              builder: (field) {
                _controller ??= TextEditingController(text: field.value);
              
                return SearchBar(
                    controller: _controller,
                    autoFocus: true,
                    hintText: "ID, Nombres, Telefono, Email",
                    hintStyle:
                        WidgetStateProperty.all(const TextStyle(fontSize: 14)),
                    textStyle:
                        WidgetStateProperty.all(const TextStyle(fontSize: 14)),
                    onChanged: field.didChange);
              }),
        )
      ],
    );
  }
}
