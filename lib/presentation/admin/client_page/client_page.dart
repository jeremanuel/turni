import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../clients_list/bloc/clients_list_bloc.dart';
import 'widgets/add_payment_button.dart';
import 'widgets/basic_data_container.dart';
import 'widgets/labels_container.dart';
import 'widgets/payments/payments_list.dart';
import 'widgets/subscriptions_container.dart';

class Clientpage extends StatefulWidget {
    const Clientpage({
      super.key, 
      required this.clientId,
      this.createNewClient = false,
      this.client, required this.onUpdateClient
  });



  final int clientId;
  final Client? client;
  final bool createNewClient;
  final Function(Client) onUpdateClient;

  @override
  State<Clientpage> createState() => _ClientpageState();
}

class _ClientpageState extends State<Clientpage> {


  Client? client;
  bool isEditingMode = false;

  @override
  void initState()  { 
    isEditingMode = widget.createNewClient;
    client = widget.client;
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    

    final colorScheme = Theme.of(context).colorScheme;

    if(client == null && isEditingMode){
      return buildNewClientMode(colorScheme);
    }

    if(client == null) return const Center(child: Text("No pudo cargar los datos del cliente"));

    return Portal(
          child: ClientInherited(
              (newClient) => setState(() {client = newClient; widget.onUpdateClient(newClient); context.read<ClientsListBloc>().state.dataSource.loadPage(context.read<ClientsListBloc>().state.dataSource.currentPage); }),
              client: client!,
              child: Container(
                color: colorScheme.surfaceContainer,
                width: 700,
                child: Builder(
                  builder: (context) {
        
                    return ListView(
                      children: [
                        BasicDataContainer(colorScheme: colorScheme, onToggleEditing: (c) => setState(() { isEditingMode = !isEditingMode;  }), isEditing: isEditingMode,),
                        const SizedBox(height: 24),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 24),
                              PaymentsContainer(),
                              SubscriptionContainer(),
                              SizedBox(height: 24),
                              LabelsContainer(),
                              SizedBox(height: 24)
                      ],
                    ),) ]);
                  }
                )
              
              ),
            ),
        );
  }

  Portal buildNewClientMode(ColorScheme colorScheme) {
    return Portal(
      child: Container(
            color: colorScheme.surfaceContainer,
            width: 700,
            child: Column(
              children: [
                BasicDataContainer(colorScheme: colorScheme, onToggleEditing: onNewClient, isEditing: isEditingMode,),
                const Expanded(child: Center(child: Text("Guarde los datos basicos para poder cargar informacion avanzada")))
              ],
            )
      ),
    );
  }

  onNewClient(c){ 
    
    setState(() { 
      client = c; isEditingMode = false;
    });

    context.read<ClientsListBloc>().state.dataSource.loadPage(context.read<ClientsListBloc>().state.dataSource.currentPage);
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
  PaymentsDataSource? paymentDataSource;


  setAlertBasedOnLastPayment(Payment? payment){
    final now = DateTime.now();

    if(payment == null) return;

    final differenceInDaysFromLastPayment = now.difference(payment.paymentDate).inDays;

    if(differenceInDaysFromLastPayment < 30) {
      return setState(() {
         infoMessage = "Pago al dia";
         alertMessage = null;
      });
    }

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
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      paymentDataSource = PaymentsDataSource(
        int.parse(ClientInherited.of(context)!.client.clientId!),
        setAlertBasedOnLastPayment,
        paymentRepository: sl<PaymentRepository>()
      );
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(paymentDataSource == null) return const SizedBox();

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
              label: Text(alertMessage ?? infoMessage!, style: const TextStyle(color:Colors.white )),
              backgroundColor: getMessageColor(),
              visualDensity:  const VisualDensity(vertical: -4),
              side: BorderSide.none,
            ),
            const SizedBox(width: 8,),
            AddPaymentButton(
              client: client, 
              onPaymentCreated: (p0) => paymentDataSource!.refreshDatasource()              
            )
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(height: 360, child: Paymentslist(clientId: int.parse(client.clientId!), onPaymentsLoad: setAlertBasedOnLastPayment, paymentDataSource: paymentDataSource!,)),
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
  final Function(Client) updateClient;

  const ClientInherited(this.updateClient, {super.key, required super.child, required this.client});

  static ClientInherited? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientInherited>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    final value = oldWidget is ClientInherited && oldWidget.client != client;
    return value;
  }





}