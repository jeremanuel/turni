import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/person.dart';

class NewClientForm extends StatelessWidget {
  const NewClientForm({super.key, required this.newClientFormKey, this.fieldKey});

  final newClientFormKey;
  final fieldKey;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: newClientFormKey,
      onChanged: () {

        final isValid = newClientFormKey.currentState!.validate(focusOnInvalid: false);

        if(isValid){

          final values = newClientFormKey.currentState!.instantValue;

          fieldKey.currentState?.didChange(
            Client(
              person: Person(
                name: values['name'], 
                lastName: values['lastname'], 
                email: values['email'],
                phone: values['phone']
              )
            )
          );

        } else {
          fieldKey.currentState?.didChange(null);
        }


      },
      child: Column(
          children: [
            FormBuilderTextField(
              validator: requiredAndMin3,
              name: "name", 
              autofocus: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person, size: 14,),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                helperText: "Obligatorio",
                labelText: "Nombre",
                
                
              ),
            ),
            const SizedBox(height: 16,),
            FormBuilderTextField(
              name: "lastname", 
              validator: requiredAndMin3,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person, size: 14,),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                helperText: "Obligatorio",
                labelText: "Apellido"        
              ),
            ),
            const SizedBox(height: 16,),
            FormBuilderTextField(
              validator: requiredAndMin3,
              name: "phone", 
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), 
                // for version 2 and greater youcan also use this
                FilteringTextInputFormatter.digitsOnly
      
              ],
              
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, size: 14,),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                helperText: "Obligatorio",
                labelText: "Telefono",              
                  
              ),
            ),
            const SizedBox(height: 16,),
            FormBuilderTextField(
              name: "email", 
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.mail, size: 14,),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                labelText: "Email",
              ),
            ),                
          ],
        ),
    );
  }
    String? requiredAndMin3(value) {
          if(value == null || value.trim() == ''){
            return "Campo obligatorio";
          }
          if(value.length < 3){
            return "Por lo menos 3 caracteres.";
          }
  
          return null;
        }
}