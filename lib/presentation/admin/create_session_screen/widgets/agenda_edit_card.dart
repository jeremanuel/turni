import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/dropdown_widget.dart';
import '../../../../domain/entities/session.dart';
import '../bloc/create_sesssions_form_bloc.dart';
import 'rework_styles.dart';

class AgendaEditCard extends StatefulWidget {
  const AgendaEditCard({
    super.key,
    required this.session,
    required this.height,
    this.autoOpen = false,
    this.onAutoOpened,
  });

  final Session session;
  final double height;

  /// true cuando esta card corresponde al turno que se acaba de crear
  /// clickeando un espacio libre — abre el popover de edición solo una vez,
  /// apenas se monta/actualiza con esta bandera en true.
  final bool autoOpen;
  final VoidCallback? onAutoOpened;

  @override
  State<AgendaEditCard> createState() => _AgendaEditCardState();
}

class _AgendaEditCardState extends State<AgendaEditCard> {
  final dropdownController = DropdownController();

  @override
  void initState() {
    super.initState();
    _maybeAutoOpen();
  }

  @override
  void didUpdateWidget(covariant AgendaEditCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoOpen && !oldWidget.autoOpen) _maybeAutoOpen();
  }

  void _maybeAutoOpen() {
    if (!widget.autoOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      dropdownController.show!();
      widget.onAutoOpened?.call();
    });
  }

  void _nudge(Session session, int deltaMinutes) {
    final totalMinutes = (session.startTime.hour * 60 + session.startTime.minute + deltaMinutes)
        .clamp(RW.firstHour * 60, RW.lastHour * 60 - 15);
    final newStart = DateTime(
      session.startTime.year,
      session.startTime.month,
      session.startTime.day,
      totalMinutes ~/ 60,
      totalMinutes % 60,
    );
    sl<CreateSesssionsFormBloc>().add(
      EditSession(session, session.copyWith(startTime: newStart)),
    );
  }

  void _setDuration(Session session, int minutes) {
    sl<CreateSesssionsFormBloc>().add(
      EditSession(session, session.copyWith(duration: minutes)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return DropdownWidget(
      aligned: const Aligned(
        follower: Alignment.topLeft,
        target: Alignment.bottomLeft,
        offset: Offset(0, 6),
      ),
      width: 230,
      obscureBackground: false,
      dropdownController: dropdownController,
      menuWidget: SessionEditPopover(
        session: session,
        onNudge: (delta) => _nudge(session, delta),
        onSetDuration: (minutes) => _setDuration(session, minutes),
        onDelete: () {
          sl<CreateSesssionsFormBloc>().add(DeleteSession(session));
          dropdownController.hide!();
        },
        onClose: () => dropdownController.hide!(),
      ),
      child: _buildBlock(context),
    );
  }

  Widget _buildBlock(BuildContext context) {
    final session = widget.session;
    final end = session.endTime as DateTime;
    final accent = RW.accentForDuration(session.duration);
    final label =
        '${DateFormat.Hm().format(session.startTime)} – ${DateFormat.Hm().format(end)}';
    final showBadge = widget.height >= 44;

    return Stack(
      children: [
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => dropdownController.show!(),
              borderRadius: BorderRadius.circular(RW.blockRadius),
              child: Container(
                decoration: BoxDecoration(
                  color: RW.primaryContainer,
                  borderRadius: BorderRadius.circular(RW.blockRadius),
                  border: Border(left: BorderSide(color: accent, width: 4)),
                ),
                padding: const EdgeInsets.fromLTRB(10, 6, 30, 6),
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RW.onPrimaryContainer,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (showBadge) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(RW.chipRadius),
                        ),
                        child: Text(
                          '${session.duration} min',
                          style: const TextStyle(fontSize: 10, color: RW.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 5,
          right: 5,
          child: InkWell(
            onTap: () => sl<CreateSesssionsFormBloc>().add(DeleteSession(session)),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                '×',
                style: TextStyle(fontSize: 11, color: RW.onPrimaryContainer, height: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Editor inline de un turno — nudges de hora/15min para el inicio y chips
/// de duración, en vez de un formulario completo: acá se busca la fidelidad
/// 1:1 con el diseño aprobado, que edita el bloque sin salir del timeline.
/// Las acciones son callbacks (no despacha eventos directamente) para poder
/// reusarse tanto en la plantilla (paso "Horarios") como en la vista por
/// cancha (paso "Canchas"), donde cada una dispara eventos distintos.
class SessionEditPopover extends StatelessWidget {
  const SessionEditPopover({
    super.key,
    required this.session,
    required this.onNudge,
    required this.onSetDuration,
    required this.onDelete,
    required this.onClose,
  });

  final Session session;
  final ValueChanged<int> onNudge;
  final ValueChanged<int> onSetDuration;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  static const List<int> _durationOptions = [30, 60, 90];

  @override
  Widget build(BuildContext context) {
    final end = session.endTime as DateTime;
    final label =
        '${DateFormat.Hm().format(session.startTime)} – ${DateFormat.Hm().format(end)}';

    return Container(
      decoration: BoxDecoration(
        color: RW.panel,
        border: Border.all(color: RW.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 12, color: RW.onSurfaceVariant),
              children: [
                const TextSpan(text: 'Horario: '),
                TextSpan(
                  text: label,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: RW.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _NudgeButton(label: '−', onPressed: () => onNudge(-60)),
              const Expanded(
                child: Text('hora', style: RW.tSmall, textAlign: TextAlign.center),
              ),
              _NudgeButton(label: '+', onPressed: () => onNudge(60)),
              const SizedBox(width: 8),
              _NudgeButton(label: '−', onPressed: () => onNudge(-15)),
              const Expanded(
                child: Text('15 min', style: RW.tSmall, textAlign: TextAlign.center),
              ),
              _NudgeButton(label: '+', onPressed: () => onNudge(15)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Duración', style: RW.tSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final minutes in _durationOptions) ...[
                if (minutes != _durationOptions.first) const SizedBox(width: 6),
                Expanded(
                  child: _DurationChip(
                    minutes: minutes,
                    selected: session.duration == minutes,
                    onTap: () => onSetDuration(minutes),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: RW.error,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Eliminar', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: onClose,
                style: TextButton.styleFrom(
                  backgroundColor: RW.surfaceHigh,
                  foregroundColor: RW.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Listo', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: RW.outlineVariant),
          color: RW.rail,
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 14, color: RW.onSurfaceVariant)),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.minutes, required this.selected, required this.onTap});

  final int minutes;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: selected ? RW.primaryContainer : Colors.transparent,
          border: Border.all(color: selected ? RW.primaryContainer : RW.outlineVariant),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            fontSize: 11,
            color: selected ? RW.onPrimaryContainer : RW.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
