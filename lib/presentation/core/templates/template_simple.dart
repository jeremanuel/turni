import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../../../core/presentation/components/inputs/text_fields/custom_text_field.dart';

class TemplateSimple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: [
          Column(
            children: [
              _turnsGenerator(context),
              _turnCreator(context),
            ],
          ),
          Container()
        ],
      ),
    );
  }

  _turnsGenerator(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
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
            Container(
              child: CustomTextField(
                context,
                labelText: 'Inicio - Fin',
              ),
            ),
            SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: Icon(Icons.add),
              onPressed: () {},
            ),
            Spacer(),
            Container(
              width: 100,
              child: CustomTextField(context, labelText: 'Precio'),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Container(
                  width: 100,
                  child: CustomTextField(context, labelText: 'Duración'),
                ),
                Spacer(),
                ElevatedButton(
                  child: Text('Generar'),
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
      padding: EdgeInsets.all(10),
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
                Container(
                  width: 100,
                  child: CustomTextField(context, labelText: 'Inicio'),
                ),
                Spacer(),
                Container(
                  width: 100,
                  child: CustomTextField(context, labelText: 'Fin'),
                ),
              ],
            ),
            Row(
              children: [],
            )
          ],
        ),
      ),
    );
  }
}
