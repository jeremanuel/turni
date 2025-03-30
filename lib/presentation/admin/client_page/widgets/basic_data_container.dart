
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/animation/splash_animation.dart';
import '../../../../core/presentation/components/inputs/date_picker/date_picker.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/date_functions.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../core/cubit/auth/auth_cubit.dart';
import '../client_page.dart';

class BasicDataContainer extends StatelessWidget {
  const BasicDataContainer({
    super.key,
    required this.colorScheme, 
    required this.onToggleEditing, 
    required this.isEditing,
  });

  final ColorScheme colorScheme;
  final Function(Client) onToggleEditing;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    

    final client = ClientInherited.of(context)?.client;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: (isEditing || client == null) ? EditBasicDataContainer(client: client, onToggleEditing: onToggleEditing) : InfoBasicDataContainer(client: client!, onToggleEditing: onToggleEditing),
    );
  }
}

class InfoBasicDataContainer extends StatelessWidget {
  const InfoBasicDataContainer({
    super.key,
    required this.client,
    required this.onToggleEditing,
  });

  final Client client;
  final Function(Client) onToggleEditing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
    
      children: [
        Row(
          children: [
            Text(client.person!.fullName, style: Theme.of(context).textTheme.headlineSmall,),
            const Spacer(),
            IconButton(onPressed: () => onToggleEditing(client), icon: const Icon(Icons.edit))
          ],
        ),
        const SizedBox(height: 15,),
        if(client.person?.email != null)
        Row(
          spacing: 4,
          children: [
            Text("Email: ", style: Theme.of(context).textTheme.labelLarge,),
            Text(client.person!.email!, style: Theme.of(context).textTheme.bodyLarge),
          ]
        ),
        if(client.person?.phone != null)
        Row(
          spacing: 4,
          children: [
            Text("Telefono: ", style: Theme.of(context).textTheme.labelLarge),
            Text(client.person!.phone!, style: Theme.of(context).textTheme.bodyLarge),
          ]
        ),
        Row(
          spacing: 4,
          children: [
            Text("Creado: ", style: Theme.of(context).textTheme.labelLarge,),
            Text("01/05/2023", style: Theme.of(context).textTheme.bodyLarge),
          ]
        ),
        if(client.person?.birdDate != null)
        Row(
          spacing: 4,
          children: [
            Text("Edad: ", style: Theme.of(context).textTheme.labelLarge,),
            Text("${DateFunctions.differenceInYears(client.person!.birdDate!)} años", style: Theme.of(context).textTheme.bodyLarge),
          ]
        ),
        const SizedBox(height: 4,),
        if(client.person?.observation == null)
          Text("Sin observaciones", style: Theme.of(context).textTheme.bodyLarge)
        else Text(client.person!.observation!, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}


class EditBasicDataContainer extends StatefulWidget {
  const EditBasicDataContainer({
    super.key,
    required this.client, required this.onToggleEditing,
  });

  final Client? client;
  final Function(Client) onToggleEditing;

  @override
  State<EditBasicDataContainer> createState() => _EditBasicDataContainerState();
}

class _EditBasicDataContainerState extends State<EditBasicDataContainer> {

  final formKey = GlobalKey<FormBuilderState>();
  final AdminRepository adminRepository = sl<AdminRepository>();
  bool isPostingData = false;

  @override
  Widget build(BuildContext context) {

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return FormBuilder(
      onChanged: () => setState(() {}),
      key: formKey,
      initialValue: {
        "name":widget.client?.person?.name,
        "last_name":widget.client?.person?.lastName,
        "phone":widget.client?.person?.phone,
        "email":widget.client?.person?.email,
        "bird_date":widget.client?.person?.birdDate,
        "observation":widget.client?.person?.observation
      },
      child: Column(
        children: [
          Row(
            children: [
              Text(widget.client == null ? "Creando cliente" :"Editando datos basicos", style: textTheme.headlineSmall,),
              const Spacer(),
              if(widget.client != null) IconButton(onPressed: () => widget.onToggleEditing(widget.client!), icon: const Icon(Icons.close))
            ],
          ),
          const SizedBox(height: 24,),
          Row(
            spacing:  24,
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: "name", 
                  decoration:  InputDecoration(labelText: "Nombre", filled: true, fillColor: colorScheme.inversePrimary), 
                  autofocus: true,
                  validator: FormBuilderValidators.minLength(3, errorText: "Minimo 3 caracteres"))
              ),
              Expanded(
                child: FormBuilderTextField(
                  name: "last_name", 
                  decoration:  InputDecoration(labelText: "Apellido", filled: true, fillColor: colorScheme.inversePrimary),
                  validator: FormBuilderValidators.minLength(3, errorText: "Minimo 3 caracteres"),
                  )
                ),
            ],
          ),
          const SizedBox(height: 20,),
          Row(
            spacing:  24,
            children: [
              Expanded(
                child: FormBuilderTextField(
                  name: "phone", 
                  decoration:  InputDecoration(labelText: "Telefono", filled: true, fillColor: colorScheme.inversePrimary, helperText: ""),
                  validator: FormBuilderValidators.phoneNumber(checkNullOrEmpty: false, errorText: "Numero invalido"),
                  )
                ),
              Expanded(child: DatePicker(name: "bird_date", inputDecoration: InputDecoration(labelText: "Fecha de nacimiento", filled: true, fillColor: colorScheme.inversePrimary, helperText: "") ,), ),

            ],
          ),
          const SizedBox(height: 5,),
          FormBuilderTextField(
            name: "email", 
            decoration:  InputDecoration(labelText: "Email", filled: true, fillColor: colorScheme.inversePrimary),
            validator: FormBuilderValidators.email(checkNullOrEmpty: false, errorText: "Email invalido"),
          ),
          const SizedBox(height: 20,),
          FormBuilderTextField(name: "observation", decoration:  InputDecoration(labelText: "Observaciones", alignLabelWithHint: true, filled: true, fillColor: colorScheme.inversePrimary), minLines: 3, maxLines: 5),
          const SizedBox(height: 24,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              if(widget.client != null) OutlinedButton(onPressed:  (){widget.onToggleEditing(widget.client!); }, child: const Text("Cancelar")),
              
              SizedBox(
                width: 100,
                child: buildSaveButton(),
              ),
            ],
          )
          
        ],
      ),
    );
  }

  Widget buildSaveButton() {

    if(isPostingData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    return FilledButton(
                onPressed: (formKey.currentState?.isDirty ?? false) ? onPressSave : null, 
                child: const Text("Guardar")
            );
  }

  onPressSave() async {

    if(!formKey.currentState!.validate()) return null;

    setState(() {
      isPostingData = true;
    });

    Map person = Map.from(formKey.currentState!.instantValue);
    person['bird_date'] = person['bird_date']?.toIso8601String();

    final repositoryResult = await adminRepository.createOrSaveClient({
      "client_id":int.tryParse(widget.client?.clientId ?? ''),
      "person_id":int.tryParse(widget.client?.personId ?? ''),
      "person":person,
      "club_id":sl<AuthCubit>().getClubId()
    });

    repositoryResult.when(
      left: (failure) {
        SnackbarsFunctions.showErrorsSnackbar(context, "Hubo un error al intentar guardar los datos del cliente");
      }, 
      right: (client) {
        ClientInherited.of(context)?.updateClient(client);
        widget.onToggleEditing(client);
      },
    );

    setState(() {
      isPostingData = false;
    });

    
  }
}

