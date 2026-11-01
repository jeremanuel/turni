import '../../../../core/utils/either.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../domain/entities/tournament/tournament.dart';
import '../../../../domain/repositories/tournament_repository.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../widgets/tournament_ui.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Qué deportes categoriza el club (asigna su propia categoría a los
/// jugadores y tiene ranking) y la ciudad del club (ranking de la ciudad).
class CategorySettingsTab extends StatefulWidget {
  const CategorySettingsTab({super.key});

  @override
  State<CategorySettingsTab> createState() => _CategorySettingsTabState();
}

class _CategorySettingsTabState extends State<CategorySettingsTab> {
  final _repository = sl<TournamentRepository>();
  final _city = TextEditingController();
  final _province = TextEditingController();

  CategorySettings? _settings;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _city.dispose();
    _province.dispose();
    super.dispose();
  }

  void _apply(CategorySettings s) {
    _settings = s;
    _city.text = s.city?.name ?? '';
    _province.text = s.city?.province ?? '';
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final result = await _repository.getCategorySettings();
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() => _error = failure.message),
      right: (s) => setState(() => _apply(s)),
    );
  }

  Future<void> _toggle(SportSetting sport, bool value) async {
    final result = await _repository.saveCategorySettings(sports: {sport.clubTypeId: value});
    if (!mounted) return;
    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (s) => setState(() => _settings = s),
    );
  }

  Future<void> _saveCity() async {
    setState(() => _saving = true);
    final name = _city.text.trim();
    final result = name.isEmpty
        ? await _repository.saveCategorySettings(clearCity: true)
        : await _repository.saveCategorySettings(city: ClubCity(name: name, province: _province.text.trim().isEmpty ? null : _province.text.trim()));
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      left: (failure) => SnackbarsFunctions.showErrorsSnackbar(context, failure.message),
      right: (s) {
        setState(() => _apply(s));
        SnackbarsFunctions.showSuccessSnackbar(context, 'Ciudad guardada');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return LoadError(message: _error!, onRetry: _load);
    final settings = _settings;
    if (settings == null) return const Center(child: CircularProgressIndicator());
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TourAnchor(id: 'categories.sports', child: SectionCard(
                  title: 'Deportes que categoriza el club',
                  subtitle: 'Si lo activás, el club asigna su propia categoría a cada jugador (desde su ficha) y tiene ranking de ese deporte. '
                      'En tus torneos cuenta esa categoría; si un jugador no tiene, cuenta la que declaró él.',
                  child: Column(
                    children: [
                      if (settings.sports.isEmpty)
                        Text('El club todavía no tiene canchas activas.', style: TextStyle(color: scheme.onSurfaceVariant)),
                      for (final sport in settings.sports)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(sport.name),
                          subtitle: Text(sport.categorizes ? 'Categoriza jugadores · tiene ranking' : 'Los jugadores usan su categoría personal'),
                          value: sport.categorizes,
                          onChanged: (v) => _toggle(sport, v),
                        ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
                TourAnchor(id: 'categories.city', child: SectionCard(
                  title: 'Ciudad del club',
                  subtitle: 'Agrupa el ranking de la ciudad: suma los torneos de todos los clubes de la misma ciudad.',
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 260,
                        child: TextField(controller: _city, decoration: const InputDecoration(labelText: 'Ciudad', hintText: 'Ej.: Tandil')),
                      ),
                      SizedBox(
                        width: 260,
                        child: TextField(controller: _province, decoration: const InputDecoration(labelText: 'Provincia (opcional)')),
                      ),
                      FilledButton(onPressed: _saving ? null : _saveCity, child: const Text('Guardar')),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
