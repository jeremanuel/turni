import 'dart:math';

import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/presentation/styles/text_styles.dart';
import 'package:turni/data/repositories/auth_repository.dart';
import 'package:turni/domain/models/session.dart';

class SessionCard extends StatelessWidget {

  final Session session;
  const SessionCard({super.key, required this.session});

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
                          Text("\$ ${session.price.floor()}", style: const TextStyle(fontSize: 20)),
                          Text("\$${(session.price/ 4).floor()} c/u", style: const TextStyle(fontSize: 12)) // TODO aca es session.price / cantidad de personas del physical 
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
                            Text(session.duration)
                          ]),
                        const SizedBox(height: 5),
                        
                          const Row(
                            children: [
                             Icon(
                              Icons.person,
                              size: 18,
                            ),
                            Text("4") // TODO obtener personas de el physical partition.
                          ]),
                          const SizedBox(height: 5),
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
                          "${session.startTime.hour.toString().padLeft(2, '0')} : ${session.startTime.minute.toString().padLeft(2, '0')}",
                          style: TextStyles.h1,
                        ),
                        Text("Beduinos"), // Obtener nombre de el physical partition.
                    
                      ],
                    )),
                  );
  }
}