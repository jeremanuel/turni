import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/payment/payment.dart';
import 'widgets/add_payment_button.dart';
import 'widgets/basic_data_container.dart';
import 'widgets/labels_container.dart';
import 'widgets/payments/payments_list.dart';
import 'widgets/subscriptions_container.dart';

class Clientpage extends StatefulWidget {
  const Clientpage({
    super.key,
    required this.clientId,
    this.client
  });


  final int clientId;
  final Client? client;

  @override
  State<Clientpage> createState() => _ClientpageState();
}

class _ClientpageState extends State<Clientpage> {


  Client? client;

  @override
  void initState()  {

    client = widget.client;
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    

    final colorScheme = Theme.of(context).colorScheme;

    if(client == null) return const Center(child: Text("No pudo cargar los datos del cliente"));

    return Portal(
      child: ClientInherited(
        client: client!,
        child: Container(
          color: colorScheme.surfaceContainer,
          width: 700,
          child: ListView(
            children: [
              BasicDataContainer(colorScheme: colorScheme),
              const SizedBox(height: 24,),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 24,),
                    PaymentsContainer(),
                    SubscriptionContainer(),
                    SizedBox(height: 24,),
                    LabelsContainer(),
                    SizedBox(height: 24,)
        
        
            ],
          ),)])
        
        ),
      ),
    );
  }
}

class PaymentsContainer extends StatefulWidget {
  const PaymentsContainer({super.key});

  @override
  State<PaymentsContainer> createState() => _PaymentsContainerState();
}

class _PaymentsContainerState extends State<PaymentsContainer> {

  String? alertMessage;
  String? infoMessage;


  setAlertBasedOnLastPayment(Payment? payment){
    final now = DateTime.now();

    if(payment == null) return;

    final differenceInDaysFromLastPayment = now.difference(payment.paymentDate).inDays;

    if(differenceInDaysFromLastPayment > 30){
      setState(() {
        alertMessage = "$differenceInDaysFromLastPayment desde el ultimo pago";
        infoMessage = null;
      });
    } else {
      setState(() {
        infoMessage = "$differenceInDaysFromLastPayment desde el ultimo pago";
        alertMessage = null;
      });     
    }
    
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final client = ClientInherited.of(context)!.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Pagos",
              style: textTheme.headlineSmall,
            ),
            const Spacer(),
            if(alertMessage != null || infoMessage != null)
            Chip(
              label:  Text(alertMessage ?? infoMessage!, style: const TextStyle(color:Colors.white )),
              backgroundColor: getMessageColor(),
              visualDensity:  const VisualDensity(vertical: -4),
              side: BorderSide.none,
            ),
            const SizedBox(width: 8,),
            const AddPaymentButton(),
            //TextButton(onPressed: (){}, child: Row(children: [ Icon(Icons.add), SizedBox(width: 8,) ,Text("Registrar nuevo pago") ],)),

          ],
        ),
        const SizedBox(height: 16),
        SizedBox(height: 360, child: Paymentslist(clientId: int.parse(client.clientId!,), onPaymentsLoad: setAlertBasedOnLastPayment,)),
      ],
    );
  }

  dynamic getMessageColor() {

    if(alertMessage != null) return const Color.fromARGB(255, 189, 44, 44);

    

    return const Color.fromARGB(255, 114, 155, 111);
  }
}

class ClientInherited extends InheritedWidget {

  final Client client;

  const ClientInherited({super.key, required super.child, required this.client});

  static ClientInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientInherited>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return oldWidget is ClientInherited && oldWidget.client != client;
  }

}