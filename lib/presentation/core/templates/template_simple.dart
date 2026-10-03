import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../core/presentation/components/inputs/text_fields/custom_text_field.dart';

class TemplateSimple extends StatelessWidget {
  const TemplateSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
        children: [
          Column(
            children: [
              _turnsGenerator(context),
              _turnCreator(context),
            ],
          ),
          Container()
        ],
      );
  }

  _turnsGenerator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FormBuilder(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
                context,
                labelText: 'Inicio - Fin',
              ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: const Icon(Icons.add),
              onPressed: () {},
            ),
            const Spacer(),
            SizedBox(
              width: 100,
              child: CustomTextField(context, labelText: 'Precio'),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: CustomTextField(context, labelText: 'Duración'),
                ),
                const Spacer(),
                ElevatedButton(
                  child: const Text('Generar'),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _turnCreator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: FormBuilder(
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: CustomTextField(context, labelText: 'Inicio'),
                ),
                const Spacer(),
                SizedBox(
                  width: 100,
                  child: CustomTextField(context, labelText: 'Fin'),
                ),
              ],
            ),
            const Row(
              
            )
          ],
        ),
      ),
    );
  }
}
