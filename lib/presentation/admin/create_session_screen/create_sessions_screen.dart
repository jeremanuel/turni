import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/inputs/chips/filter_chip_interval_date.dart';
import '../../../core/utils/responsive_builder.dart';
import '../../../core/utils/types/time_interval.dart';
import '../../../domain/entities/physical_partition.dart';
import '../../core/agenda/agenda.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import 'bloc/create_sesssions_form_bloc.dart';

import 'widgets/add_session_button.dart';
import 'widgets/agenda_edit_card.dart';

class CreateSessionScreen extends StatefulWidget {
  const CreateSessionScreen({super.key});

  @override
  State<CreateSessionScreen> createState() => _CreateSessionScreenState();
}

class _CreateSessionScreenState extends State<CreateSessionScreen> {

  @override
  void dispose() {

    sl.resetLazySingleton<CreateSesssionsFormBloc>();
    // TODO: implement dispose
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      bloc: sl<CreateSesssionsFormBloc>(),
      listener: (context, state) {
        if(state.savedSessions){
          context.read<SessionManagerBloc>().add(SessionManagerEvent.reloadSessionsEvent());
          context.go('/session_manager');
        }
      },
      child: Portal(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildMainContainer(context),
            const VerticalDivider(),
            buildSideContainer(context)
          ],
        ),
      ),
    );
  }

  Container buildSideContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      width: 300,
      child: Column(
        children: [
          const Text("Agregar Turnos",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20)),
          const SizedBox(height: 80),
          BlocBuilder<CreateSesssionsFormBloc, CreateSesssionsFormState>(
            bloc: sl<CreateSesssionsFormBloc>(),
            builder: (context, state) {
              return FilterChipIntervalDate(
                initialValue: state.interval,
                onApply: (p0) => sl<CreateSesssionsFormBloc>()
                    .add(ChangeSelectionInitialDate(p0)),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text("Seleccione en que modalidades cargara el turno."),
          const SizedBox(height: 20),
          buildClubPartitionsHorizontalList(context),
          const SizedBox(height: 20),
          buildPhysicalPartitionsHorizontalList(context),
          const Spacer(),
          FilledButton(
              onPressed: () =>
                  sl<CreateSesssionsFormBloc>().add(const CreateSessions()),
              child: const Text("Crear Turnos"))
        ],
      ),
    );
  }

  SizedBox buildClubPartitionsHorizontalList(BuildContext context) {

    final clubPartitions = context.read<SessionManagerBloc>().state.clubPartitions;
    
    final formBloc = sl<CreateSesssionsFormBloc>();
    
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (ResponsiveBuilder.isMobile(context))
            const SizedBox(
              width: 8,
            ),
          ...clubPartitions.expand((e) => [
                BlocBuilder<CreateSesssionsFormBloc, CreateSesssionsFormState>(
                  bloc: formBloc,
                  builder: (context, state) {
                    return FilterChip(
                        selected: state.selectedClubPartitions.contains(e),
                        label: Text(e.clubType!.name),
                        onSelected: (val) =>
                            formBloc.add(ChangeSelectionClubPartition(e, val)),
                        showCheckmark: false);
                  },
                ),
                const SizedBox(
                  width: 16,
                ),
              ]),
          if (ResponsiveBuilder.isMobile(context))
            const SizedBox(
              width: 8,
            ),
        ],
      ),
    );
  }

  Widget buildPhysicalPartitionsHorizontalList(context) {
    final formBloc = sl<CreateSesssionsFormBloc>();

    return BlocBuilder<CreateSesssionsFormBloc, CreateSesssionsFormState>(
      bloc: formBloc,
      builder: (context, state) {
        final physicalPartitions = formBloc.state.selectedClubPartitions
            .expand((element) => element.physicalPartitions!);

        return Column(
          children: [
            if (physicalPartitions.isNotEmpty) ...[
              const Text("Seleccione en que canchas"),
              const SizedBox(
                height: 20,
              ),
            ],
            Wrap(
              runSpacing: 8,
              children: [
                if (ResponsiveBuilder.isMobile(context))
                  const SizedBox(
                    width: 8,
                  ),
                ...physicalPartitions.expand((e) => [
                      FilterChip(
                          selected:
                              state.selectedPhysicalPartitions.contains(e),
                          label: Text("Cancha ${e.physicalIdentifier!}"),
                          onSelected: (val) => formBloc
                              .add(ChangeSelectionPhysicalPartition(e, val)),
                          showCheckmark: false),
                      const SizedBox(
                        width: 16,
                      ),
                    ]),
                if (ResponsiveBuilder.isMobile(context))
                  const SizedBox(
                    width: 8,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Expanded buildMainContainer(context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            buildMainContainerHeader(),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 5,
                          spreadRadius: 5,
                          color: Theme.of(context)
                              .colorScheme
                              .shadow
                              .withOpacity(0.1))
                    ],
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: BlocBuilder<CreateSesssionsFormBloc,
                      CreateSesssionsFormState>(
                    bloc: sl<CreateSesssionsFormBloc>(),
                    buildWhen: (previous, current) =>
                        previous.sessions != current.sessions,
                    builder: (context, state) {
                      return Agenda(
                        sessions: state.sessions,
                        buildCard: (session, physicalPartition) =>
                            AgendaEditCard(session: session),
                        physicalPartitions: [
                          PhysicalPartition(
                              partitionPhysicalId: 1,
                              clubPartitionId: 1,
                              minPlayers: 1,
                              maxPlayers: 1,
                              physicalIdentifier: 1,
                              isCover: 'true',
                              description: '')
                        ],
                        fromDate: DateTime.now()
                            .applied(const TimeOfDay(hour: 8, minute: 30)),
                        lastDate: DateTime.now()
                            .applied(const TimeOfDay(hour: 22, minute: 30)),
                      );
                    },
                  )),
            )
          ],
        ),
      ),
    );
  }

  Row buildMainContainerHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const AddSessionButton(),
        const SizedBox(
          width: 8,
        ),
        IconButton(onPressed: () {}, icon: const Icon(Icons.build))
      ],
    );
  }
}
