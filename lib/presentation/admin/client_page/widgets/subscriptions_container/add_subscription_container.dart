// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../core/presentation/components/inputs/animation/splash_animation.dart';
import '../../../../../core/utils/domain_error.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/subscription/client_subscription.dart';
import '../../../../../domain/entities/subscription/subscription.dart';
import '../../../../../domain/repositories/subscription_repository.dart';
import '../../../../core/cubit/auth/auth_cubit.dart';
import '../../../club_config/club_config_focus.dart';
import '../../../club_config/widgets/inactive_partition_hint.dart';
import '../../client_page.dart';

/// Alta de un abono para el cliente. Los turnos fijos no se cargan acá: tienen
/// su propia sección (ver `ClientFixedSessions` / pestaña Turnos fijos).
class AddSubscriptionContainer extends StatefulWidget {
  const AddSubscriptionContainer({
    super.key,
    required this.clubPartitions,
    required this.client,
  });

  final List<ClubPartition>? clubPartitions;
  final Client client;

  @override
  State<AddSubscriptionContainer> createState() =>
      _AddSubscriptionContainerState();
}

class _AddSubscriptionContainerState extends State<AddSubscriptionContainer> {
  Subscription? selectedSubscription;
  bool isLoading = false;
  bool isConfirmed = false;
  final subscriptionRepository = sl<SubscriptionRepository>();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isConfirmed) {
      return SplashAnimation(
        width: 300,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 50,
            ).animate().fadeIn(delay: const Duration(milliseconds: 400)),
            Text(
              "Subscripcion confirmada",
              style: textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 450)),
          ],
        ),
      );
    }

    if (selectedSubscription != null) {
      return buildConfirmation(textTheme, context).animate().fadeIn().moveY();
    }

    return buildSubscriptionSelection(context);
  }

  SizedBox buildSubscriptionSelection(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView(
        children: [
          ListTile(
            title: Text(
              "Nueva subscripcion",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Divider(height: 1, color: Theme.of(context).colorScheme.onSurface),
          ...widget.clubPartitions!.expand((clubPartition) {
            // Los turnos fijos se cargan desde su propia sección (Turnos fijos).
            return clubPartition.subscriptions!
                .where((subscription) => subscription.subscriptionType != "FIXED_SESSION")
                .map((subscription) {
              // Las suscripciones de una modalidad inactiva se listan pero no
              // se pueden elegir (ver InactivePartitionHint).
              return InactivePartitionHint(
                inactive: !clubPartition.active,
                message: InactivePartitionHint.clubPartitionMessage,
                focus: ClubConfigFocus.clubPartition(clubPartition.club_partition_id ?? 0),
                child: ListTile(
                enabled: clubPartition.active,
                trailing: Text(
                  "\$${subscription.getCurrentPrice()!.price}",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                subtitle: Text(clubPartition.clubType!.name),
                title: Text(
                  subscription.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  setState(() {
                    selectedSubscription = subscription;
                  });
                },
              ),
              );
            }).toList();
          }),
        ],
      ),
    );
  }

  Widget _buildInfoLine(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 1),
                Text(value, style: textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text("Confirmar suscripcion", style: textTheme.titleMedium),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          "Asignar ${selectedSubscription!.name} a ${widget.client.person!.fullName}.",
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        _buildInfoLine(
          context,
          "Plan",
          selectedSubscription!.name,
          icon: Icons.sell_outlined,
        ),
        const SizedBox(height: 8),
        _buildInfoLine(
          context,
          "Precio",
          "\$${selectedSubscription!.getCurrentPrice()!.price}",
          icon: Icons.attach_money,
        ),
      ],
    );
  }

  Future<void> _confirmSubscription() async {
    setState(() {
      isLoading = true;
    });

    final payload = {
      "client_id": int.parse(widget.client.clientId!),
      "subscription_id": selectedSubscription!.subscriptionId,
      "created_by_admin": sl<AuthCubit>().state.userCredential!.admin!.adminId,
    };

    final response = await subscriptionRepository.subscribeClient(
      payload,
      int.parse(widget.client.clientId!),
    );

    final result = switch (response) {
      Left(:final failure) => failure,
      Right(:final value) => value,
    };

    if (result is DomainError) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (result is ClientSubscription) {
      setState(() {
        isConfirmed = true;
        isLoading = false;
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      final clientInherited = ClientInherited.of(context);
      clientInherited?.updateClient(
        widget.client.copyWith(
          clientSubscriptions: [
            result,
            ...widget.client.clientSubscriptions ?? [],
          ],
        ),
      );
    }
  }

  Container buildConfirmation(TextTheme textTheme, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _buildConfirmationStep(context, textTheme, colorScheme),
            ),
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: isLoading ? null : _confirmSubscription,
                child: const Text("Crear"),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: isLoading ? null : () => setState(() => selectedSubscription = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Volver"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
