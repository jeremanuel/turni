
import 'package:flutter/material.dart';

import '../client_page.dart';

class BasicDataContainer extends StatelessWidget {
  const BasicDataContainer({
    super.key,
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {

    final client = ClientInherited.of(context)!.client;

    return Container(
      
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius:const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Text(client.person!.fullName, style: Theme.of(context).textTheme.titleLarge,),
              Spacer(),
              IconButton(onPressed: (){}, icon: Icon(Icons.edit))
            ],
          ),
          const SizedBox(height: 15,),
          if(client.person?.email != null)
          Row(
            spacing: 4,
            children: [
              Text("Email: ", style: Theme.of(context).textTheme.labelLarge,),
              Text(client.person!.email!, style: Theme.of(context).textTheme.bodyLarge),
            ]
          ),
          if(client.person?.phone != null)
          Row(
            spacing: 4,
            children: [
              Text("Telefono: ", style: Theme.of(context).textTheme.labelLarge),
              Text(client.person!.phone!, style: Theme.of(context).textTheme.bodyLarge),
            ]
          ),
          Row(
            spacing: 4,
            children: [
              Text("Creado: ", style: Theme.of(context).textTheme.labelLarge,),
              Text("01/05/2023", style: Theme.of(context).textTheme.bodyLarge),
            ]
          ),
          Row(
            spacing: 4,
            children: [
              Text("Edad: ", style: Theme.of(context).textTheme.labelLarge,),
              Text("25 años", style: Theme.of(context).textTheme.bodyLarge),
            ]
          ),
          SizedBox(height: 4,),
          Text("Sin observaciones", style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
