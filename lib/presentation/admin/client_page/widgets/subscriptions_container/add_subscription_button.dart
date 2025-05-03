import 'package:flutter/material.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../../core/utils/responsive_builder.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../core/cubit/auth/auth_cubit.dart';
import 'add_subscription_container.dart';

class AddSubscriptionButton extends StatefulWidget {
  
  const AddSubscriptionButton({super.key, required this.client});
  
  final Client client;

  @override
  State<AddSubscriptionButton> createState() => _AddSubscriptionButtonState();
}

class _AddSubscriptionButtonState extends State<AddSubscriptionButton> {

  final dropdownController = DropdownController();

  Widget buildButton(BuildContext context, Client client) {
    
    if(ResponsiveBuilder.isMobile(context)){
      return IconButton(
              onPressed:() => onPressAddSubscription(context, client), 
              icon: const Icon(Icons.add), 
              tooltip: "Agregar subscripcion",
            );
      }
    
    return TextButton(
      onPressed:() => onPressAddSubscription(context, client), 
      child: const Text("Agregar subscripcion")
    );
  }

  onPressAddSubscription(BuildContext context, Client client){
    
    if(client.clientSubscriptions?.any((subscription) => subscription.isActive) ?? false){
      return SnackbarsFunctions.showErrorsSnackbar(context, "El cliente ya tiene una subscripcion activa");
    }

    dropdownController.show!();
  }


  @override
  Widget build(BuildContext context) {
    final clubPartitions =  sl<AuthCubit>().state.userCredential?.admin?.clubPartitions;

    return DropdownWidget(
      menuWidget: AddSubscriptionContainer(clubPartitions: clubPartitions, client: widget.client),
      dropdownController: dropdownController,
      child: buildButton(context, widget.client)
    );
  }
  
}