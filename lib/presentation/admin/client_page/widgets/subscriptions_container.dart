
import 'package:flutter/material.dart';

import '../../../../core/utils/date_functions.dart';
import '../../../../domain/entities/subscription/client_subscription.dart';
import '../client_page.dart';

class SubscriptionContainer extends StatelessWidget {
  const SubscriptionContainer({super.key});

  @override
  Widget build(BuildContext context) {
    
    final textTheme = Theme.of(context).textTheme;
    final client = ClientInherited.of(context)!.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Subscripciones", style: textTheme.headlineSmall),
        const SizedBox(height: 24,),
        if(client.clientSubscriptions == null || client.clientSubscriptions!.isEmpty) const Text("El cliente no tiene subscripciones cargadas")
        else SizedBox(
          height: 120,
          child: ListView.separated(
            itemCount: client.clientSubscriptions?.length ?? 0,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              return _SubscriptionCard(clientSubscription: client.clientSubscriptions![index]);
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8)
            ,
            
          ),
        )
      ],
    );
  }
}


class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({
    super.key, required this.clientSubscription,
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
            child: IconButton(onPressed: (){}, icon: Icon(Icons.cancel), tooltip: "Cancelar subscripcion",)
          ),
        Column(
          spacing: 8,
          children: [
            const SizedBox(height: 2,),
            Text(clientSubscription.subscription.name, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Text("Inicio: ", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),),
                Text(DateFunctions.formatDateToDefaultFormat(clientSubscription.startDate), style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),),
              ]
            ),
            if(!clientSubscription.isActive)
             Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Text("Fin: ", style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),),
                Text(DateFunctions.formatDateToDefaultFormat(clientSubscription.endDate!), style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),),
              ]
            ),           
        
          ]
          ),
      ],
    ),
    );
  }
}


