import 'package:flutter/material.dart';
import '../../../../core/presentation/components/loading/app_skeleton.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/presentation/components/permission_lock.dart';
import '../../../../core/utils/permissions.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../core/presentation/components/maps/location_picker_map.dart';
import '../../../../core/services/address_geocoder.dart';
import '../../../../domain/entities/club_info.dart';
import '../../../../domain/repositories/club_info_repository.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../../core/utils/responsive_builder.dart';

/// Datos del establecimiento. Es también el alta del club: un club nuevo
/// llega sin dirección ni ubicación y su dueño los completa acá (con el
/// recorrido de `ClubConfigTour`).
class ClubInfoTab extends StatefulWidget {
  const ClubInfoTab({super.key, this.onLoaded});


  /// Al cargar los datos del club (ej. para ofrecer el recorrido si está incompleto).
  final ValueChanged<ClubInfo>? onLoaded;

  @override
  State<ClubInfoTab> createState() => _ClubInfoTabState();
}

class _ClubInfoTabState extends State<ClubInfoTab> {
  final _repository = sl<ClubInfoRepository>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapKey = GlobalKey<LocationPickerMapState>();

  /// Ubicación confirmada en el mapa (se guarda con "Guardar cambios").
  LatLng? _location;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSearchingAddress = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _repository.getClubInfo();

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
      right: (info) {
        setState(() {
          _nameController.text = info.name ?? '';
          _addressController.text = info.address ?? '';
          _location = info.lat != null && info.lng != null ? LatLng(info.lat!, info.lng!) : null;
          _isLoading = false;
        });
        widget.onLoaded?.call(info);
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final location = _location;
    if (location == null) {
      setState(() => _errorMessage = "Marcá en el mapa dónde está el establecimiento y confirmá la ubicación.");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await _repository.updateClubInfo(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      lat: location.latitude,
      lng: location.longitude,
    );

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (_) {
        setState(() {
          _isSaving = false;
        });
        SnackbarsFunctions.showSuccessSnackbar(context, "Datos del establecimiento guardados.");
      },
    );
  }

  void _resetForm() => _load();

  /// Ubica la dirección escrita en el mapa (pin sin confirmar).
  Future<void> _searchAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      SnackbarsFunctions.showErrorsSnackbar(context, "Escribí la dirección para buscarla en el mapa.");
      return;
    }

    setState(() => _isSearchingAddress = true);
    final point = await AddressGeocoder.search(address);
    if (!mounted) return;
    setState(() => _isSearchingAddress = false);

    if (point == null) {
      SnackbarsFunctions.showErrorsSnackbar(
        context,
        "No encontramos esa dirección. Probá agregando la localidad, o marcala directo en el mapa.",
      );
      return;
    }
    _mapKey.currentState?.placePin(point);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppSkeleton(
      enabled: _isLoading,
      child: SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Datos generales que ven tus clientes al buscar tu establecimiento.",
            ),
            const SizedBox(height: 20),
            const ReadOnlyNotice(permissions: [Permissions.CONFIGURACION_CLUB]),
            PermissionLock(
              permissions: const [Permissions.CONFIGURACION_CLUB],
              child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Datos del establecimiento", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        "Nombre, dirección y ubicación en el mapa.",
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      TourAnchor(
                        id: 'clubInfo.name',
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Nombre del establecimiento",
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) => (value == null || value.trim().isEmpty)
                              ? "Ingresá un nombre."
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TourAnchor(
                        id: 'clubInfo.address',
                        child: TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: "Dirección",
                          helperText: "Calle, número y localidad.",
                          border: const OutlineInputBorder(),
                          suffixIcon: _isSearchingAddress
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: InlineSpinner(),
                                )
                              : IconButton(
                                  tooltip: "Buscar en el mapa",
                                  icon: const Icon(Icons.search),
                                  onPressed: _searchAddress,
                                ),
                        ),
                        onFieldSubmitted: (_) => _searchAddress(),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? "Ingresá una dirección."
                            : null,
                      ),
                      ),
                      const SizedBox(height: 16),
                      Text("Ubicación en el mapa", style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      TourAnchor(
                        id: 'clubInfo.map',
                        // El mapa no se arma con datos de mentira.
                        child: _isLoading
                            ? const Bone(height: 300, width: double.infinity, uniRadius: 8)
                            : LocationPickerMap(
                        key: _mapKey,
                        confirmed: _location,
                        onConfirmed: (point) => setState(() {
                          _location = point;
                          _errorMessage = null;
                        }),
                      ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving ? null : _resetForm,
                            child: const Text("Cancelar"),
                          ),
                          const SizedBox(width: 8),
                          TourAnchor(
                            id: 'clubInfo.save',
                            child: FilledButton(
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const InlineSpinner(size: 16)
                                  : const Text("Guardar cambios"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Logo y fotos", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      "Imagen de portada y logo que ven los clientes.",
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sin logo",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Cambiar logo"),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "PRÓXIMAMENTE",
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onTertiaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
