// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/router/app_routes.dart';
import '../../../../../core/config/service_locator.dart';
import '../../../../../core/presentation/components/inputs/animation/splash_animation.dart';
import '../../../../../core/utils/domain_error.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../core/utils/physical_partition_naming.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/club_partition.dart';
import '../../../../../domain/entities/physical_partition.dart';
import '../../../../../domain/entities/subscription/client_subscription.dart';
import '../../../../../domain/entities/subscription/subscription.dart';
import '../../../../../domain/repositories/subscription_repository.dart';
import '../../../../core/cubit/auth/auth_cubit.dart';
import '../../client_page.dart';

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
  static const _dayLabels = <int, String>{
    0: "Domingo",
    1: "Lunes",
    2: "Martes",
    3: "Miercoles",
    4: "Jueves",
    5: "Viernes",
    6: "Sabado",
  };
  static const _fixedStepConfigure = 0;
  static const _fixedStepOverlaps = 1;
  static const _fixedStepConfirm = 2;

  Subscription? selectedSubscription;
  bool isLoading = false;
  bool isConfirmed = false;
  final subscriptionRepository = sl<SubscriptionRepository>();
  int? selectedDayOfWeek;
  TimeOfDay? selectedTime;
  int? selectedDuration;
  int? selectedPartitionPhysicalId;
  List<Map<String, dynamic>> fixedPreview = [];
  Set<String> overrideDates = {};
  String? fixedValidationError;
  String? fixedPreviewInfo;
  Map<String, dynamic>? fixedExistingSubscriptionConflict;
  int currentFixedStep = _fixedStepConfigure;

  bool get isFixedSession =>
      selectedSubscription?.subscriptionType == "FIXED_SESSION";

  ClubPartition? get selectedSubscriptionClubPartition {
    if (selectedSubscription == null) return null;
    for (final partition in widget.clubPartitions ?? const <ClubPartition>[]) {
      final hasSubscription =
          (partition.subscriptions ?? const <Subscription>[]).any(
            (s) => s.subscriptionId == selectedSubscription!.subscriptionId,
          );
      if (hasSubscription) return partition;
    }
    return null;
  }

  List<PhysicalPartition> get availablePhysicalPartitions =>
      selectedSubscriptionClubPartition?.physicalPartitions ??
      const <PhysicalPartition>[];

  PhysicalPartition? get selectedPhysicalPartition {
    for (final partition in availablePhysicalPartitions) {
      if (partition.partitionPhysicalId == selectedPartitionPhysicalId) {
        return partition;
      }
    }
    return null;
  }

  int get bookedConflictCount =>
      fixedPreview.where((item) => item["isBooked"] == true).length;

  int get freeConflictCount =>
      fixedPreview.where((item) => item["isBooked"] != true).length;

  bool get hasAnyConfiguration =>
      selectedDayOfWeek != null ||
      selectedTimeString != null ||
      selectedDuration != null ||
      selectedPartitionPhysicalId != null;

  double get fixedStepProgress {
    switch (currentFixedStep) {
      case _fixedStepConfigure:
        return 1 / 3;
      case _fixedStepOverlaps:
        return 2 / 3;
      case _fixedStepConfirm:
        return 1;
      default:
        return 1 / 3;
    }
  }

  String get fixedStepTitle {
    switch (currentFixedStep) {
      case _fixedStepConfigure:
        return "Configurar turno fijo";
      case _fixedStepOverlaps:
        return "Revisar solapamientos";
      case _fixedStepConfirm:
        return "Confirmar suscripcion";
      default:
        return "Turno fijo";
    }
  }

  String? get selectedTimeString {
    if (selectedTime == null) return null;
    final hh = selectedTime!.hour.toString().padLeft(2, '0');
    final mm = selectedTime!.minute.toString().padLeft(2, '0');
    return "$hh:$mm";
  }

  Future<void> _loadFixedPreview() async {
    if (selectedDayOfWeek == null ||
        selectedTimeString == null ||
        selectedDuration == null ||
        selectedPartitionPhysicalId == null) {
      setState(() {
        fixedValidationError = "Completa dia y horario para previsualizar.";
      });
      return;
    }

    setState(() {
      fixedValidationError = null;
      fixedPreviewInfo = null;
      fixedExistingSubscriptionConflict = null;
      isLoading = true;
    });

    final response = await subscriptionRepository.previewFixedSessions({
      "dayOfWeek": selectedDayOfWeek,
      "sessionTime": selectedTimeString,
      "sessionDuration": selectedDuration,
      "partitionPhysicalId": selectedPartitionPhysicalId,
    });

    final result = switch (response) {
      Left(:final failure) => failure,
      Right(:final value) => value,
    };

    if (result is DomainError) {
      setState(() {
        fixedValidationError = "No se pudo cargar la previsualizacion.";
        fixedPreviewInfo = null;
        isLoading = false;
      });
      return;
    }

    if (result is Map<String, dynamic>) {
      final fixedConflict = result["fixedConflict"] as Map<String, dynamic>?;
      final preview = (result["preview"] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (fixedConflict != null) {
        final conflictClientName =
            fixedConflict["clientFullName"]?.toString() ?? "otro cliente";
        setState(() {
          fixedExistingSubscriptionConflict = fixedConflict;
          fixedValidationError =
              "Ya existe un turno fijo en ese horario para $conflictClientName.";
          fixedPreview = [];
          overrideDates = {};
          fixedPreviewInfo = null;
          currentFixedStep = _fixedStepConfigure;
          isLoading = false;
        });
        return;
      }

      final conflicts = preview
          .where((item) => item["existingSession"] != null)
          .toList();
      setState(() {
        fixedExistingSubscriptionConflict = null;
        fixedPreview = conflicts;
        overrideDates = overrideDates
            .where((d) => conflicts.any((c) => c["date"] == d))
            .toSet();
        fixedPreviewInfo = conflicts.isEmpty
            ? "No hay turnos solapados para los proximos 30 dias."
            : "Se encontraron ${conflicts.length} fecha(s) con solapamientos.";
        currentFixedStep = conflicts.isEmpty
            ? _fixedStepConfirm
            : _fixedStepOverlaps;
        isLoading = false;
      });
    }
  }

  void _resetFixedPreviewState() {
    fixedPreview = [];
    overrideDates = {};
    fixedValidationError = null;
    fixedPreviewInfo = null;
    fixedExistingSubscriptionConflict = null;
    currentFixedStep = _fixedStepConfigure;
  }

  void _openFixedConflictClientProfile() {
    final conflictClientId = fixedExistingSubscriptionConflict?["clientId"];
    if (conflictClientId == null) {
      return;
    }

    context.goNamed(
      AppRoutes.CLIENT_ROUTE.name,
      pathParameters: {"clientId": conflictClientId.toString()},
    );
  }

  void _resetSelectedSubscription() {
    selectedSubscription = null;
    selectedDayOfWeek = null;
    selectedTime = null;
    selectedDuration = null;
    selectedPartitionPhysicalId = null;
    _resetFixedPreviewState();
  }

  void _goBackFromCurrentStep() {
    setState(() {
      if (!isFixedSession) {
        _resetSelectedSubscription();
        return;
      }

      if (currentFixedStep == _fixedStepConfirm) {
        currentFixedStep = fixedPreview.isNotEmpty
            ? _fixedStepOverlaps
            : _fixedStepConfigure;
        return;
      }

      if (currentFixedStep == _fixedStepOverlaps) {
        currentFixedStep = _fixedStepConfigure;
        return;
      }

      _resetSelectedSubscription();
    });
  }

  void _cancelWizard() {
    setState(() {
      _resetSelectedSubscription();
    });
  }

  void _goToNextFromCurrentStep() {
    if (!isFixedSession) {
      return;
    }

    if (currentFixedStep == _fixedStepConfigure) {
      _loadFixedPreview();
      return;
    }

    if (currentFixedStep == _fixedStepOverlaps) {
      setState(() {
        currentFixedStep = _fixedStepConfirm;
      });
    }
  }

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            return clubPartition.subscriptions!.map((subscription) {
              return ListTile(
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
                    _resetSelectedSubscription();
                    selectedSubscription = subscription;
                  });
                },
              );
            }).toList();
          }),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required Widget child,
    Widget? title,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[title, const SizedBox(height: 16)],
        child,
      ],
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

  Widget _buildSummaryChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: textTheme.labelLarge),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _buildSectionCard(
      context: context,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSummaryChip(
                context,
                Icons.warning_amber_rounded,
                "Reservados",
                "$bookedConflictCount",
              ),
              _buildSummaryChip(
                context,
                Icons.layers_clear_outlined,
                "Libres",
                "$freeConflictCount",
              ),
              _buildSummaryChip(
                context,
                Icons.done_all_outlined,
                "Override",
                "${overrideDates.length}",
              ),
            ],
          ),

          if (fixedValidationError != null) ...[
            const SizedBox(height: 12),
            Text(
              fixedValidationError!,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          if (fixedPreviewInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fixedPreview.isEmpty
                    ? colorScheme.tertiaryContainer
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                fixedPreviewInfo!,
                style: textTheme.bodyMedium?.copyWith(
                  color: fixedPreview.isEmpty
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 150),
            width: double.infinity,

            child: fixedPreview.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        fixedPreviewInfo == null
                            ? "Configura el turno y ejecuta la previsualizacion para ver conflictos y overrides por fecha."
                            : "No hay fechas para revisar. Si aparece un conflicto reservado, vas a poder marcar Override desde aca.",
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (
                        var index = 0;
                        index < fixedPreview.length;
                        index++
                      ) ...[
                        if (index > 0) const SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            final item = fixedPreview[index];
                            final date = item["date"]?.toString() ?? "";
                            final isBooked = item["isBooked"] == true;
                            final existingSession =
                                item["existingSession"]
                                    as Map<String, dynamic>?;
                            final isOverridden = overrideDates.contains(date);

                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? colorScheme.errorContainer.withValues(
                                        alpha: 0.45,
                                      )
                                    : colorScheme.tertiaryContainer.withValues(
                                        alpha: 0.55,
                                      ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isBooked
                                      ? colorScheme.error.withValues(
                                          alpha: 0.25,
                                        )
                                      : colorScheme.tertiary.withValues(
                                          alpha: 0.25,
                                        ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Icon(
                                        isBooked
                                            ? Icons.block_outlined
                                            : Icons.event_available_outlined,
                                        size: 18,
                                        color: isBooked
                                            ? colorScheme.error
                                            : colorScheme.tertiary,
                                      ),
                                      Text(date, style: textTheme.titleSmall),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isBooked
                                              ? colorScheme.error
                                              : colorScheme.tertiary,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          isBooked ? "Reservado" : "Libre",
                                          style: textTheme.labelSmall?.copyWith(
                                            color: isBooked
                                                ? colorScheme.onError
                                                : colorScheme.onTertiary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    existingSession == null
                                        ? "No se encontro informacion del turno existente."
                                        : "Sesion #${existingSession["session_id"]} ${isBooked ? "ocupada por un cliente" : "disponible para reemplazo automatico"}",
                                    style: textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  if (isBooked)
                                    SwitchListTile.adaptive(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      value: isOverridden,
                                      title: const Text("Aplicar override"),
                                      subtitle: Text(
                                        isOverridden
                                            ? "Se eliminara el turno reservado para crear el turno fijo."
                                            : "Si no activas override, esta fecha se omitira.",
                                      ),
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked) {
                                            overrideDates.add(date);
                                          } else {
                                            overrideDates.remove(date);
                                          }
                                        });
                                      },
                                    )
                                  else
                                    Text(
                                      "Este turno se reemplaza automaticamente al confirmar.",
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedSetupStep(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return _buildSectionCard(
      context: context,

      child: Column(
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: selectedDayOfWeek,
            decoration: const InputDecoration(
              labelText: "Dia de la semana",
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            items: _dayLabels.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedDayOfWeek = value;
                _resetFixedPreviewState();
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: selectedPartitionPhysicalId,
            decoration: InputDecoration(
              labelText: PhysicalPartitionNaming.singularFromClubPartition(
                selectedSubscriptionClubPartition,
              ),
              prefixIcon: Icon(Icons.sports_tennis_outlined),
            ),
            items: availablePhysicalPartitions
                .map(
                  (partition) => DropdownMenuItem(
                    value: partition.partitionPhysicalId,
                    child: Text(
                      PhysicalPartitionNaming.labelFromPhysicalPartition(
                        partition,
                        fallbackClubPartition: selectedSubscriptionClubPartition,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              PhysicalPartition? selectedPartition;
              for (final partition in availablePhysicalPartitions) {
                if (partition.partitionPhysicalId == value) {
                  selectedPartition = partition;
                  break;
                }
              }
              setState(() {
                selectedPartitionPhysicalId = value;
                selectedDuration =
                    selectedPartition?.defaultSessionDuration ??
                    selectedDuration;
                _resetFixedPreviewState();
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      selectedTime ?? const TimeOfDay(hour: 18, minute: 0),
                );
                if (picked != null) {
                  setState(() {
                    selectedTime = picked;
                    _resetFixedPreviewState();
                  });
                }
              },
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                selectedTimeString == null
                    ? "Seleccionar horario"
                    : "Horario $selectedTimeString",
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: selectedDuration?.toString() ?? "",
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Duracion",
              suffixText: "min",
              prefixIcon: Icon(Icons.timelapse_outlined),
            ),
            onChanged: (value) {
              setState(() {
                selectedDuration = int.tryParse(value);
                _resetFixedPreviewState();
              });
            },
          ),
          if (fixedValidationError != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                fixedValidationError!,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
            ),
          ],
          if (fixedExistingSubscriptionConflict != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Conflicto con turno fijo existente",
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Cliente: ${fixedExistingSubscriptionConflict!["clientFullName"] ?? "-"}",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Horario: ${fixedExistingSubscriptionConflict!["sessionTime"] ?? "-"} (${fixedExistingSubscriptionConflict!["sessionDuration"] ?? "-"} min)",
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openFixedConflictClientProfile,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text("Abrir ficha del cliente"),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverlapStep(BuildContext context) {
    return _buildPreviewPanel(context);
  }

  Widget _buildConfirmationStep(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return _buildSectionCard(
      context: context,
      title: Row(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 8),
          _buildInfoLine(
            context,
            "Tipo",
            isFixedSession ? "Turno fijo" : "Standard",
            icon: isFixedSession ? Icons.event_repeat : Icons.category_outlined,
          ),
          if (isFixedSession) ...[
            const SizedBox(height: 8),
            if (selectedDayOfWeek != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInfoLine(
                  context,
                  "Dia",
                  _dayLabels[selectedDayOfWeek]!,
                  icon: Icons.date_range,
                ),
              ),
            if (selectedTimeString != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInfoLine(
                  context,
                  "Hora",
                  selectedTimeString!,
                  icon: Icons.alarm,
                ),
              ),
            if (selectedDuration != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInfoLine(
                  context,
                  "Duracion",
                  "${selectedDuration} min",
                  icon: Icons.timelapse_outlined,
                ),
              ),
            if (selectedPhysicalPartition != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildInfoLine(
                  context,
                  PhysicalPartitionNaming.singularFromClubPartition(
                    selectedSubscriptionClubPartition,
                  ),
                  "${selectedPhysicalPartition!.physicalIdentifier ?? selectedPhysicalPartition!.partitionPhysicalId}",
                  icon: Icons.grid_view_rounded,
                ),
              ),
            if (fixedPreview.isNotEmpty)
              _buildInfoLine(
                context,
                "Overrides seleccionados",
                "${overrideDates.length} de ${bookedConflictCount} conflictos reservados",
                icon: Icons.done_all_outlined,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomStepActions(
    BuildContext context,
    bool isCompact,
    bool showCreateAction,
  ) {
    final canGoBack = isFixedSession
        ? currentFixedStep != _fixedStepConfigure
        : true;
    final showNext = isFixedSession && currentFixedStep != _fixedStepConfirm;

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCreateAction)
            FilledButton(
              onPressed: isLoading ? null : _confirmSubscription,
              child: const Text("Crear"),
            ),
          if (showNext) ...[
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: isLoading ? null : _goToNextFromCurrentStep,
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Siguiente"),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isLoading ? null : _goBackFromCurrentStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Volver"),
          ),
        ],
      );
    }

    return Row(
      children: [
        TextButton(
          onPressed: isLoading ? null : _cancelWizard,
          child: const Text("Cancelar"),
        ),
        const SizedBox(width: 8),
        if (canGoBack)
          OutlinedButton.icon(
            onPressed: isLoading ? null : _goBackFromCurrentStep,
            icon: const Icon(Icons.arrow_back),
            label: const Text("Volver"),
          ),
        const Spacer(),
        if (showNext)
          FilledButton.tonalIcon(
            onPressed: isLoading ? null : _goToNextFromCurrentStep,
            icon: const Icon(Icons.arrow_forward),
            label: const Text("Siguiente"),
          ),
        if (showNext && showCreateAction) const SizedBox(width: 8),
        if (showCreateAction)
          FilledButton(
            onPressed: isLoading ? null : _confirmSubscription,
            child: const Text("Crear"),
          ),
      ],
    );
  }

  Future<void> _confirmSubscription() async {
    if (isFixedSession) {
      if (selectedDayOfWeek == null ||
          selectedTimeString == null ||
          selectedDuration == null ||
          selectedPartitionPhysicalId == null) {
        setState(() {
          fixedValidationError = "Completa todos los campos de sesion fija.";
        });
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    final payload = {
      "client_id": int.parse(widget.client.clientId!),
      "subscription_id": selectedSubscription!.subscriptionId,
      "created_by_admin": sl<AuthCubit>().state.userCredential!.admin!.adminId,
      if (isFixedSession) "day_of_week": selectedDayOfWeek,
      if (isFixedSession) "session_time": selectedTimeString,
      if (isFixedSession) "session_duration": selectedDuration,
      if (isFixedSession) "partition_physical_id": selectedPartitionPhysicalId,
      if (isFixedSession) "overrideDates": overrideDates.toList(),
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
    final showCreateAction =
        !isFixedSession || currentFixedStep == _fixedStepConfirm;

    return Container(
      height: 450,
      padding: const EdgeInsets.all(16),
      child: Theme(
        data: Theme.of(context).copyWith(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFixedSession) ...[
              Text(
                fixedStepTitle,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fixedStepProgress,
                  minHeight: 6,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentFixedStep == _fixedStepConfigure)
                        _buildFixedSetupStep(context, textTheme, colorScheme),
                      if (currentFixedStep == _fixedStepOverlaps)
                        _buildOverlapStep(context),
                      if (currentFixedStep == _fixedStepConfirm)
                        _buildConfirmationStep(context, textTheme, colorScheme),
                    ],
                  ),
                ),
              ),
            ] else
              Expanded(
                child: SingleChildScrollView(
                  child: _buildConfirmationStep(
                    context,
                    textTheme,
                    colorScheme,
                  ),
                ),
              ),
            const SizedBox(height: 8),

            _buildBottomStepActions(context, true, showCreateAction),
          ],
        ),
      ),
    );
  }
}
