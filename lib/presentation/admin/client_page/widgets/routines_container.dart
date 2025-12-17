import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/routine/routine.dart';
import '../../../../domain/repositories/routine_repository.dart';
import '../../routines/widgets/routine_card.dart';
import '../client_page.dart';

class RoutinesContainer extends StatefulWidget {
  const RoutinesContainer({super.key});

  @override
  State<RoutinesContainer> createState() => _RoutinesContainerState();
}

class _RoutinesContainerState extends State<RoutinesContainer> {

  final List<Routine> routines = [];

  @override
  void initState() {
    loadMockUpRoutines();
    super.initState();
  }

  void loadMockUpRoutines(){
    sl<RoutineRepository>().getLastRoutines().then((result) {
      switch (result) {
        case Right(value: final data):
          setState(() {
            routines.clear();
            routines.addAll(data);
          });
        case Left(failure: final error):
          //Handle error
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    final client = ClientInherited.of(context)!.client;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 450,
          child: Row(
            children: [
              Text("Rutinas", style: textTheme.headlineSmall),
              const Spacer(),
                FilledButton(
                  style:ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(colorScheme.primaryContainer),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  onPressed: () {
                    context.goNamed(
                      AppRoutes.NEW_ROUTINE_ROUTE.name,
                      pathParameters: {'clientId': client.clientId.toString()},
                      extra: {'client': client,}
                    );
                  }, child:  Text("Nueva rutina", style:  TextStyle(color: colorScheme.onPrimaryContainer),)),
            ],
          ),
        ),
        const SizedBox(height: 18,),
        if(routines.isEmpty) const Text("El cliente no tiene rutina cargada")
        else SizedBox(
                width: 450,
                child: RoutineCard(routine: routines.first))
      ],
    );
  }
}