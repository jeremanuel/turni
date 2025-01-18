
import 'package:flutter/material.dart';

import '../../../../core/presentation/components/inputs/LabelChip.dart';
import '../client_page.dart';

class LabelsContainer extends StatelessWidget {
  const LabelsContainer({
    super.key,
  });


  @override
  Widget build(BuildContext context) {

 
    final textTheme = Theme.of(context).textTheme;

    final client = ClientInherited.of(context)!.client;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
                Row(
                  spacing: 4,
                  children: [
                    Text("Etiquetas", style: textTheme.headlineSmall,),
                    const Icon(Icons.info_outlined, size: 18,)
                  ],
                ),
                const SizedBox(height: 24,),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if(client.labels != null && client.labels!.isNotEmpty) ...client.labels!.map((e) => Labelchip(e),)
                    else const Text("No hay etiquetas cargadas"),
                    SizedBox(
                      width: 200,
                      child: TextButton(onPressed: (){}, child: Row(spacing: 4 ,children: [Icon(Icons.add),const Text("Agregar etiqueta",)],),  ))
                  ],
                )
      ],
    );
    
  }
}

