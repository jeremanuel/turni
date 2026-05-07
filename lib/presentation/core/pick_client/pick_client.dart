
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../domain/entities/client.dart';
import 'widgets/new_client_form.dart';
import 'widgets/search_client_button.dart';

class PickClient extends StatefulWidget {
  const PickClient({
    super.key,
    this.onPressNew, 
    this.onBackToSelection, 
    required this.name, 
    this.validator, 
    this.isRequired = false, 
    this.initialValue, 
    this.readOnly = false,
    this.onChange
  });  
  
  /// Invocado cuando se preciona en "Nuevo" cliente.
  final Function()? onPressNew;
  /// Invocado al volver a la etapa inicial del componente.
  final Function()? onBackToSelection;
  /// Invocado al seleccionar un cliente existente desde la etapa inicial.
  final Function(Client?)? onChange;
  final String name;
  final String? Function(Client?)? validator;
  final bool isRequired;
  final Client? initialValue;
  final bool readOnly;

  @override
  State<PickClient> createState() => _PickClientState();
}

class _PickClientState extends State<PickClient> {
  bool newMode = false;
  
  final GlobalKey<FormFieldState<Client?>> fieldKey = GlobalKey<FormFieldState<Client?>>();
  final GlobalKey<FormBuilderState> newClientFormKey = GlobalKey<FormBuilderState>();
  
  
  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;
 
    return FormBuilderField<Client?>(
      initialValue: widget.initialValue,
      onChanged: (value) => widget.onChange?.call(value),
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

      final children = <Widget>[
          
          if(!widget.readOnly) Text("Cliente", style: textTheme.titleMedium),

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

          if(!widget.readOnly) const SizedBox(height: 16),
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
      spacing: 8,
      children: [
        Expanded(
          child: SearchClientButton(
            onPickClient: (client) {
          
              fieldKey.currentState?.didChange(client);
          
            },
          ),
        ),
        Expanded(
          child: OutlinedButton.icon(
            style:TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
            icon: const Icon(Icons.add),
            label: const Text("Crear"),
            onPressed: () {
              
              context.pushNamed(
                AppRoutes.NEW_CLIENT_ROUTE.name,
                extra: {
                  'onClientCreated': (Client client) {
                    context.pop();
                    fieldKey.currentState?.didChange(client);
                  }
                }
              );
          
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                widget.onPressNew?.call();
              });
              
            }
          ),
        )
      ],
    );
  }

  Widget buildPickedClientInfo() {
    final client = fieldKey.currentState!.value;

    return InkWell(
      onTap: () {
        context.goNamed(AppRoutes.CLIENT_ROUTE.name,  pathParameters: {"clientId":client.clientId!});
      },
      child: ListTile(  
        leading: CircleAvatar(
            child: Text(client!.person!.fullName.characters.first)
          ),
        trailing: widget.readOnly ? null : IconButton(
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
      ),
    );
  }






}


