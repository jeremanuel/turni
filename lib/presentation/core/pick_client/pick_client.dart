
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
          
          if(!widget.readOnly) Text("Cliente", style: textTheme.titleSmall),

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

          if(!widget.readOnly) const SizedBox(height: 8),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      }
    );

  }

  Row buildInitialState() {
    return Row(
      spacing: 8,
      children: [
        Expanded(
          child: SearchClientButton(
            asField: true,
            onPickClient: (client) {
          
              fieldKey.currentState?.didChange(client);
          
            },
          ),
        ),
        TextButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Nuevo cliente"),
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
      ],
    );
  }

  /// El cliente elegido: una fila con borde (avatar, nombre y contacto) y la
  /// cruz para elegir otro.
  Widget buildPickedClientInfo() {
    final client = fieldKey.currentState!.value!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final contact = [
      if (client.person!.hasEmail()) client.person!.email!,
      if (client.person!.hasPhone()) client.person!.phone!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: Text(client.person!.fullName.trim().characters.first.toUpperCase()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(client.person!.fullName, style: textTheme.titleSmall, overflow: TextOverflow.ellipsis),
            if (contact.isNotEmpty)
              Text(contact, style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant), overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (!widget.readOnly)
          IconButton(
            tooltip: 'Elegir otro cliente',
            onPressed: () => fieldKey.currentState?.didChange(null),
            icon: const Icon(Icons.close),
          ),
      ]),
    );
  }







}


