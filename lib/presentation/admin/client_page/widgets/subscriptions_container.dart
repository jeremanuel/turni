
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
                return _SubscriptionCard(clientSubscription: client.clientSubscriptions![index]);
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8)
            ),
          )
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    required this.clientSubscription,
  });

  final ClientSubscription clientSubscription;

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
    width: 200,
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


