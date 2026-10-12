import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/utils/physical_partition_naming.dart';
import '../../../../core/utils/thousands_format.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/entities/club_partition.dart';
import '../../../../domain/entities/fixed_session.dart';
import '../../../../domain/entities/physical_partition.dart';
import '../../../../domain/repositories/fixed_session_repository.dart';
import '../../../core/cubit/auth/auth_cubit.dart';
import '../../club_config/widgets/time_field.dart';
import 'client_search_field.dart';
import 'fixed_session_texts.dart';

/// Cancha elegible para un turno fijo: "Pádel · Cancha 2".
class FixedSessionCourtOption {
  FixedSessionCourtOption(this.clubPartition, this.court);

  final ClubPartition clubPartition;
  final PhysicalPartition court;

  int get id => court.partitionPhysicalId;

  String get sport => clubPartition.clubType?.name ?? 'Cancha';

  String get name => PhysicalPartitionNaming.labelFromPhysicalPartition(court, fallbackClubPartition: clubPartition);

  String get label => '$sport · $name';

  /// "Cubierta · 4 jug."
  String get detail {
    final parts = <String>[
      if (court.isCover != null) court.isCover == '1' ? 'Cubierta' : 'Descubierta',
      if (court.maxPlayers != null) '${court.maxPlayers} jug.',
    ];
    return parts.join(' · ');
  }

  /// Canchas activas de los sectores del admin.
  static List<FixedSessionCourtOption> fromAdmin() {
    final partitions = sl<AuthCubit>().state.userCredential?.admin?.clubPartitions ?? const <ClubPartition>[];
    return [
      for (final partition in partitions.where((p) => p.active))
        for (final court in (partition.physicalPartitions ?? const <PhysicalPartition>[]).where((c) => c.active))
          FixedSessionCourtOption(partition, court),
    ];
  }
}

/// Panel lateral para cargar un turno fijo: quiénes, cuándo y dónde, desde
/// cuándo, y a la derecha las próximas 8 semanas (se recalcula sola cuando
/// los datos están completos). Devuelve el resultado del alta.
class FixedSessionSheet extends StatefulWidget {
  const FixedSessionSheet({super.key, this.initialClient, this.initialDayOfWeek});

  final Client? initialClient;
  final int? initialDayOfWeek;

  @override
  State<FixedSessionSheet> createState() => _FixedSessionSheetState();
}

class _FixedSessionSheetState extends State<FixedSessionSheet> {
  final _repository = sl<FixedSessionRepository>();
  final _courts = FixedSessionCourtOption.fromAdmin();
  final _time = TextEditingController();
  final _customDuration = TextEditingController();

  Client? _client;
  final List<Client> _participants = [];
  String? _sport;
  int? _courtId;
  int? _dayOfWeek;
  int _duration = 60;
  DateTime? _startDate;

  Timer? _debounce;
  int _request = 0;
  List<FixedSessionOccurrence>? _preview;
  bool _loadingPreview = false;
  String? _previewError;
  bool _saving = false;
  String? _error;

  static const _durations = [60, 90, 120];

  @override
  void initState() {
    super.initState();
    _client = widget.initialClient;
    _dayOfWeek = widget.initialDayOfWeek;
    _sport = _courts.isEmpty ? null : _courts.first.sport;
    _time.addListener(_schedulePreview);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _time.dispose();
    _customDuration.dispose();
    super.dispose();
  }

  List<String> get _sports => {for (final c in _courts) c.sport}.toList();

  List<FixedSessionCourtOption> get _sportCourts => _courts.where((c) => c.sport == _sport).toList();

  Set<int> get _takenIds => {
        if (_client?.clientId != null) _client!.intClientId,
        for (final p in _participants) p.intClientId,
      };

  bool get _validTime => RegExp(r'^\d{2}:\d{2}$').hasMatch(_time.text.trim());

  FixedSessionDraft? get _draft {
    if (_client == null || _courtId == null || _dayOfWeek == null || !_validTime) return null;
    return FixedSessionDraft(
      clientId: _client!.intClientId,
      participantIds: _participants.map((p) => p.intClientId).toList(),
      partitionPhysicalId: _courtId!,
      dayOfWeek: _dayOfWeek!,
      startTime: _time.text.trim(),
      duration: _duration,
      startDate: _startDate == null ? null : DateFormat('yyyy-MM-dd').format(_startDate!),
    );
  }

