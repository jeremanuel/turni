import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/responsive_builder.dart';
import '../../../../../core/utils/types/time_interval.dart';
import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/extra.dart';
import '../../../../../domain/entities/physical_partition.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/repositories/session_repository.dart';
import '../../../../../domain/usercases/session_user_cases.dart';
import '../../../../../core/config/service_locator.dart';
import '../../../../core/pick_client/pick_client.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'widgets/activity_container.dart';
import 'widgets/payment_container.dart';

class SessionInfo extends StatefulWidget {
  const SessionInfo(
      {super.key,
      required this.session,
      required this.physicalPartition,
      required this.clubPartition});

  final Session session;
  final PhysicalPartition physicalPartition;
  final ClubPartition clubPartition;

  @override
  State<SessionInfo> createState() => _SessionInfoState();
}

class _SessionInfoState extends State<SessionInfo> {
  bool isValid = false;
  bool isLoadingSession = false;
  var _formKey = GlobalKey<FormBuilderState>();

  final SessionUserCases _sessionUserCases =
      SessionUserCases(sl<SessionRepository>());

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SessionInfo oldWidget) {
    if (widget.session.sessionId != oldWidget.session.sessionId) {
      setState(() {
        _formKey = GlobalKey<FormBuilderState>();
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final timeInterval = TimeInterval(
        initialDate: widget.session.startTime, endDate: widget.session.endTime);
    final isMobile = ResponsiveBuilder.isMobile(context);
    final horizontalPadding = isMobile ? 12.0 : 0.0;
    final sectionSpacing = isMobile ? 12.0 : 16.0;
    final headerSpacing = isMobile ? 18.0 : 32.0;

    return FormBuilder(
      autovalidateMode: AutovalidateMode.onUserInteraction,
      key: _formKey,
      onChanged: () {
        setState(() {
          isValid = _formKey.currentState!.validate(focusOnInvalid: false);
        });
      },
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    buildHeader(context),
                    SizedBox(height: headerSpacing),
                    Wrap(
                      runSpacing: isMobile ? 6 : 8,
                      spacing: isMobile ? 6 : 8,
                      children: [
                        Chip(
                            visualDensity: isMobile
                                ? const VisualDensity(
                                    horizontal: -2, vertical: -2)
                                : null,
                            materialTapTargetSize: isMobile
                                ? MaterialTapTargetSize.shrinkWrap
                                : null,
                            avatar: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            label: Text(timeInterval.getInitialTextString())),
                        Chip(
                            visualDensity: isMobile
                                ? const VisualDensity(
                                    horizontal: -2, vertical: -2)
                                : null,
                            materialTapTargetSize: isMobile
                                ? MaterialTapTargetSize.shrinkWrap
                                : null,
                            avatar: Icon(Icons.access_time,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            label: Text(timeInterval.toStringTime())),
                        Chip(
                            visualDensity: isMobile
                                ? const VisualDensity(
                                    horizontal: -2, vertical: -2)
                                : null,
                            materialTapTargetSize: isMobile
                                ? MaterialTapTargetSize.shrinkWrap
                                : null,
                            label: Text(widget.clubPartition.clubType!.name)),
                        Chip(
                            visualDensity: isMobile
                                ? const VisualDensity(
                                    horizontal: -2, vertical: -2)
                                : null,
                            materialTapTargetSize: isMobile
                                ? MaterialTapTargetSize.shrinkWrap
                                : null,
                            avatar: Icon(Icons.place,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            label: Text(
                                "Cancha ${widget.physicalPartition.physicalIdentifier}")),
                        Chip(
                            visualDensity: isMobile
                                ? const VisualDensity(
                                    horizontal: -2, vertical: -2)
                                : null,
                            materialTapTargetSize: isMobile
                                ? MaterialTapTargetSize.shrinkWrap
                                : null,
                            avatar: Icon(Icons.attach_money,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            label: Text("${widget.session.price}"))
                      ],
                    ),
                    SizedBox(height: sectionSpacing),
                    const Divider(),
                    SizedBox(height: sectionSpacing),
                    PickClient(
                      initialValue: widget.session.client,
                      readOnly: widget.session.client != null,
                      name: "client",
                      isRequired: true,
                    ),
                    if (widget.session.isReserved) ...[
                      SizedBox(height: sectionSpacing),
                      const Divider(),
                      SizedBox(height: sectionSpacing),
                      PaymentContainer(
                        session: widget.session,
                        onExtraAdded: (extra, payed) async {
                          final result = await _sessionUserCases.addExtraToSession(
                            widget.session.sessionId,
                            extra,
                            paidExtra: payed,
                          );

                          result.when(
                            left: (_) {},
                            right: (savedExtra) {
                              final updated = widget.session.copyWith(
                                extras: [...?widget.session.extras, savedExtra],
                              );
                              context
                                  .read<SessionManagerBloc>()
                                  .updateSessionInState(updated);
                            },
                          );
                        },
                        onPaymentAdded: (payment) async {
                          final result = await _sessionUserCases.addPaymentToSession(
                            widget.session.sessionId,
                            payment,
                          );

                          result.when(
                            left: (_) {},
                            right: (savedPayment) {
                              final updated = widget.session.copyWith(
                                payments: [...?widget.session.payments, savedPayment],
                              );
                              context
                                  .read<SessionManagerBloc>()
                                  .updateSessionInState(updated);
                            },
                          );
                        },
                        onExtraDeleted: (extra) async {
                          final result = await _sessionUserCases.deleteSessionExtra(
                            widget.session.sessionId,
                            extra,
                          );

                          result.when(
                            left: (_) {},
                            right: (success) {
                              if (!success) return;

                              final updated = widget.session.copyWith(
                                extras: widget.session.extras
                                    ?.where((current) =>
                                        (current.extraId != null &&
                                                extra.extraId != null)
                                            ? current.extraId != extra.extraId
                                            : current != extra)
                                    .toList(),
                              );
                              context
                                  .read<SessionManagerBloc>()
                                  .updateSessionInState(updated);
                            },
                          );
                        },
                        onExtrasPayed: (extras) async {
                          final paidExtras = <Extra>[];

                          for (final extra in extras) {
                            final result = await _sessionUserCases.paySessionExtra(
                              widget.session.sessionId,
                              extra,
                            );

                            result.when(
                              left: (_) {},
                              right: (savedExtra) {
                                paidExtras.add(savedExtra);
                              },
                            );
                          }

                          if (paidExtras.isEmpty) return;

                          final updated = widget.session.copyWith(
                              extras: widget.session.extras?.map((currentExtra) {
                            final savedExtra = paidExtras.firstWhere(
                              (s) {
                                if (s.extraId != null && currentExtra.extraId != null) {
                                  return s.extraId == currentExtra.extraId;
                                }
                                return s.name == currentExtra.name &&
                                    s.amount == currentExtra.amount;
                              },
                              orElse: () => currentExtra,
                            );

                            return savedExtra != currentExtra ? savedExtra : currentExtra;
                          }).toList());

                          context
                              .read<SessionManagerBloc>()
                              .updateSessionInState(updated);
                        },
                      ),
                      SizedBox(height: sectionSpacing),
                      if (isMobile)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text("Actividad"),
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: ActivityContainer(),
                            ),
                          ],
                        )
                      else
                        const ActivityContainer(),
                      SizedBox(height: sectionSpacing),
                      if (isMobile)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text("Observaciones"),
                          children: const [
                            Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: TextField(
                                minLines: 3,
                                maxLines: 5,
                                decoration: InputDecoration(
                                    hintText: "Observaciones",
                                    border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        )
                      else
                        const TextField(
                          minLines: 3,
                          maxLines: 5,
                          decoration: InputDecoration(
                              hintText: "Observaciones",
                              border: OutlineInputBorder()),
                        ),
                      SizedBox(height: sectionSpacing),
                    ]
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: () {},
                    child: Text(widget.session.isReserved
                        ? "Cancelar Reserva"
                        : "Eliminar Turno")),
                if (!widget.session.isReserved)
                  FilledButton(
                      onPressed: isValid
                          ? () {
                              final sessionManagerBloc =
                                  context.read<SessionManagerBloc>();

                              final client = _formKey
                                  .currentState!.fields['client']?.value;

                              sessionManagerBloc
                                  .add(ReserveEvent(widget.session, client));

                              context.go("/session_manager");
                            }
                          : null,
                      child: const Text("Reservar Turno")),
              ],
            ),
          )
        ],
      ),
    );
  }

  Stack buildHeader(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Stack(
      children: [
        SizedBox(
          height: 64,
          width: ResponsiveBuilder.isDesktop(context) ? 300 : double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Datos del Turno",
                style: textTheme.headlineSmall,
              ),
/*             Text("${timeInterval.getInitialTextString()} | ${timeInterval.toStringTime()}", style: textTheme.bodyLarge),
 */
            ],
          ),
        ),
        SizedBox(
          height: 64,
          child: IconButton(
              onPressed: () {
                context.go("/session_manager");
              },
              icon: const Icon(Icons.arrow_back)),
        )
      ],
    );
  }
}
