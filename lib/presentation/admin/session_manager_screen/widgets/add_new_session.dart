import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/utils/physical_partition_naming.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/types/time_interval.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/entities/session.dart';
import '../../../core/custom_time_picker.dart';
import '../../../core/pick_client/pick_client.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddNewSession extends StatefulWidget {
  AddNewSession({
    super.key,
    required BuildContext context,
    required int idPhysicalPartition,
    required this.selectedTimeInterval,
  }) : clubPartition = _findPhysicalPartition(context, idPhysicalPartition) {
    physicalPartition = clubPartition.physicalPartitions!.firstWhere(
      (element) => element.partitionPhysicalId == idPhysicalPartition,
    );

    final defaultDurationMinutes =
        physicalPartition.defaultSessionDuration ??
        physicalPartition.durationInMinutes;
    duration = defaultDurationMinutes != null
        ? Duration(minutes: defaultDurationMinutes)
        : selectedTimeInterval.getDuration();

    defaultPrice =
        physicalPartition.defaultSessionPrice ??
        _findFallbackDefaultPrice(context, idPhysicalPartition) ??
        0;
  }

  late final PhysicalPartition physicalPartition;
  final ClubPartition clubPartition;
  final TimeInterval selectedTimeInterval;
  late final Duration? duration;
  late final double defaultPrice;
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  static ClubPartition _findPhysicalPartition(
    BuildContext context,
    int idPhysicalPartition,
  ) {
    return context.read<SessionManagerBloc>().state.clubPartitions.firstWhere((
      element,
    ) {
      final index = element.physicalPartitions!.indexWhere(
        (element) => element.partitionPhysicalId == idPhysicalPartition,
      );

      return index != -1;
    });
  }

  static double? _findFallbackDefaultPrice(
    BuildContext context,
    int idPhysicalPartition,
  ) {
    final sessions = context.read<SessionManagerBloc>().state.sessions;

    for (final session in sessions) {
      if (session.partitionPhysicalId == idPhysicalPartition &&
          session.price > 0) {
        return session.price;
      }
    }

    return null;
  }

  String get defaultPriceAsText {
    if (defaultPrice <= 0) return '';
    if (defaultPrice == defaultPrice.roundToDouble()) {
      return defaultPrice.toInt().toString();
    }
    return defaultPrice.toStringAsFixed(2);
  }

  @override
  State<AddNewSession> createState() => _AddNewSessionState();
}

class _AddNewSessionState extends State<AddNewSession> {
  bool isValid = true;

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: FormBuilder(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        key: widget._formKey,
        onChanged: () {
          setState(() {
            isValid = widget._formKey.currentState!.validate(
              focusOnInvalid: false,
            );
          });
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildHeader(context),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InputChip(
                          label: Text(widget.clubPartition.clubType!.name),
                        ),
                        const SizedBox(width: 8),
                        InputChip(
                          label: Text(
                            PhysicalPartitionNaming.labelFromPhysicalPartition(
                              widget.physicalPartition,
                              fallbackClubPartition: widget.clubPartition,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    PickClient(
                      name: "client",
                      onPressNew: () {
                        setState(() {
                          isValid = widget._formKey.currentState!.validate(
                            focusOnInvalid: false,
                          );
                        });
                      },
                      onBackToSelection: () {
                        setState(() {
                          isValid = widget._formKey.currentState!.validate(
                            focusOnInvalid: false,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text("Hora de inicio"),
                    const SizedBox(height: 16),
                    CustomTimePicker(
                      name: "initialTime",
                      initialHours: widget
                          .selectedTimeInterval
                          .initialDate!
                          .hour
                          .toString(),
                      initialMinutes: widget
                          .selectedTimeInterval
                          .initialDate!
                          .minute
                          .toString(),
                    ),
                    const SizedBox(height: 16),
                    const Text("Duracion"),
                    const SizedBox(height: 16),
                    CustomTimePicker(
                      name: "duration",
                      initialHours: widget.duration?.inHours.toString(),
                      initialMinutes:
                          (widget.duration!.inMinutes -
                                  widget.duration!.inHours * 60)
                              .toString(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: FormBuilderTextField(
                        name: "price",
                        initialValue: widget.defaultPriceAsText,
                        decoration: InputDecoration(
                          prefix: const Text("\$"),
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          labelText: "Precio",
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: FilledButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      onPressed: isValid
                          ? () {
                              final sessionManagerBloc = context
                                  .read<SessionManagerBloc>();

                              final currentDate =
                                  sessionManagerBloc.state.currentDate;

                              final values =
                                  widget._formKey.currentState?.instantValue;

                              TimeOfDay duration = values!['duration'];

                              final newSession = Session(
                                sessionId: -1,
                                createdAt: DateTime.now(),
                                startTime: currentDate.applied(
                                  values['initialTime'],
                                ),
                                duration: duration.getTotalMinutes,
                                price:
                                    (values['price'] != null &&
                                        values['price']
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                    ? double.parse(values['price'])
                                    : widget.defaultPrice,
                                partitionPhysicalId: widget
                                    .physicalPartition
                                    .partitionPhysicalId,
                                clientId: values['client']?.clientId != null
                                    ? int.tryParse(values['client'].clientId)
                                    : null,
                                client:
                                    values['client'] != null &&
                                        values['client'].clientId == null
                                    ? values['client']
                                    : null,
                              );

                              sessionManagerBloc.add(
                                SaveSessionEvent(newSession),
                              );

                              context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
                            }
                          : null,
                      child: const Text("Crear Turno"),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stack buildHeader(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 64,
          width: ResponsiveBuilder.isDesktop(context) ? 300 : double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Nuevo Turno", style: TextStyle(fontSize: 16)),
              Text(
                "${widget.selectedTimeInterval.getInitialTextString()} | ${widget.selectedTimeInterval.toStringTime()}",
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: IconButton(
            onPressed: () {
              context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
            },
            icon: const Icon(Icons.arrow_back),
          ),
        ),
      ],
    );
  }
}
