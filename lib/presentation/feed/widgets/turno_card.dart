import 'dart:math';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/presentation/styles/text_styles.dart';
import 'package:turni/data/repositories/auth_repository.dart';
import 'package:turni/domain/models/turno.dart';

class TurnoCard extends StatelessWidget {

  final Turno turno;
  const TurnoCard({super.key, required this.turno});

  @override
  Widget build(BuildContext context) {
    return Card(          
          child: InkWell(
            enableFeedback: true,
            onTap: (){ AuthRepository.signInGoogle(); },
            child:
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    buildColorContainer(),
                    buildGeneralInfo(), 
                    const Spacer(),
                    buildPriceInfo()
            ]),
          ),
        );
  }

  SizedBox buildPriceInfo() {
    return SizedBox(
                    height: 120,
                    child: Container(
                      decoration: DottedDecoration(
                          linePosition: LinePosition.left
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child:  Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("\$ ${turno.price.floor()}", style: TextStyle(fontSize: 20)),
                          Text("\$${(turno.price/turno.persons).floor()} c/u", style: TextStyle(fontSize: 12))
                        ],
                      ),
                    ),
                  );
  }

  Container buildGeneralInfo() {
    return Container(
                    width:165,
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(
                              Icons.timer_sharp,
                              size: 18,
                            ),
                            Text(turno.duration)
                          ]),
                        const SizedBox(height: 5),
                        
                          Row(
                            children: [
                            const Icon(
                              Icons.person,
                              size: 18,
                            ),
                            Text(turno.persons.toString())
                          ]),
                          const SizedBox(height: 5),
                          Text(turno.place.courtDescription, overflow: TextOverflow.ellipsis, maxLines: 2,)
                        ]),
                  );
  }

  Container buildColorContainer() {
    return Container(
                    color: Colors.amber,
                    height: 120,
                    width: 120,
                    child: Center(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          turno.startAt.hour.toString().padLeft(2, '0') + ":" + turno.startAt.minute.toString().padLeft(2, '0'),
                          style: TextStyles.h1,
                        ),
                        Text(turno.place.name),
                        if(turno.place.photo != "")
                          CircleAvatar(
                            radius: 16,
                            child: ClipRect(child: Image.network(turno.place.photo), ),
                          )
                      ],
                    )),
                  );
  }
}