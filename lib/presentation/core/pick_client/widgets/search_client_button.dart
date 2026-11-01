import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';

class SearchClientButton extends StatefulWidget {

  const SearchClientButton({super.key, required this.onPickClient, this.asField = false});

  final Function(Client) onPickClient;

  /// Se ve como un campo de búsqueda ("Buscar por nombre, email o teléfono")
  /// en vez de un botón.
  final bool asField;

  @override
  State<SearchClientButton> createState() => _SearchClientButtonState();
}

class _SearchClientButtonState extends State<SearchClientButton> {
  final controller = DropdownController();

  @override
  Widget build(BuildContext context) {
    return DropdownWidget( 
    menuWidget: ClientListContainer(
      onPressClose: () => controller.hide?.call(),
      onPickClient: widget.onPickClient,
    ), 
    dropdownController: controller,
    width: widget.asField ? 420 : 300,
    child: widget.asField
        ? _SearchField(onTap: () => controller.toggle!())
        : FilledButton.icon(
            onPressed: (){
              controller.toggle!();
            }, 
            label: const Text("Buscar"),
            icon: const Icon(Icons.search),
          ),
    );
  }
}

/// El disparador con forma de campo: borde `outline`, lupa y la pista.
class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: scheme.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Icon(Icons.search, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buscar por nombre, email o teléfono',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, color: scheme.onSurfaceVariant),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class ClientListContainer extends StatefulWidget {
  const ClientListContainer({
    super.key, 
    required this.onPickClient, required this.onPressClose, 
  });

  final Function(Client) onPickClient;
  final Function() onPressClose;

  @override
  State<ClientListContainer> createState() => _ClientListContainerState();
}

class _ClientListContainerState extends State<ClientListContainer> {

  bool isSearching = false;
  List<Client> clientsResult = [];
  String? search;
  CancelableOperation? searchOperation;
  Timer? searchTimer;
  
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          hintText: "Nombre, apellido, email o telefono",
                          hintStyle: const TextStyle(fontSize: 13),
                          suffixIcon: IconButton(onPressed: () => widget.onPressClose.call(), icon: Icon(Icons.close))
            ),
            autofocus: true,
            onChanged: onChangedSearch,
          ),
      
          if(isSearching) ...[ const SizedBox(height: 8,), const LinearProgressIndicator()],
      
          if(clientsResult.isNotEmpty) Expanded(
            child: ListView(
              children: clientsResult.map((client) {
                return ListTile(
                  onTap: () {
                   widget.onPickClient(client);
                  },
                  isThreeLine: true,

                  leading:CircleAvatar(child: Text(client.person!.fullName.characters.first)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(client.person!.hasEmail()) Text(client.person!.email!, overflow: TextOverflow.ellipsis,),
                      if(client.person!.hasPhone()) Text(client.person!.phone!, overflow: TextOverflow.ellipsis)
                    ],
                  ),
                  title: Text(client.person!.fullName),
                );
              },).toList(),
            ),
          ),

          if(!isSearching && search != null && search!.isNotEmpty && clientsResult.isEmpty)... const [SizedBox(height: 20,), Text("No se encontraron resultados.")],

          if(!isSearching && (search == null || search!.isEmpty || search!.length < 4)) ... const [SizedBox(height: 20,), Text("Escriba mas de 3 caracteres para realizar una busqueda.")],
      
          
        ],
      ),
    );
  }

  void onChangedSearch(value) {
  
    searchTimer?.cancel();

    final isValueValidToSearch = value.isNotEmpty && value.length > 3;

    if(!isValueValidToSearch){
      return setState(() {
        clientsResult = [];
        search = null;
        isSearching  = false;
      });
    }

    searchTimer = Timer(const Duration(milliseconds: 300), () { 
      
      setState(() {
        isSearching = true;
        search = value;
      });

      searchOperation?.cancel();

      searchOperation = CancelableOperation.fromFuture(getClients(value)).then((clients) {                    
        setState(() {
          isSearching = false;
          clientsResult = clients;
        });
      });

    });
           
  }

  Future<List<Client>> getClients(String value) async {
    final response = await sl<AdminRepository>().getClients(search!);

    final value = switch (response) {
      Left() => null,
      Right(:final value) => value,
    };

    return value?.data ?? [];
  }
}