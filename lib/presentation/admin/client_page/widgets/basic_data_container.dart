
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/date_picker/date_picker.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/date_functions.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/responsive_builder.dart';
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

    bool isMobile = ResponsiveBuilder.isMobile(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
          borderRadius: isMobile ? BorderRadius.zero : BorderRadius.circular(10),
                border: isMobile 
                  ? Border.symmetric(horizontal: BorderSide(color: colorScheme.outline.withOpacity(0.5)))
                  : Border.all(color: colorScheme.outline.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(24),
      child: (isEditing || client == null) ? EditBasicDataContainer(client: client, onToggleEditing: onToggleEditing) : InfoBasicDataContainer(client: client, onToggleEditing: onToggleEditing),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isMobile = ResponsiveBuilder.isMobile(context);
    
    // Construir el nombre completo
    String fullName = '';
    if (client.person?.name != null) fullName += client.person!.name!;
    if (client.person?.lastName != null) {
      if (fullName.isNotEmpty) fullName += ' ';
      fullName += client.person!.lastName!;
    }
    
    if (isMobile) {
      // Layout en columna para mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar circular
              CircleAvatar(
                radius: 35,
                backgroundColor: colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 35,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              // Nombre completo
              Expanded(
                child: Text(
                  fullName.isNotEmpty ? fullName : 'Sin nombre',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Botón de edición
              IconButton(
                onPressed: () => onToggleEditing(client),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Email
          if (client.person?.email != null) ...[
            Text(
              client.person!.email!,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
          ],
          // Teléfono
          if (client.person?.phone != null) ...[
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  client.person!.phone!,
                  style: textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Edad
          if (client.person?.birdDate != null) ...[
            Text(
              "${DateFunctions.differenceInYears(client.person!.birdDate!)} años",
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
          ],
          // Información adicional
          Row(
            spacing: 4,
            children: [
              Text("Creado: ", style: textTheme.labelLarge),
              Text("01/05/2023", style: textTheme.bodyLarge),
            ],
          ),
          const SizedBox(height: 8),
          // Observaciones
          if (client.person?.observation != null)
            Text(client.person!.observation!, style: textTheme.bodyMedium)
          else
            Text("Sin observaciones", style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            )),
        ],
      );
    }
    
    // Layout horizontal para desktop/tablet
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar circular
        CircleAvatar(
          radius: 40,
          backgroundColor: colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.person,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 20),
        // Información del usuario
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Nombre completo
              Text(
                fullName.isNotEmpty ? fullName : 'Sin nombre',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              // Email, Teléfono y Edad en la misma línea
              Row(
                children: [
                  if (client.person?.email != null)
                    Text(
                      client.person!.email!,
                      style: textTheme.bodyLarge,
                    ),
                  if (client.person?.email != null && client.person?.phone != null)
                    const SizedBox(width: 16),
                  if (client.person?.phone != null) ...[
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      client.person!.phone!,
                      style: textTheme.bodyLarge,
                    ),
                  ],
                  if (client.person?.birdDate != null) ...[
                    const SizedBox(width: 16),
                    Text(
                      "${DateFunctions.differenceInYears(client.person!.birdDate!)} años",
                      style: textTheme.bodyLarge,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              // Información adicional
              Row(
                spacing: 4,
                children: [
                  Text("Creado: ", style: textTheme.labelLarge),
                  Text("01/05/2023", style: textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 4),
              // Observaciones
              if (client.person?.observation != null)
                Text(client.person!.observation!, style: textTheme.bodyMedium)
              else
                Text("Sin observaciones", style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                )),
            ],
          ),
        const Spacer(),
        // Botón de edición
        IconButton(
          onPressed: () => onToggleEditing(client),
          icon: const Icon(Icons.edit),
          tooltip: 'Editar',
        ),
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

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: FormBuilder(
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
              spacing:  24,
              children: [
                Expanded(
                  child: FormBuilderTextField(
                    name: "name", 
                    decoration:  InputDecoration(labelText: "Nombre", filled: true, fillColor: colorScheme.surfaceContainerHighest), 
                    autofocus: true,
                    validator: FormBuilderValidators.minLength(3, errorText: "Minimo 3 caracteres"))
                ),
                Expanded(
                  child: FormBuilderTextField(
                    name: "last_name", 
                    decoration:  InputDecoration(labelText: "Apellido", filled: true, fillColor: colorScheme.surfaceContainerHighest),
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
                    decoration:  InputDecoration(labelText: "Telefono", filled: true, fillColor: colorScheme.surfaceContainerHighest, helperText: ""),
                    validator: FormBuilderValidators.phoneNumber(checkNullOrEmpty: false, errorText: "Numero invalido"),
                    )
                  ),
                Expanded(child: DatePicker(name: "bird_date", inputDecoration: InputDecoration(labelText: "Fecha de nacimiento", filled: true, fillColor: colorScheme.surfaceContainerHighest, helperText: "") ,), ),

              ],
            ),
            const SizedBox(height: 5,),
            FormBuilderTextField(
              name: "email", 
              decoration:  InputDecoration(labelText: "Email", filled: true, fillColor: colorScheme.surfaceContainerHighest),
              validator: FormBuilderValidators.email(checkNullOrEmpty: false, errorText: "Email invalido"),
            ),
            const SizedBox(height: 20,),
            FormBuilderTextField(name: "observation", decoration:  InputDecoration(labelText: "Observaciones", alignLabelWithHint: true, filled: true, fillColor: colorScheme.surfaceContainerHighest), minLines: 3, maxLines: 5),
          const SizedBox(height: 24,),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              if(widget.client != null) TextButton(
                
                onPressed:  () => widget.onToggleEditing(widget.client!), 
                child: const Text("Cancelar")
              ),
              
              SizedBox(
                width: 100,
                child: buildSaveButton(),
              ),
            ],
          )
          
        ],        ),      ),
    );
  }

  Widget buildSaveButton() {

    if(isPostingData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));

    return FilledButton(
                style: ButtonStyle(
                  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                onPressed: (formKey.currentState?.isDirty ?? false) ? onPressSave : null, 
                child: const Text("Guardar")
            );
  }

  void onPressSave() async {

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

    switch (repositoryResult) {
      case Left():
        SnackbarsFunctions.showErrorsSnackbar(context, "Hubo un error al intentar guardar los datos del cliente");
      case Right(:final value):
        ClientInherited.of(context)?.updateClient(value);
        widget.onToggleEditing(value);
    }

    setState(() {
      isPostingData = false;
    });

    
  }
}

