import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/repositories/routine_repository.dart';
import '../client_feature/wrapper_client_provider.dart';
import 'cubit/new_routine_cubit.dart';
import 'pages/previous_routines.dart';
import 'widgets/routine_group.dart';

class NewRoutinePage extends StatefulWidget {
  final Client? client;
  final int clientId;
  const NewRoutinePage({super.key, this.client, required this.clientId});


  @override
  State<NewRoutinePage> createState() => _NewRoutinePageState();
}

class _NewRoutinePageState extends State<NewRoutinePage> with TickerProviderStateMixin  {
  late final TabController tabControllerDesktop;
  late final TabController tabControllerMobile;


  @override
  void initState() {
    super.initState();
    
    tabControllerDesktop = TabController(length: 2, vsync: this);
    tabControllerMobile = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final isMobile = ResponsiveBuilder.isMobile(context);


    return WrapperClientProvider(
      clientId: widget.clientId,
      onUpdateClient: (client) {
        //client = client;
      },
      client: widget.client,
      child: BlocProvider<NewRoutineCubit>(
        create: (context) => NewRoutineCubit(sl<RoutineRepository>(), widget.clientId),
        child: buildScaffold(
          context,
          child: Container(
              width: 900,
              padding: isMobile ? null : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              color: colorScheme.surfaceContainer,
              child: Builder(
                builder: (context) {
          
                  if(isMobile) {
                    return Column(
                      children: [
                        TabBar(    
                          controller: tabControllerMobile,
                          tabs:[
                            const Tab(text: "Nueva",),
                            const Tab(text: "Anteriores",),
                            const Tab(text: "Ultimas creadas",),
                          
                            
                          ],
                        ),
                      Expanded(
                    child: TabBarView(
                      controller: tabControllerMobile,
                      children: [
                      buildNewRoutineBody(context, colorScheme),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: PreviousRoutines(),
                      ),
                      const Center(child: Text("Aquí va la vista previa2")),
                    ]),
                  )
                              
                    ],
                    );
                  }
          
                  return Row(
                    children: [
                      buildNewRoutineBody(context, colorScheme),
                      const VerticalDivider(),
                      Expanded(
                        child: Column(
                          children: [
                            TabBar(
                              
                              controller: tabControllerDesktop,
                              tabs:[
                                const Tab(text: "Anteriores",),
                                const Tab(text: "Ultimas creadas",),
                              
                                
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: tabControllerDesktop,
                                children: [
                                const PreviousRoutines(),
                                const Center(child: Text("Aquí va la vista previa2")),
                              ]),
                            )
                          ],
                        )
                      )
                    ],
                  );
                }
              )),
        ),
      ),
    );
  }

  Widget buildScaffold(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    if(ResponsiveBuilder.isDesktop(context)) return child;

    return Scaffold(
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Acción para guardar la rutina
          },
          child: const Text("Guardar Rutina"),
        ),
      ),
      appBar: AppBar(
        
        backgroundColor: colorScheme.primaryContainer,
        title: buildHeader(context, colorScheme),
      ),
      body: Center(
        child: child,
      ),
    );
  }

  SizedBox buildNewRoutineBody(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
              width: ResponsiveBuilder.isMobile(context) ? null : 464,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if(ResponsiveBuilder.isDesktop(context)) buildHeader(context, colorScheme),
                  const SizedBox(height: 24,),
                  Flexible(
                    child: buildGroupList(),
                  ),
                  const SizedBox(height: 16,),
                  Builder(
                    builder: (context) {
                      return TextButton.icon(
                        onPressed: () {
                          context.read<NewRoutineCubit>().addNewRoutineGroup();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Agregar grupo de ejercicios"),
                      );
                    }
                  ),
                  BlocBuilder<NewRoutineCubit, NewRoutineState>(
                    builder: (context, state) {
                      
                      if(state.copiedGroup == null) return const SizedBox();

                      return Positioned(
                        bottom: 16,
                        left: 0,
                        child: TextButton.icon(
                          onPressed: () {
                            context.read<NewRoutineCubit>().addRoutineGroup(state.copiedGroup!);
                            context.read<NewRoutineCubit>().setCopiedGroup(null);
                          },
                          icon: const Icon(Icons.paste),
                          label: const Text("Pegar grupo"),
                        ),
                      );
                    }
                  )
                ],
              ),
            );
  }

  Widget buildGroupList() {
    return BlocBuilder<NewRoutineCubit, NewRoutineState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          shrinkWrap: true,
          children: state.routineGroups.mapIndexed((index, group) => Padding( 
            padding: EdgeInsets.only(bottom: index == state.routineGroups.length -1 ? 0 : 16),
             child: RoutineGroup(routineGroup: group, isFirst: index == 0,))).toList(),
        );
      },
    );
  }

  Row buildHeader(BuildContext context, ColorScheme colorScheme) {
    final clientName = widget.client?.person != null 
        ? "${widget.client!.person!.name} ${widget.client!.person!.lastName}"
        : "Cliente";

    return Row(
      spacing: 4,
      children: [
        TextButton(
          child: Text(clientName,
              style: Theme.of(context).textTheme.titleMedium),
          onPressed: () => context.pop(),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(
          width: 8,
        ),
        Text(
          "Nueva rutina",
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
  

}
