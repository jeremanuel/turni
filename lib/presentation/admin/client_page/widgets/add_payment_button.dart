
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/animation/splash_animation.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/payment/payment.dart';
import '../../../../domain/entities/subscription/subscription.dart';
import '../../../../domain/repositories/payment_repository.dart';
import '../../../core/cubit/auth/auth_cubit.dart';
import '../../../core/pick_client/pick_client.dart';

class AddPaymentButton extends StatefulWidget {

  const AddPaymentButton({super.key, required this.client, required this.onPaymentCreated, this.shortButton = false});

  final Function(Payment) onPaymentCreated;
  final Client? client;
  final bool shortButton;
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
        onCancel: () => dropdownController.hide?.call(),
        onPaymentCreated: (p0) {
          widget.onPaymentCreated.call(p0);
          Future.delayed(const Duration(seconds: 3)).then((value) => dropdownController.hide?.call());
        }), 
      dropdownController: dropdownController,
      child: buildButton(context)
    );
  }

  Widget buildButton(BuildContext context) {
    
    if(ResponsiveBuilder.isMobile(context) || widget.shortButton){
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

  final Client? client;
  final Function(Payment) onPaymentCreated;
  final Function() onCancel;
  
  const AddPaymentContainer({
    super.key, 
    required this.client, 
    required this.onPaymentCreated, 
    required this.onCancel,
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

  List<Subscription> subscriptions = [];

  @override
  void initState() {
    subscriptions = [...Set.from(widget.client?.clientSubscriptions?.map((e) => e.subscription)?? [])] ;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
      
          ListTile(
            title: Text("Nuevo pago", style: Theme.of(context).textTheme.titleLarge,),
          ),
           Divider(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1,
          ),
          const SizedBox(height: 24,),
          Portal(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  if(widget.client == null) 
                  PickClient(
                    name: "client", 
                    isRequired: true,
                     onChange: (client)  {
                      if(client == null) return;
                      
                      setState(() {
                        subscriptions = [...Set.from(client.clientSubscriptions?.map((e) => e.subscription)?? [])];
                      });
                     },
                    ),
                  const SizedBox(height: 12,),
                  Divider(height: 1,),
                  const SizedBox(height: 12,),
                  
                  buildSubscriptionField(),
                  buildAmountField(),
                  buildPaymentMethodField(),
                  buildObservationsField(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48,),
          Row(
            spacing: 4,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: widget.onCancel, child: const Text("Cancelar")),
              TextButton(
                onPressed: createPayment, 
                child: isCreatingPayment ? SizedBox(height: 24,width: 24, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2,)) : const Text("Crear Pago")
              ),
            ],
          ),
          const SizedBox(height: 16,)
        ],
      ),
    );
  }

  void createPayment() async {
              
                final currentFormState = formKey.currentState!;
              
                if(!currentFormState.validate()) return;
                  
                setState(() {
                  isCreatingPayment = true;
                });
              
                final instantValue = currentFormState.instantValue;
              
                final int? selectedSubscription = instantValue['subscription']?.subscriptionId;

                final client = widget.client ?? instantValue['client'] as Client;

             
              
                final result = await paymentRepository.createPayment({
                    "amount": double.parse(instantValue['amount']),
                    "payment_method_id": instantValue['payment_method'],
                    "observation": instantValue['observations'],
                    "client_subscription_id": client.clientSubscriptions?.firstWhereOrNull((element) => element.subscription.subscriptionId == selectedSubscription)?.clientSubscriptionId,
                    "client_id": int.tryParse(client.clientId ?? ''),
                    'client':client.copyWith(clubId: sl<AuthCubit>().getClubId()), 
                    "created_by_admin": sl<AuthCubit>().state.userCredential!.admin!.adminId
                  });
              
                switch (result) {
                  case Right(:final value):
                    widget.onPaymentCreated(value);
                  case Left(:final failure):
                    setState(() {
                      error = failure;
                      isCreatingPayment = false;
                    });
                }
              
                setState(() {
                  isCreatingPayment = false;
                  isPaymentCreated = true;
                });
              
                
              
                }

  FormBuilderTextField buildObservationsField() {
    return FormBuilderTextField(
            name: "observations",
            decoration: const InputDecoration(
              contentPadding:  EdgeInsets.symmetric(horizontal: 8),
              labelText: "Observaciones",
              border: OutlineInputBorder(),
            ),
          );
  }

  FormBuilderDropdown<int> buildPaymentMethodField() {
    return FormBuilderDropdown(
            name: "payment_method",
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
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
              border: OutlineInputBorder(),
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
              border: OutlineInputBorder(),
              fillColor: Colors.grey,
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