  void _update(VoidCallback change) {
    setState(change);
    _schedulePreview();
  }

  void _schedulePreview() {
    _debounce?.cancel();
    if (_draft == null) {
      if (_preview != null || _previewError != null) {
        setState(() {
          _preview = null;
          _previewError = null;
        });
      }
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), _loadPreview);
  }

  Future<void> _loadPreview() async {
    final draft = _draft;
    if (draft == null) return;
    final request = ++_request;
    setState(() => _loadingPreview = true);
    final result = await _repository.preview(draft);
    if (!mounted || request != _request) return;
    setState(() {
      _loadingPreview = false;
      switch (result) {
        case Right(:final value):
          _preview = value;
          _previewError = null;
        case Left(:final failure):
          _preview = null;
          _previewError = failure.message;
      }
    });
  }

  Future<void> _submit() async {
    final draft = _draft;
    if (draft == null) {
      setState(() => _error = 'Completá titular, cancha, día y hora.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.create(draft);
    if (!mounted) return;
    switch (result) {
      case Right(:final value):
        Navigator.of(context).pop(value);
      case Left(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = _dayOfWeek == null ? null : (_dayOfWeek == 0 ? 7 : _dayOfWeek!);
    final first = weekday == null ? today : today.add(Duration(days: (weekday - today.weekday + 7) % 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? first,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: weekday == null ? null : (d) => d.weekday == weekday,
      helpText: 'Desde cuándo',
    );
    if (picked != null) _update(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      elevation: 8,
      child: SizedBox(
        width: 720,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.event_repeat, color: scheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nuevo turno fijo', style: textTheme.titleLarge),
                        Text(
                          'Mismo día, hora y cancha todas las semanas. Se cargan 8 semanas y se van sumando solas.',
                          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section(context, '1 · Quiénes'),
                          _whoSection(context),
                          const SizedBox(height: 24),
                          _section(context, '2 · Cuándo y dónde'),
                          _whereSection(context),
                          const SizedBox(height: 24),
                          _section(context, '3 · Desde cuándo'),
                          OutlinedButton.icon(
                            onPressed: _pickStartDate,
                            icon: const Icon(Icons.event, size: 18),
                            label: Text(_startDate == null
                                ? 'Desde hoy'
                                : DateFormat("EEEE d/MM", 'es').format(_startDate!)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  VerticalDivider(width: 1, color: scheme.outlineVariant),
                  SizedBox(width: 280, child: _previewPanel(context)),
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
              child: Row(
                children: [
                  if (_error != null)
                    Expanded(child: Text(_error!, style: TextStyle(color: scheme.error)))
                  else
                    const Spacer(),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving || _courts.isEmpty ? null : _submit,
                    child: const Text('Cargar turno fijo'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _whoSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_client != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _Initials(name: _client!.person?.fullName ?? '', background: scheme.primaryContainer, foreground: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_client!.person?.fullName.trim() ?? 'Cliente', style: textTheme.titleSmall),
                      Text(
                        ['Titular', if ((_client!.person?.phone ?? '').isNotEmpty) _client!.person!.phone!].join(' · '),
                        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (widget.initialClient == null)
                  TextButton(onPressed: () => _update(() => _client = null), child: const Text('Cambiar')),
              ],
            ),
          )
        else
          ClientSearchField(
            label: 'Buscar titular',
            excludeIds: _takenIds,
            onSelected: (client) => _update(() => _client = client),
          ),
        const SizedBox(height: 12),
        if (_participants.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in _participants)
                InputChip(
                  label: Text(p.person?.fullName.trim() ?? 'Cliente'),
                  onDeleted: () => _update(() => _participants.remove(p)),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClientSearchField(
          label: 'Sumar integrante (opcional)',
          excludeIds: _takenIds,
          clearOnSelect: true,
          onSelected: (client) => _update(() => _participants.add(client)),
        ),
        const SizedBox(height: 6),
        Text(
          'Los integrantes ven el turno en su app y pueden pagar su parte.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _whereSection(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final custom = !_durations.contains(_duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sport in _sports)
              ChoiceChip(
                label: Text(sport),
                selected: _sport == sport,
                onSelected: (_) => _update(() {
                  _sport = sport;
                  if (_courts.where((c) => c.id == _courtId).firstOrNull?.sport != sport) _courtId = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: [
            for (final court in _sportCourts)
              _CourtTile(
                option: court,
                selected: court.id == _courtId,
                onTap: () => _update(() {
                  _courtId = court.id;
                  final minutes = court.court.defaultSessionDuration;
                  if (minutes != null) _duration = minutes;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Día', style: textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            for (final day in fixedSessionWeekOrder)
              _DayButton(
                label: fixedSessionDayNames[day].substring(0, 1) == 'M' && day == 3 ? 'X' : fixedSessionDayNames[day].substring(0, 1),
                tooltip: fixedSessionDayNames[day],
                selected: _dayOfWeek == day,
                onTap: () => _update(() {
                  _dayOfWeek = day;
                  _startDate = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 140,
              child: TimeField(
                controller: _time,
                decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final minutes in _durations)
                        ChoiceChip(
                          label: Text('$minutes min'),
                          selected: _duration == minutes,
                          onSelected: (_) => _update(() => _duration = minutes),
                        ),
                      SizedBox(
                        width: 96,
                        child: TextField(
                          controller: _customDuration,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: custom ? '$_duration min' : 'Otra',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            final minutes = int.tryParse(value.trim());
                            if (minutes != null && minutes >= 15 && minutes <= 600) _update(() => _duration = minutes);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _previewPanel(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final preview = _preview;
    final dayName = _dayOfWeek == null ? 'días' : fixedSessionDayNames[_dayOfWeek!].toLowerCase();

    final Widget body;
    if (_draft == null) {
      body = Text(
        'Elegí titular, cancha, día y hora para ver cómo quedan las próximas semanas.',
        style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    } else if (_previewError != null) {
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
        child: Text(_previewError!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13)),
      );
    } else if (preview == null) {
      body = const LinearProgressIndicator();
    } else {
      final free = preview.where((o) => !o.status.isConflict).length;
      final busy = preview.where((o) => o.status.isConflict).toList();
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
            child: Text(
              busy.isEmpty
                  ? 'Los $free $dayName están libres.'
                  : '$free de ${preview.length} $dayName disponibles. '
                      '${busy.map((o) => FixedSessionTexts.shortDate(o.date)).join(', ')} ya '
                      '${busy.length == 1 ? 'está ocupado' : 'están ocupados'}: esos días no se tocan.',
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          for (final o in preview) _PreviewRow(occurrence: o),
        ],
      );
    }

    final price = preview?.firstWhere((o) => o.price != null, orElse: () => preview.first).price;

    return Container(
      color: scheme.surfaceContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Próximas 8 semanas', style: textTheme.titleSmall)),
              if (_loadingPreview && preview != null)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: body)),
          if (price != null) ...[
            Divider(color: scheme.outlineVariant),
            Text('Precio por turno según la tarifa', style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text('\$ ${ThousandsFormat.formatPrice(price)}', style: textTheme.titleMedium),
          ],
        ],
      ),
    );
  }
}

class _CourtTile extends StatelessWidget {
  const _CourtTile({required this.option, required this.selected, required this.onTap});

  final FixedSessionCourtOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                ),
              ),
              if (option.detail.isNotEmpty)
                Text(
                  option.detail,
                  style: TextStyle(fontSize: 11, color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayButton extends StatelessWidget {
  const _DayButton({required this.label, required this.tooltip, required this.selected, required this.onTap});

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Material(
          color: selected ? scheme.primary : Colors.transparent,
          shape: CircleBorder(side: selected ? BorderSide.none : BorderSide(color: scheme.outline)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w500, color: selected ? scheme.onPrimary : scheme.onSurface),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.occurrence});

  final FixedSessionOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final conflict = occurrence.status.isConflict;
    final label = switch (occurrence.status) {
      FixedSessionOccurrenceStatus.created => 'Se crea el turno',
      FixedSessionOccurrenceStatus.freeSession => 'Usa el turno libre',
      _ => FixedSessionTexts.conflictLabel(occurrence),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: conflict ? scheme.errorContainer.withValues(alpha: 0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: conflict ? scheme.error : (occurrence.status == FixedSessionOccurrenceStatus.created ? scheme.primary : scheme.secondary),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(width: 72, child: Text(FixedSessionTexts.shortDate(occurrence.date), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: conflict ? scheme.error : scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.background, required this.foreground});

  final String name;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return CircleAvatar(
      radius: 18,
      backgroundColor: background,
      child: Text(initials, style: TextStyle(color: foreground, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}
