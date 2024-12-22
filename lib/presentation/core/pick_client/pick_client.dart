import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/person.dart';
import '../../../domain/repositories/admin_repository.dart';
import 'widgets/new_client_form.dart';
import 'widgets/search_client_button.dart';

class PickClient extends StatefulWidget {
  const PickClient({
  super.key,
  this.onPressNew, 
  this.onBackToSelection, 
  this.onSelect,
  required this.name, 
  this.validator, 
  this.isRequired = false
  });  
  
  /// Invocado cuando se preciona en "Nuevo" cliente.
  final Function()? onPressNew;
  /// Invocado al volver a la etapa inicial del componente.
  final Function()? onBackToSelection;
  /// Invocado al seleccionar un cliente existente desde la etapa inicial.
  final Function()? onSelect;
  final String name;
  final String? Function(Client?)? validator;
  final bool isRequired;
  @override
  State<PickClient> createState() => _PickClientState();
}

class _PickClientState extends State<PickClient> {
  final SearchController _searchController = SearchController();
  bool newMode = false;
  
  final GlobalKey<FormFieldState<Client?>> fieldKey = GlobalKey<FormFieldState<Client?>>();
  final GlobalKey<FormBuilderState> newClientFormKey = GlobalKey<FormBuilderState>();
  
  
  @override
  Widget build(BuildContext context) {
 
    return FormBuilderField<Client?>(
      validator: (value) {

        if(newMode && value == null){
          return "invalid";
        }

        if(widget.isRequired && value == null) {
          return "not client picked";
        }

        return null;
      },
      name: widget.name,
      key: fieldKey,
      builder: (field) {

      final children = [
          if(!newMode)
          const Text("Cliente"),

          if(newMode) Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Nuevo Cliente"),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    newMode = false;
                    fieldKey.currentState?.didChange(null);
                  });

                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    widget.onBackToSelection?.call();
                  });
                  
                },
                icon: const Icon(Icons.close)
              )
              
          ]),

          const SizedBox(height: 16),
      ];
      
      if (field.value == null && !newMode) {
        children.add(buildInitialState());
      }

      if(field.value != null && !newMode){
        children.add(
          buildPickedClientInfo()
        );
      } 

      if(newMode){
        children.add(
          NewClientForm(newClientFormKey: newClientFormKey, fieldKey: fieldKey,)
        );
      }

        return Column(
          children: children,
        );
      }
    );

  }

  Row buildInitialState() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        SearchClientButton(
          onPickClient: (client) {

            fieldKey.currentState?.didChange(client);

          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text("Crear"),
          onPressed: () {
            setState(() {
              newMode = true;
            });

            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              widget.onPressNew?.call();
            });
            
          }
        )
      ],
    );
  }

  ListTile buildPickedClientInfo() {
    final client = fieldKey.currentState!.value;

    return ListTile(  
      leading: CircleAvatar(
          child: Text(client!.person!.fullName.characters.first)
        ),
      trailing: IconButton(
          onPressed: () {
            fieldKey.currentState?.didChange(null);
          },
          icon: const Icon(Icons.close)
        ),
      subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if(client.person!.hasEmail()) Text(client.person!.email!, overflow: TextOverflow.ellipsis,),
                    if(client.person!.hasPhone()) Text(client.person!.phone!, overflow: TextOverflow.ellipsis)
                  ],
                ),
      title: Text(client.person!.fullName),
    );
  }






}


