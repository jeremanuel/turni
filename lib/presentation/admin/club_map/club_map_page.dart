import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/club_map/club_map.dart';
import '../../../domain/repositories/club_map_repository.dart';
import 'widgets/club_map_editor.dart';
import 'widgets/club_map_overview.dart';
import 'widgets/club_map_sport_picker.dart';

enum _Step { overview, pickSports, editor }

/// Mapa del club: un solo plano con todas las canchas, a escala real.
///
/// Flujo: el mapa (lectura) → elegir qué deportes ubicar (y, si no hay plano,
/// el tamaño del predio) → editor. Cada deporte se suma al plano una sola vez.
class ClubMapPage extends StatefulWidget {
  final ClubMapRepository? repository;

  const ClubMapPage({super.key, this.repository});

  @override
  State<ClubMapPage> createState() => _ClubMapPageState();
}

class _ClubMapPageState extends State<ClubMapPage> {
  late final ClubMapRepository _repository = widget.repository ?? sl<ClubMapRepository>();

  ClubMapView? _view;
  String? _loadError;
  _Step _step = _Step.overview;

  // Lo que se eligió en el paso 1, para el editor.
  Set<int> _editorPartitions = {};
  int _editorWidthM = 0;
  int _editorHeightM = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    final result = await _repository.getClubMap();
    if (!mounted) return;
    result.when(left: (failure) => setState(() => _loadError = failure.message), right: (view) => setState(() => _view = view));
  }

  void _openEditor({required Set<int> extraPartitions, ClubMapSizePreset? size}) {
    final view = _view!;
    final map = view.map;
    final preset = size ?? ClubMapSizePreset.all.firstWhere((p) => p.id == ClubMapSizePreset.defaultPreset);

    setState(() {
      _editorPartitions = {if (map != null) ...view.partitionIdsInMap(map.elements), ...extraPartitions};
      _editorWidthM = map?.widthM ?? preset.widthM;
      _editorHeightM = map?.heightM ?? preset.heightM;
      _step = _Step.editor;
    });
  }

  Future<String?> _save(ClubMapLayout layout) async {
    final result = await _repository.saveClubMap(layout);
    String? error;
    result.when(
      left: (failure) => error = failure.message,
      right: (view) {
        if (!mounted) return;
        setState(() {
          _view = view;
          _step = _Step.overview;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plano del club guardado')));
      },
    );
    return error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No se pudo cargar el mapa del club.', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    final view = _view;
    if (view == null) return const Center(child: CircularProgressIndicator());

    switch (_step) {
      case _Step.overview:
        return ClubMapOverview(
          view: view,
          onEdit: () => _openEditor(extraPartitions: const {}),
          onAddSports: () => setState(() => _step = _Step.pickSports),
          onSeeSessions: () => context.go(AppRoutes.SESSION_MANAGER_ROUTE.path),
        );
      case _Step.pickSports:
        return ClubMapSportPicker(
          view: view,
          onCancel: () => setState(() => _step = _Step.overview),
          onContinue: (partitionIds, size) => _openEditor(extraPartitions: partitionIds, size: size),
        );
      case _Step.editor:
        return ClubMapEditor(
          view: view,
          partitionIds: _editorPartitions,
          initialWidthM: _editorWidthM,
          initialHeightM: _editorHeightM,
          isNewMap: view.map == null,
          onCancel: () => setState(() => _step = _Step.overview),
          onSave: _save,
        );
    }
  }
}
