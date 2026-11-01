import 'package:flutter/material.dart';

import '../../../../core/presentation/components/links/entity_links.dart';
import '../../../../domain/entities/gym/gym.dart';
import '../../club_config/widgets/admin_data_table.dart';

/// Primer paso de "Nueva rutina": de dónde partir. Copiar la rutina actual
/// del cliente (lo más común: ajustar pesos), usar otra de base o arrancar
/// con grupos vacíos.
class StartChooser extends StatefulWidget {
  const StartChooser({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.clientRoutines,
    required this.recentRoutines,
    required this.onCopy,
    required this.onEmpty,
  });

  final int clientId;
  final String clientName;
  final List<Routine> clientRoutines;
  final List<Routine> recentRoutines;
  final ValueChanged<Routine> onCopy;
  final ValueChanged<int> onEmpty;

  @override
  State<StartChooser> createState() => _StartChooserState();
}

class _StartChooserState extends State<StartChooser> {
  int _groups = 3;
  bool _onlyClient = false;
  final _tableKey = GlobalKey();

  String get _firstName => widget.clientName.split(' ').first;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final active = widget.clientRoutines.where((r) => r.isActive).firstOrNull;

    final bases = <({Routine routine, int? clientId, String clientName, bool mine})>[
      for (final routine in widget.clientRoutines) (routine: routine, clientId: widget.clientId, clientName: widget.clientName, mine: true),
      for (final routine in widget.recentRoutines.where((r) => r.clientId != widget.clientId))
        (routine: routine, clientId: routine.clientId, clientName: routine.clientName ?? 'Cliente', mine: false),
    ]..sort((a, b) => b.routine.createdAt.compareTo(a.routine.createdAt));
    final visible = _onlyClient ? bases.where((b) => b.mine).toList() : bases;

    Widget option({
      required IconData icon,
      required String title,
      required Widget body,
      required Widget action,
      bool highlighted = false,
      String? badge,
      bool fill = false,
    }) {
      return Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: highlighted ? colorScheme.primary : Colors.transparent, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: highlighted ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: highlighted ? colorScheme.onPrimaryContainer : colorScheme.onSurface),
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
                      child: Text(badge, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSecondaryContainer)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              body,
              const SizedBox(height: 16),
              if (fill) const Spacer(),
              SizedBox(width: double.infinity, child: action),
            ],
          ),
        ),
      );
    }

    List<Widget> options({required bool fill}) => <Widget>[
      if (active != null)
        option(
          icon: Icons.copy_all_outlined,
          title: 'Partir de su rutina actual',
          badge: 'Lo más rápido',
          highlighted: true,
          body: Text(
            '${routineMonthsLabel(active)} · ${active.groups.map((g) => g.name).join(' · ')} · ${active.exercisesCount} ejercicios. '
            'Copiamos todo y ajustás pesos o cambiás lo que haga falta.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          action: FilledButton(onPressed: () => widget.onCopy(active), child: const Text('Copiar y editar')),
          fill: fill,
        ),
      option(
        icon: Icons.person_add_alt_outlined,
        title: 'Copiar de otra rutina',
        body: Text(
          'Una rutina anterior de $_firstName o una que armaste hace poco para otro cliente.',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        action: OutlinedButton(
          onPressed: bases.isEmpty ? null : () => Scrollable.ensureVisible(_tableKey.currentContext!, duration: const Duration(milliseconds: 300)),
          child: const Text('Ver rutinas'),
        ),
        fill: fill,
      ),
      option(
        icon: Icons.add,
        title: 'Empezar de cero',
        highlighted: active == null,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cuántos grupos va a tener', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (var n = 1; n <= 5; n++)
                  ChoiceChip(
                    label: Text('$n'),
                    selected: _groups == n,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _groups = n),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _groups == 1 ? 'Un solo grupo, por ejemplo un full body.' : 'Se crean Grupo 1 a Grupo $_groups. Los renombrás en el editor.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        action: active == null
            ? FilledButton(onPressed: () => widget.onEmpty(_groups), child: const Text('Crear vacía'))
            : OutlinedButton(onPressed: () => widget.onEmpty(_groups), child: const Text('Crear vacía')),
        fill: fill,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('¿De dónde arrancás la rutina de $_firstName?', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                'Elegí un punto de partida. Después podés copiar grupos o ejercicios de cualquier otra rutina.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(builder: (context, constraints) {
                final cards = options(fill: constraints.maxWidth >= 900);
                if (constraints.maxWidth >= 900) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, card) in cards.indexed) ...[if (i > 0) const SizedBox(width: 16), Expanded(child: card)],
                      ],
                    ),
                  );
                }
                final columns = constraints.maxWidth >= 600 ? 2 : 1;
                final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [for (final card in cards) SizedBox(width: width, child: card)],
                );
              }),
              if (bases.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  key: _tableKey,
                  children: [
                    Expanded(child: Text('Rutinas para usar de base', style: textTheme.titleMedium)),
                    ChoiceChip(label: const Text('Todas'), selected: !_onlyClient, onSelected: (_) => setState(() => _onlyClient = false)),
                    const SizedBox(width: 8),
                    ChoiceChip(label: Text('Solo de $_firstName'), selected: _onlyClient, onSelected: (_) => setState(() => _onlyClient = true)),
                  ],
                ),
                const SizedBox(height: 12),
                AdminDataTable(
                  columns: const ['Cliente', 'Grupos', 'Ejercicios', 'Creada', ''],
                  columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2), 2: FixedColumnWidth(110), 3: FixedColumnWidth(150), 4: FixedColumnWidth(150)},
                  rows: [
                    for (final base in visible)
                      [
                        ClientLink(clientId: base.clientId, name: base.clientName),
                        Text('${base.routine.groups.map((g) => g.name).join(' · ')}${base.mine && base.routine.isActive ? ' (actual)' : ''}'),
                        Text('${base.routine.exercisesCount}'),
                        Text(base.mine ? shortDate(base.routine.startDate) : agoLabel(base.routine.createdAt)),
                        TextButton(onPressed: () => widget.onCopy(base.routine), child: const Text('Usar de base')),
                      ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
