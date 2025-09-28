import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/responsive_builder.dart';
import '../../../../../core/utils/types/time_interval.dart';
import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/payment/payment.dart';
import '../../../../../domain/entities/payment/payment_method.dart';
import '../../../../../domain/entities/physical_partition.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../core/pick_client/pick_client.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/activity_container.dart';
import 'widgets/payment_container.dart';

class SessionInfo extends StatefulWidget {

  const SessionInfo({super.key, required this.session, required this.physicalPartition, required this.clubPartition});


  final Session session;
  final PhysicalPartition physicalPartition;
  final ClubPartition clubPartition;

  @override
  State<SessionInfo> createState() => _SessionInfoState();
}

class _SessionInfoState extends State<SessionInfo> {

  bool isValid = false;
  bool isLoadingSession = false;
  var _formKey = GlobalKey<FormBuilderState>();
  late Session session;

  @override
  void initState() {

    session = widget.session.copyWith(price: 20000);
    
    super.initState();
  }

  

  @override
  void didUpdateWidget(covariant SessionInfo oldWidget) {
    if(widget.session.sessionId != oldWidget.session.sessionId){
      setState(() {
        _formKey = GlobalKey<FormBuilderState>();
      });

    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {

  final timeInterval = TimeInterval(initialDate: widget.session.startTime,endDate: widget.session.endTime);
  final colorScheme = Theme.of(context).colorScheme;

    return FormBuilder(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _formKey,
      onChanged: (){
        
        setState(() {
          isValid = _formKey.currentState!.validate(focusOnInvalid: false);
        });
    
      },
      child: Column(
        children: [          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildHeader(context),
                  const SizedBox(height: 32),
                  Wrap(
                    runSpacing: 8,
                    spacing: 8,
                    children: [
                      Chip(
                        avatar: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.onSurfaceVariant,), 
                        label: Text(timeInterval.getInitialTextString())
                      ),
                      Chip(
                        avatar: Icon(Icons.access_time, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        label: Text(timeInterval.toStringTime())
                      ),
                      Chip(
                        label: Text(widget.clubPartition.clubType!.name)
                      ),
                      Chip(
                        avatar: Icon(Icons.place, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          label: Text("Cancha ${widget.physicalPartition.physicalIdentifier}")
                      ),
                      Chip(
                        avatar: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          label: Text("${widget.session.price}")
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  PickClient(
                    initialValue: widget.session.client,
                    readOnly: widget.session.client != null,
                    name: "client",
                    isRequired:true,
                  ),
                  if(widget.session.isReserved) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    PaymentContainer(
                      session: session,
                      onExtraAdded: (extra, payed) {
                        setState(() {
                          session = session.copyWith(
                            extras: [...?session.extras, extra],
                          );
                        });
                        print(session.extras);
                      },
                      onPaymentAdded: (payment) {
                        setState(() {
                          session = session.copyWith(
                            payments: [...?session.payments, payment]
                          );
                        });
                      },
                      onExtrasPayed: (extras) {
                        setState(() {
                          session = session.copyWith(
                            extras: session.extras?.map((e) {
                              if(extras.contains(e)) {
                                return e.copyWith(payment: Payment.fromExtra(amount: e.amount, method: PaymentMethod(paymentMethodId: 1, name: "Efectivo")));
                              }
                              return e;
                            }).toList()
                          );
                        });
                      },
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    const ActivityContainer(),        
                    const SizedBox(height: 16),
                    const TextField(
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Observaciones", 
                        border: OutlineInputBorder()
                      ),
                    ),
                    const SizedBox(height: 16),      
                  ]
    
               
                  
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: (){} , child:  Text(widget.session.isReserved ? "Cancelar Reserva" : "Eliminar Turno")),
              if(!widget.session.isReserved)
                FilledButton(
                  onPressed: isValid ? (){
                      
                  final sessionManagerBloc = context.read<SessionManagerBloc>();
                  
                  final client = _formKey.currentState!.fields['client']?.value;
                
                  sessionManagerBloc.add(
                    ReserveEvent(widget.session, client)
                  );  
                      
                  context.go("/session_manager");
                          } : null,
                  child: const Text("Reservar Turno")
                ),
            ],
          )
        ],
      ),
    );
  }

Stack buildHeader(BuildContext context) {
  final timeInterval = TimeInterval(initialDate: widget.session.startTime,endDate: widget.session.endTime);
  final textTheme = Theme.of(context).textTheme;
  return Stack(
    children: [
      SizedBox(
        height: 64,
        width: ResponsiveBuilder.isDesktop(context) ? 300 : double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Datos del Turno", style: textTheme.headlineSmall,),
/*             Text("${timeInterval.getInitialTextString()} | ${timeInterval.toStringTime()}", style: textTheme.bodyLarge),
 */
          ],
        ),
      ),
      SizedBox(
        height: 64,
        child: IconButton(
          onPressed: (){
            context.go("/session_manager");
          }, 
          icon: const Icon(Icons.arrow_back)
        ),
      ) 
      
    ],
  );
}
}
