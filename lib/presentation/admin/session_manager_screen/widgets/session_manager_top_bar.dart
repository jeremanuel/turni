import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../browser/browser.dart';
import '../../browser/browser_options.dart';
import '../../bulk_sessions/widgets/bulk_sessions_menu_button.dart';
import '../../club_config/club_config_focus.dart';
import '../../club_config/widgets/inactive_partition_hint.dart';
import '../bloc/session_manager_bloc.dart';
import '../bloc/session_manager_event.dart';
import '../bloc/session_manager_state.dart';

/// Barra superior del gestor de turnos (escritorio): día anterior/siguiente,
/// "Hoy", la fecha (abre el calendario), modalidades, buscar y gestión
/// masiva. Reemplaza el carrusel de días y el calendario fijo de la derecha.
class SessionManagerTopBar extends StatefulWidget {
  const SessionManagerTopBar({super.key});

  @override
  State<SessionManagerTopBar> createState() => _SessionManagerTopBarState();
}

class _SessionManagerTopBarState extends State<SessionManagerTopBar> {
  final _calendar = DropdownController();

  void _goTo(DateTime date) => context.read<SessionManagerBloc>().add(SessionChangeDateEvent(date));

  static String dateTitle(DateTime date) {
    final text = DateFormat("EEEE d 'de' MMMM", 'es').format(date);
    return text[0].toUpperCase() + text.substring(1);
  }

  void _openSearch(List<ClubPartition> clubPartitions) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
        child: SizedBox(
          width: 560,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GenericBrowser(browserOptions: BrowserOptions(clubPartitions: clubPartitions)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SessionManagerBloc, SessionManagerState>(
      buildWhen: (previous, current) =>
          previous.currentDate != current.currentDate ||
          previous.clubPartitions != current.clubPartitions ||
          previous.selectedClubPartition != current.selectedClubPartition,
      builder: (context, state) {
        final date = state.currentDate;
        final iconButtonStyle = IconButton.styleFrom(
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        );

        return Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Día anterior',
                style: iconButtonStyle,
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => _goTo(date.subtract(const Duration(days: 1))),
              ),
              IconButton(
                tooltip: 'Día siguiente',
                style: iconButtonStyle,
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => _goTo(date.add(const Duration(days: 1))),
              ),
              const SizedBox(width: 4),
              OutlinedButton(
                onPressed: () => _goTo(DateTime.now()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  foregroundColor: scheme.primary,
                  side: BorderSide(color: scheme.outline),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: const Text('Hoy'),
              ),
              const SizedBox(width: 16),
              DropdownWidget(
                dropdownController: _calendar,
                width: 320,
                menuWidget: SizedBox(
                  width: 320,
                  height: 340,
                  child: CalendarDatePicker2(
                    config: CalendarDatePicker2Config(),
                    value: [date],
                    onValueChanged: (value) {
                      if (value.isEmpty) return;
                      _goTo(value.first);
                      _calendar.hide!();
                    },
                  ),
                ),
                child: Tooltip(
                  message: 'Elegir fecha',
                  child: InkWell(
                    onTap: () => _calendar.toggle!(),
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 44,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dateTitle(date),
                              style: TextStyle(fontSize: 22, height: 28 / 22, color: scheme.onSurface),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.keyboard_arrow_down, size: 20, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(width: 1, height: 32, color: scheme.outlineVariant),
              const SizedBox(width: 16),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final partition in state.clubPartitions) ...[
                        _ModalityChip(
                          partition: partition,
                          selected: partition.club_partition_id == state.selectedClubPartition?.club_partition_id,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Buscar cliente o turno',
                style: iconButtonStyle,
                icon: const Icon(Icons.search, size: 20),
                onPressed: () => _openSearch(state.clubPartitions),
              ),
              const SizedBox(width: 8),
              const BulkSessionsMenuButton(),
            ],
          ),
        );
      },
    );
  }
}

/// Chip de modalidad (32px, radio 8). Inactiva: deshabilitada con el aviso
/// que abre la configuración.
class _ModalityChip extends StatelessWidget {
  const _ModalityChip({required this.partition, required this.selected});

  final ClubPartition partition;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = partition.active;
    final on = selected && enabled;

    final chip = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: on ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: on ? null : Border.all(color: enabled ? scheme.outline : scheme.outlineVariant),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          partition.clubType?.name ?? 'Modalidad',
          style: TextStyle(
            fontSize: 14,
            fontWeight: on ? FontWeight.w500 : FontWeight.w400,
            color: !enabled
                ? scheme.outline
                : on
                    ? scheme.onSecondaryContainer
                    : scheme.onSurfaceVariant,
            decoration: enabled ? null : TextDecoration.lineThrough,
            decorationColor: scheme.outline,
          ),
        ),
      ),
    );

    return InactivePartitionHint(
      inactive: !enabled,
      message: InactivePartitionHint.clubPartitionMessage,
      focus: ClubConfigFocus.clubPartition(partition.club_partition_id ?? 0),
      onConfigClosed: () => context.read<SessionManagerBloc>().add(ReloadClubPartitionsEvent()),
      child: enabled
          ? Semantics(
              button: true,
              selected: selected,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => context.read<SessionManagerBloc>().add(ChangeClubPartitionEvent(partition)),
                  child: chip,
                ),
              ),
            )
          : chip,
    );
  }
}
