
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/date_functions.dart';
import '../../../../domain/entities/subscription/client_subscription.dart';
import '../../../../domain/repositories/subscription_repository.dart';
import '../client_page.dart';
import 'subscriptions_container/add_subscription_button.dart';

class SubscriptionContainer extends StatefulWidget {

  const SubscriptionContainer({super.key});

  @override
  State<SubscriptionContainer> createState() => _SubscriptionContainerState();
}

class _SubscriptionContainerState extends State<SubscriptionContainer> {

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    
    final textTheme = Theme.of(context).textTheme;
    final client = ClientInherited.of(context)!.client;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Subscripciones", style: textTheme.headlineSmall),
              const Spacer(),
              AddSubscriptionButton(client:client)
            ],
          ),
          const SizedBox(height: 24,),
          if(client.clientSubscriptions == null || client.clientSubscriptions!.isEmpty) const Text("El cliente no tiene subscripciones cargadas")
          else SizedBox(
            height: 152,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              controller: scrollController,
              itemCount: client.clientSubscriptions?.length ?? 0,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return SubscriptionCard(clientSubscription: client.clientSubscriptions![index]);
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8)
            ),
          )
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.clientSubscription,
    this.compact = false,
  });

  final ClientSubscription clientSubscription;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Container(
        decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: colorScheme.outline.withOpacity(0.5))
    ),
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
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                Text("Subcription activa", style: textTheme.titleMedium,),
                Spacer(),
                     if (clientSubscription.isActive) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.cancel, size: 20),
                    tooltip: "Cancelar suscripción",
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (innerContext) {
                          return AlertDialog(
                            title: const Text("Cancelar subscripcion"),
                            content: const Text("¿Estas seguro que deseas cancelar la subscripcion?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(innerContext);
                                },
                                child: const Text("No"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final client = ClientInherited.of(context)!.client;
                                  
                                  await sl<SubscriptionRepository>().unSubscribeClient(
                                    clientSubscription.clientSubscriptionId,
                                    client.intClientId,
                                  );

                                  ClientInherited.of(context)!.updateClient(
                                    client.copyWith(
                                      clientSubscriptions: client.clientSubscriptions!
                                          .map((e) => e.clientSubscriptionId == clientSubscription.clientSubscriptionId
                                              ? e.copyWith(endDate: DateTime.now())
                                              : e)
                                          .toList(),
                                    ),
                                  );
                                  Navigator.pop(innerContext);
                                },
                                child: const Text("Si"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ]
            ),
            SizedBox(height: 12,),
            Row(
              children: [
                Icon(
                  Icons.fitness_center_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  clientSubscription.subscription.name,
                  style: textTheme.titleMedium
                ),

           
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text("Creada"),
                Text(" hace ${DateFunctions.differencePretty(clientSubscription.startDate)}"),
              ],
            ),
            
            
          ],
        ),
      );
    }

    return Container(
    width: 240,
    height: 120,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      border: clientSubscription.isActive ? Border.all(color: colorScheme.primary) : null
    ),
    child: Stack(
      children: [
        
        if(clientSubscription.isActive)
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: (){
                showDialog(
                  context: context, 
                  builder: (innterContext) {
                    return AlertDialog(
                      title: const Text("Cancelar subscripcion"),
                      content: const Text("¿Estas seguro que deseas cancelar la subscripcion?"),
                      actions: [
                        TextButton(
                          onPressed: (){
                            Navigator.pop(innterContext);
                          }, 
                          child: const Text("No")),
                        TextButton(
                          onPressed: () async {

                            final client = ClientInherited.of(context)!.client;
                            
                            await sl<SubscriptionRepository>().unSubscribeClient(clientSubscription.clientSubscriptionId, client.intClientId);

                            ClientInherited.of(context)!.updateClient(client.copyWith(clientSubscriptions: client.clientSubscriptions!.map((e) => e.clientSubscriptionId == clientSubscription.clientSubscriptionId ? e.copyWith(endDate: DateTime.now()) : e).toList()));
                            context.pop();
                          }, 
                          child: const Text("Si")),
                      ],
                    );
                  },
                );
              }, 
              icon: const Icon(Icons.cancel), 
              tooltip: "Cancelar subscripcion",
            )
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const SizedBox(height: 2),
              Row(
                spacing: 4,
                children:[
                   const Icon(Icons.fitness_center_rounded),
                   Text("GYM", style: Theme.of(context).textTheme.titleMedium,)
                ]),
              Text(clientSubscription.subscription.name, style: Theme.of(context).textTheme.bodyLarge,),
              Row(
                spacing: 4,
                children: [
                  Text(DateFunctions.formatDateToDefaultFormat(clientSubscription.startDate), style: Theme.of(context).textTheme.bodyLarge,),
                  const Text(" - "),
                  if(clientSubscription.isActive) Text("Activa", style: Theme.of(context).textTheme.bodyLarge,)
                  else Text(DateFunctions.formatDateToDefaultFormat(clientSubscription.endDate!), style: Theme.of(context).textTheme.bodyLarge,),

                ]
              ),      
            ]
            ),
        ),
      ],
    ),
    );
  }
}


