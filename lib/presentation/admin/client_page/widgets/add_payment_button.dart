
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/animation/splash_animation.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/payment/payment.dart';
import '../../../../domain/entities/subscription/subscription.dart';
import '../../../../domain/repositories/payment_repository.dart';
import '../../../core/cubit/auth/auth_cubit.dart';

class AddPaymentButton extends StatefulWidget {

  const AddPaymentButton({super.key, required this.client, required this.onPaymentCreated});

  final Function(Payment) onPaymentCreated;
  final Client client;

  @override
  State<AddPaymentButton> createState() => _AddPaymentButtonState();
}

class _AddPaymentButtonState extends State<AddPaymentButton> {

  final dropdownController = DropdownController();

  @override
  Widget build(BuildContext context) {
    return DropdownWidget(
      menuWidget: AddPaymentContainer(
        client: widget.client, 
        onPaymentCreated: (p0) {
          widget.onPaymentCreated.call(p0);
          Future.delayed(const Duration(seconds: 3)).then((value) => dropdownController.hide?.call());
        }), 
      dropdownController: dropdownController,
      child: buildButton(context)
    );
  }

  Widget buildButton(BuildContext context) {
    
    if(ResponsiveBuilder.isMobile(context)){
      return IconButton(
        onPressed: (){
          dropdownController.show!();
        }, 
        icon: const Icon(Icons.add_card_outlined), tooltip: "Registrar nuevo pago",
      );
    }
    
    return TextButton(
      onPressed:(){ 
        dropdownController.show!();
      }, 
      child: const Text("Registrar nuevo pago")
    );
  }
}

class AddPaymentContainer extends StatefulWidget {

  final Client client;
  final Function(Payment) onPaymentCreated;
  
  const AddPaymentContainer({
    super.key, 
    required this.client, 
    required this.onPaymentCreated,
  });

  @override
  State<AddPaymentContainer> createState() => _AddPaymentContainerState();
}

class _AddPaymentContainerState extends State<AddPaymentContainer> {

  bool isCreatingPayment = false;
  bool isPaymentCreated = false;
  DomainError? error;
  final PaymentRepository paymentRepository = sl<PaymentRepository>();

  GlobalKey<FormBuilderState> formKey = GlobalKey();
  
  late final List<Subscription> subscriptions;

  @override
  void initState() {
    subscriptions = [...Set.from(widget.client.clientSubscriptions?.map((e) => e.subscription)?? [])] ;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(error != null){
      return SplashAnimation(
        width: 300, 
        height: 430,
        color: Theme.of(context).colorScheme.errorContainer,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.onErrorContainer, size: 50).animate().fadeIn(delay: const Duration(milliseconds: 400)),
            Text(error!.message, style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onErrorContainer)).animate().fadeIn(delay: const Duration(milliseconds: 450))
          ],
        )
      );
    }

    if(isPaymentCreated){
      return SplashAnimation(
        width: 300, 
        height: 430,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Icon(Icons.check, color: Theme.of(context).colorScheme.onPrimary, size: 50).animate().fadeIn(delay: const Duration(milliseconds: 400)),
            Text("Pago creado", style: Theme.of(context).textTheme.titleLarge!.copyWith(color: Theme.of(context).colorScheme.onPrimary)).animate().fadeIn(delay: const Duration(milliseconds: 450)),
            const Spacer(),
            Row(
              children: [
                Divider(color: Theme.of(context).colorScheme.onPrimary).animate().custom(builder: (context, value, child) => SizedBox(width: value, child: child), duration: const Duration(seconds: 2, milliseconds: 500), begin: 0, end: 300, curve: Curves.easeInOut),
              ],
            )
          ],
        )
      );
    }

    return FormBuilder(
      initialValue: {
        "payment_method": 1,
        "subscription": subscriptions.firstOrNull,
        "amount": subscriptions.firstOrNull?.getCurrentPrice()?.price.toString(),
        "observations": subscriptions.isEmpty ? "Clase sin subcripcion" : null
      },
      key: formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        height: 460,
        child:  Column(
          spacing: 8,
          children: [
            Row(
              children: [
                SizedBox(width: 8,),
                Text("Nuevo pago", style: Theme.of(context).textTheme.titleLarge,),
              ],
            ),
            const Divider(),
            SizedBox(height: 4,),
            buildSubscriptionField(),
            buildAmountField(),
            buildPaymentMethodField(),
            buildObservationsField(),
            const Spacer(),
            Row(
              spacing: 8,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: (){}, child: Text("Cancelar")),
                FilledButton(
                  onPressed: () async {
                
                  final currentFormState = formKey.currentState!;
                
                  if(!currentFormState.validate()) return;
                    
                  setState(() {
                    isCreatingPayment = true;
                  });
                
                  final instantValue = currentFormState.instantValue;
                
                  final int? selectedSubscription = instantValue['subscription']?.subscriptionId;
                
                  final result = await paymentRepository.createPayment({
                      "amount": double.parse(instantValue['amount']),
                      "payment_method_id": instantValue['payment_method'],
                      "observation": instantValue['observations'],
                      "client_subscription_id": widget.client.clientSubscriptions!.firstWhereOrNull((element) => element.subscription.subscriptionId == selectedSubscription)?.clientSubscriptionId,
                      "client_id": int.parse(widget.client.clientId!),
                      "created_by_admin": sl<AuthCubit>().state.userCredential!.admin!.adminId
                    });
                
                  result.when(
                    right: widget.onPaymentCreated,
                    left: (failure) => setState(() {
                      error = failure;
                      isCreatingPayment = false;
                    }),
                  );
                
                  setState(() {
                    isCreatingPayment = false;
                    isPaymentCreated = true;
                  });
                
                  
                
                  }, 
                  child: isCreatingPayment ? SizedBox(height: 24,width: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2,)) : const Text("Crear Pago")
                ),
              ],
            )
          ],
        )
      ),
    );
  }

  FormBuilderTextField buildObservationsField() {
    return FormBuilderTextField(
            name: "observations",
            decoration: const InputDecoration(
              contentPadding:  EdgeInsets.symmetric(horizontal: 8),
              labelText: "Observaciones",
              
            ),
          );
  }

  FormBuilderDropdown<int> buildPaymentMethodField() {
    return FormBuilderDropdown(
            name: "payment_method",
            decoration: const InputDecoration(
              contentPadding:  EdgeInsets.symmetric(horizontal: 8),
              labelText: "Metodo de pago", 
              helperText: ""
            ),
            initialValue: 1,
            items: const [
              DropdownMenuItem(value: 2, child: Text("Transferencia")),
              DropdownMenuItem(value: 1, child: Text("Efectivo"))
            ]
          );
  }

  FormBuilderTextField buildAmountField() {
    return FormBuilderTextField(
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.numeric(errorText: "Monto invalido"),
            FormBuilderValidators.required(errorText: "Este campo es requerido")
          ]),
          name: "amount",
            decoration: const InputDecoration(
              contentPadding:  EdgeInsets.symmetric(horizontal: 8),
              labelText: "Monto",
              prefix: Text("\$"),
              helperText: ""

            ),
          );
  }

  FormBuilderDropdown<Subscription> buildSubscriptionField() {
    return FormBuilderDropdown(
            name: "subscription",
            decoration:const InputDecoration(
              contentPadding:  EdgeInsets.symmetric(horizontal: 8),
              labelText: "Subscripcion",
              helperText: ""
            ),
            items: subscriptions.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
            onChanged: (value) {
              
              if(value == null) return;

              formKey.currentState!.fields['amount']!.didChange(value.getCurrentPrice()?.price.toString());
            },
        
          );
  }
}