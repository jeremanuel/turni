
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/date_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/physical_partition_naming.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/subscription/client_subscription.dart';
import '../../../../domain/repositories/subscription_repository.dart';
import '../../../core/cubit/auth/auth_cubit.dart';
import '../client_page.dart';
import 'subscriptions_container/add_subscription_button.dart';

class SubscriptionContainer extends StatefulWidget {

  const SubscriptionContainer({super.key});

  @override
  State<SubscriptionContainer> createState() => _SubscriptionContainerState();
}

class _SubscriptionContainerState extends State<SubscriptionContainer> {

  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    
    final textTheme = Theme.of(context).textTheme;
    final client = ClientInherited.of(context)!.client;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Subscripciones", style: textTheme.headlineSmall),
              const Spacer(),
              AddSubscriptionButton(client:client)
            ],
          ),
          const SizedBox(height: 24,),
          if(client.clientSubscriptions == null || client.clientSubscriptions!.isEmpty) const Text("El cliente no tiene subscripciones cargadas")
          else SizedBox(
            height: 152,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              controller: scrollController,
              itemCount: client.clientSubscriptions?.length ?? 0,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                return SubscriptionCard(clientSubscription: client.clientSubscriptions![index]);
              },
              separatorBuilder: (context, index) => const SizedBox(width: 8)
            ),
          )
        ],
      ),
    );
  }
}

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    super.key,
    required this.clientSubscription,
    this.compact = false,
  });

  static const _dayLabels = <int, String>{
    0: 'Domingo',
    1: 'Lunes',
    2: 'Martes',
    3: 'Miercoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sabado',
  };

  final ClientSubscription clientSubscription;
  final bool compact;

  String get _statusLabel => clientSubscription.isActive ? 'Activa' : 'Finalizada';

  String get _priceLabel => '\$${clientSubscription.subscription.getCurrentPrice()?.price ?? '-'}';

  String? _locationLabel() {
    if (clientSubscription.partitionPhysicalId == null) return null;

    final authState = sl<AuthCubit>().state;
    final clubPartitions = authState.userCredential?.admin?.clubPartitions;

    ClubPartition? currentClubPartition;
    if (clubPartitions != null && clubPartitions.isNotEmpty) {
      currentClubPartition = clubPartitions.firstWhere(
        (partition) =>
            partition.club_partition_id ==
            clientSubscription.subscription.clubPartitionId,
        orElse: () => clubPartitions.first,
      );
    }

    final singular = PhysicalPartitionNaming.singularFromClubPartition(
      currentClubPartition,
    );

    return '$singular ${clientSubscription.partitionPhysicalId}';
  }

  String? get _dayLabel {
    if (clientSubscription.dayOfWeek == null) return null;
    return _dayLabels[clientSubscription.dayOfWeek!];
  }

  String? get _timeLabel {
    final sessionTime = clientSubscription.sessionTime;
    if (sessionTime == null) return null;
    return DateFunctions.formatTimeToHourMinute(sessionTime, useUtc: true);
  }

  Widget _buildDetailPill(BuildContext context, IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Chip(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),

      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          Text(value, style: textTheme.labelLarge),
        ],
      ),
    );
  }

  Widget _buildDetailsWrap(BuildContext context) {
    final locationLabel = _locationLabel();

    final details = <Widget>[
      _buildDetailPill(context, Icons.sell_outlined, 'Precio', _priceLabel),
    ];

    if (locationLabel != null) {
      details.add(
        _buildDetailPill(context, Icons.place_outlined, 'Lugar', locationLabel),
      );
    }
    if (_dayLabel != null) {
      details.add(_buildDetailPill(context, Icons.calendar_today_outlined, 'Dia', _dayLabel!));
    }
    if (_timeLabel != null) {
      details.add(_buildDetailPill(context, Icons.schedule_outlined, 'Hora', _timeLabel!));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details,
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = clientSubscription.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primaryContainer : colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? colorScheme.primary.withOpacity(0.2) : colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        _statusLabel,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Future<bool?> _showUnsubscribeDecisionDialog(BuildContext context, int futureLinkedSessions) async {
    bool unlinkFutureSessions = false;

    return showDialog<bool>(
      context: context,
      builder: (innerContext) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return AlertDialog(
              title: const Text('Cancelar subscripcion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (futureLinkedSessions > 0)
                    Text(
                      'Esta subscripcion tiene $futureLinkedSessions turno(s) futuro(s) vinculado(s).',
                    )
                  else
                    const Text('¿Estas seguro que deseas cancelar la subscripcion?'),
                  if (futureLinkedSessions > 0) ...[
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: unlinkFutureSessions,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Desvincular turnos futuros del cliente'),
                      subtitle: const Text('Si se activa, esas reservas quedaran sin cliente asignado.'),
                      onChanged: (value) {
                        setInnerState(() {
                          unlinkFutureSessions = value ?? false;
                        });
                      },
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(innerContext, null),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(innerContext, unlinkFutureSessions),
                  child: const Text('Si'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleUnsubscribe(BuildContext context) async {
    final clientInherited = ClientInherited.of(context);
    if (clientInherited == null) return;
    final client = clientInherited.client;
    final repository = sl<SubscriptionRepository>();

    final previewResponse = await repository.previewUnsubscribeLinkedSessions(
      clientSubscription.clientSubscriptionId,
      client.intClientId,
    );

    final previewResult = switch (previewResponse) {
      Left(:final failure) => failure,
      Right(:final value) => value,
    };

    if (previewResult is DomainError) {
      return;
    }

    final futureLinkedSessions = previewResult as int;
    final unlinkDecision = await _showUnsubscribeDecisionDialog(context, futureLinkedSessions);
    if (unlinkDecision == null) {
      return;
    }

    final unsubscribeResponse = await repository.unSubscribeClient(
      clientSubscription.clientSubscriptionId,
      client.intClientId,
      unlinkFutureSessions: unlinkDecision,
    );

    final unsubscribeResult = switch (unsubscribeResponse) {
      Left(:final failure) => failure,
      Right(:final value) => value,
    };

    if (unsubscribeResult is DomainError) {
      return;
    }

    clientInherited.updateClient(
      client.copyWith(
        clientSubscriptions: client.clientSubscriptions!
            .map((e) => e.clientSubscriptionId == clientSubscription.clientSubscriptionId
                ? e.copyWith(endDate: DateTime.now())
                : e)
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (compact) {
      return Container(
        decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colorScheme.outline.withOpacity(0.5))
    ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clientSubscription.subscription.name, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Creada hace ${DateFunctions.differencePretty(clientSubscription.startDate)}',
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(context),
                if (clientSubscription.isActive) ...[
                  const SizedBox(width: 6),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.cancel, size: 20),
                    tooltip: "Cancelar suscripción",
                    onPressed: () => _handleUnsubscribe(context),
                  ),
                ],
              ]
            ),
            const SizedBox(height: 12),
            _buildDetailsWrap(context),
          ],
        ),
      );
    }

    return Container(
    width: 300,
    height: 156,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
      border: clientSubscription.isActive ? Border.all(color: colorScheme.primary) : null
    ),
    child: Stack(
      children: [
        
        if(clientSubscription.isActive)
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: () => _handleUnsubscribe(context), 
              icon: const Icon(Icons.cancel), 
              tooltip: "Cancelar subscripcion",
            )
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clientSubscription.subscription.name, style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          clientSubscription.isActive
                              ? 'Desde ${DateFunctions.formatDateToDefaultFormat(clientSubscription.startDate)}'
                              : 'Finalizo ${DateFunctions.formatDateToDefaultFormat(clientSubscription.endDate!)}',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailsWrap(context),
            ]
            ),
        ),
      ],
    ),
    );
  }
}


