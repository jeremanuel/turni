import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trina_grid/trina_grid.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/date_functions.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/entities/payment/payment.dart';
import '../../../domain/entities/subscription/client_subscription.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../client_feature/wrapper_client_provider.dart';
import 'widgets/add_payment_button.dart';
import 'widgets/basic_data_container.dart';
import 'widgets/labels_container.dart';
import 'widgets/payments/payments_list.dart';
import 'widgets/routines_container.dart';
import 'widgets/subscriptions_container.dart';
import 'widgets/subscriptions_container/add_subscription_button.dart';

export 'widgets/subscriptions_container.dart' show SubscriptionCard;

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


  bool isEditingMode = false;
  bool loadingClient = false;
  
  @override
  void initState()  { 
    isEditingMode = widget.createNewClient;
    super.initState();
  }


  void _onUpdateClient( Client newClient){
    setState(() {
      widget.onUpdateClient(newClient);
      // context.read<ClientsListBloc>().refetchClients();  TODO: Parametrizar
    });
  }

  @override
  Widget build(BuildContext context) {
    

    final colorScheme = Theme.of(context).colorScheme;

    if(widget.clientId == -1 && isEditingMode){
      return buildScaffold(context, buildNewClientMode(colorScheme));
    }

    

    return WrapperClientProvider(
      clientId: widget.clientId,
      onUpdateClient: _onUpdateClient,
            client: widget.client,
      child: buildScaffold(context, Container(
              color: colorScheme.surfaceContainer,
              child: Builder(
                builder: (context) {
                  final client = ClientInherited.of(context)!.client;

                  if(ResponsiveBuilder.isDesktop(context)) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 24,
                                children: [
                                Expanded(
                                    flex: 2,
                                    child: BasicDataContainer(
                                      colorScheme: colorScheme,
                                      onToggleEditing: (c) => setState(() {
                                        isEditingMode = !isEditingMode;
                                    }),
                                    isEditing: isEditingMode,
                                  ),
                                ), 
                                
                                  SizedBox(
                                    width: 450,
                                    child: _ActiveSubscriptionWidget(client: client),
                                  ),
                              ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                            const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  height: 450,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    spacing: 16,
                                    children: [
                                      Expanded(flex: 2, child: PaymentsContainer()),
                                      SizedBox(
                                        width: 8,
                                  
                                      
                                      ),
                                      RoutinesContainer(),
                                      
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  width: 450,
                                  child: LabelsContainer())
                                 
                            
                      
                            
                              ],
                            ),
                          ),

                        ],
                      ),
                    );
                  }

                  return buildMobileBody(colorScheme, context, client);
                }
              )
            
            )),
    );
  }

  ListView buildMobileBody(ColorScheme colorScheme, BuildContext context, Client client) {
    return ListView(
                  children: [
                    BasicDataContainer(colorScheme: colorScheme, onToggleEditing: (c) => setState(() { isEditingMode = !isEditingMode;  }), isEditing: isEditingMode,),
                    const SizedBox(height: 24),
                     Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ActiveSubscriptionWidget(client: client),
                          const SizedBox(height: 24),
                          const SizedBox(
                            height: 400,
                            child: PaymentsContainer(),
                          ),
                          const SizedBox(height: 24),
                          const SizedBox(
                            height: 400,
                            child: RoutinesContainer(),
                          ),
                          const SizedBox(height: 24),
                          const LabelsContainer(),
                          const SizedBox(height: 24)
                  ],
                ),) ]);
  }

  Widget buildScaffold(BuildContext context, Widget child){
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainer,
        title: Builder(
          builder: (context) {
            return buildBreadcrumb(context);
          }
        ),
      ),
    );

  }

  void toggleEditing(){
    setState(() { isEditingMode = !isEditingMode;  });
  }

  Widget buildBreadcrumb(BuildContext context){
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final clientInherited = ClientInherited.of(context);
    
    return Row(
      children: [
        // Botón de regreso
     
        const SizedBox(width: 8),
        // Breadcrumb
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Clientes
                InkWell(
                  onTap: () => context.pop(),
                  child: Text(
                    'Clientes',
                    style: textTheme.bodyLarge
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: colorScheme.onPrimaryContainer.withOpacity(0.5),
                  ),
                ),
                // Nombre del cliente o estado de edición
                if (isEditingMode && clientInherited == null)
                  Text(
                    'Nuevo cliente',
                    style: textTheme.bodyLarge
                  )
                else if (isEditingMode)
                  Text(
                    'Editando',
                    style: textTheme.bodyLarge
                  )
                else
                  Text(
                    'Cliente',
                    style: textTheme.bodyLarge
                  ),
              ],
            ),
          ),
        ),
        // Botón de edición
     
      ],
    );
  }



  Container buildNewClientMode(ColorScheme colorScheme) {
    return Container(
          color: colorScheme.surfaceContainer,
          width: 700,
          child: Column(
            children: [
              BasicDataContainer(colorScheme: colorScheme, onToggleEditing: onNewClient, isEditing: isEditingMode,),
              const Expanded(child: Center(child: Text("Guarde los datos basicos para poder cargar informacion avanzada")))
            ],
          )
    );
  }

  void onNewClient(Client c){ 
    
    setState(() { 
      isEditingMode = false;
      ClientInherited.of(context)!.updateClient(c);
    });

   // context.read<ClientsListBloc>().refetchClients();
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
  PaymentRepository? paymentRepository;
  TrinaGridStateManager? stateManager;


  void setAlertBasedOnLastPayment(Payment? payment){
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
      paymentRepository = sl<PaymentRepository>();
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    if(paymentRepository == null) return const SizedBox();

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final client = ClientInherited.of(context)!.client;

    return Container(
      
      padding: const EdgeInsets.all(20),
      child: Column(
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
            Row(
              spacing: 8,
              children: [
                Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: getMessageColor(),
                  shape: BoxShape.circle,
                ),
              ),
              Text(alertMessage ?? infoMessage!, style: const TextStyle(color:Colors.white ))
              ],
           
            ),
            const SizedBox(width: 16,),
            AddPaymentButton(
              client: client, 
              onPaymentCreated: (p0){
                stateManager!.setFilter((element) => true);
              }             
            )
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Paymentslist(
            clientId: int.parse(client.clientId!), 
            onPaymentsLoad: setAlertBasedOnLastPayment, 
            paymentRepository: paymentRepository!, 
            onLoaded: (event) => setState(() {
              stateManager = event.stateManager;
             
            }),
          )
        ),
      ],
      ),
    );
  }

  dynamic getMessageColor() {

    if(alertMessage != null) return const Color.fromARGB(255, 189, 126, 44);

    return const Color.fromARGB(255, 114, 155, 111);
  }
}

class _ActiveSubscriptionWidget extends StatelessWidget {
  const _ActiveSubscriptionWidget({
    required this.client,
  });

  final Client client;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Obtener la suscripción activa
    final activeSubscription = client.clientSubscriptions?.firstWhereOrNull(
      (sub) => sub.isActive,
    );

    final hasActiveSubscription = activeSubscription != null && 
                                   activeSubscription.clientSubscriptionId != -1;

    if (!hasActiveSubscription) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: 8,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  "No hay suscripción activa",
                  style: textTheme.bodyLarge,
                )
              ],
            ),
            const SizedBox(height: 16),
            AddSubscriptionButton(client: client),
          ],
        ),
      );
    }

    return SubscriptionCard(
      clientSubscription: activeSubscription!,
      compact: true,
    );
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