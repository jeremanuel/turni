import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Tiles en oscuro: invierte y rota el tono 180° (el `invert(1)
/// hue-rotate(180deg)` de CSS). A diferencia de `darkModeTileBuilder`, que
/// solo invierte, el agua sigue azul y los parques verdes.
Widget _darkTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      0.574, -1.43, -0.144, 0, 255, //
      -0.426, -0.43, -0.144, 0, 255, //
      -0.426, -1.43, 0.856, 0, 255, //
      0, 0, 0, 1, 0,
    ]),
    child: tileWidget,
  );
}

/// Mapa para elegir una ubicación: se toca el mapa para poner el pin y
/// "Confirmar ubicación" (habilitado recién con un pin nuevo) la pasa a
/// [onConfirmed]. Así nadie carga latitud y longitud a mano.
///
/// Tiles de OpenStreetMap, como el mapa de la app del cliente: gratis y sin
/// API key. En dark se invierten con `darkModeTileBuilder`.
class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({
    super.key,
    required this.confirmed,
    required this.onConfirmed,
    this.enabled = true,
    this.height = 300,
  });

  /// Ubicación ya confirmada (la guardada o la última confirmada), o `null`.
  final LatLng? confirmed;

  final ValueChanged<LatLng> onConfirmed;

  final bool enabled;

  final double height;

  /// Sin ubicación todavía: el mapa arranca en el centro de Buenos Aires.
  static const _defaultCenter = LatLng(-34.6037, -58.3816);

  @override
  State<LocationPickerMap> createState() => LocationPickerMapState();
}

class LocationPickerMapState extends State<LocationPickerMap> {
  final _mapController = MapController();

  /// Pin puesto y todavía sin confirmar.
  LatLng? _pending;

  LatLng? get _pin => _pending ?? widget.confirmed;

  bool get _canConfirm => widget.enabled && _pending != null && _pending != widget.confirmed;

  @override
  void didUpdateWidget(covariant LocationPickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se recargó la ubicación guardada (ej. "Cancelar" en el formulario).
    if (widget.confirmed != oldWidget.confirmed && _pending != null && _pending != widget.confirmed) {
      _pending = null;
    }
  }

  /// Pone el pin (sin confirmar) y centra el mapa ahí. Lo usa la búsqueda
  /// por dirección del formulario.
  void placePin(LatLng point) {
    setState(() => _pending = point);
    _mapController.move(point, 16);
  }

  void _confirm() {
    final pending = _pending;
    if (pending == null) return;
    widget.onConfirmed(pending);
    setState(() => _pending = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final pin = _pin;
    final hasPending = _pending != null && _pending != widget.confirmed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
            color: colorScheme.surfaceContainerLow,
          ),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.confirmed ?? LocationPickerMap._defaultCenter,
              initialZoom: widget.confirmed != null ? 16 : 12,
              interactionOptions: InteractionOptions(
                flags: widget.enabled ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
              ),
              onTap: widget.enabled ? (_, point) => setState(() => _pending = point) : null,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.turni.admin',
                tileBuilder: dark ? _darkTileBuilder : null,
              ),
              if (pin != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pin,
                      width: 40,
                      height: 40,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        size: 40,
                        // Sin confirmar, el pin va en el color de acento
                        // secundario para que se note que falta confirmarlo.
                        color: hasPending ? colorScheme.tertiary : colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [TextSourceAttribution('© OpenStreetMap contributors')],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              hasPending
                  ? Icons.touch_app_outlined
                  : widget.confirmed != null
                      ? Icons.check_circle
                      : Icons.info_outline,
              size: 18,
              color: !hasPending && widget.confirmed != null ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasPending
                    ? 'Confirmá la ubicación para usarla.'
                    : widget.confirmed != null
                        ? 'Ubicación confirmada. Tocá el mapa para moverla.'
                        : 'Tocá el mapa donde está el establecimiento.',
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _canConfirm ? _confirm : null,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Confirmar ubicación'),
            ),
          ],
        ),
      ],
    );
  }
}
