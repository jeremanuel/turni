import 'package:flutter/material.dart';
import '../../../../core/presentation/components/loading/app_skeleton.dart';

import '../../../../core/presentation/components/permission_lock.dart';
import '../../../../core/utils/permissions.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/session_request_settings.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/presentation/components/onboarding/tour_anchor.dart';

/// Contenido de la antigua `AdminSettingsPage`, ahora como una tab dentro de
/// `ClubConfigPage` en vez de una pantalla propia con su Scaffold/AppBar.
class SessionRequestSettingsTab extends StatefulWidget {
  const SessionRequestSettingsTab({super.key});

  @override
  State<SessionRequestSettingsTab> createState() =>
      _SessionRequestSettingsTabState();
}

class _SessionRequestSettingsTabState
    extends State<SessionRequestSettingsTab> {
  final _adminRepository = sl<AdminRepository>();
  final _formKey = GlobalKey<FormState>();
  final _ttlController = TextEditingController();
  final _minPlaysController = TextEditingController();

  /// El club ofrece a sus clientes pedir un turno fijo.
  bool _fixedRequestsEnabled = false;

  static const _defaultMinPlays = 4;
  static const _maxMinPlays = 52;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ttlController.dispose();
    _minPlaysController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _adminRepository.getSessionRequestSettings();

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
      right: (settings) {
        setState(() {
          _show(settings);
          _isLoading = false;
        });
      },
    );
  }

  void _show(SessionRequestSettings settings) {
    _ttlController.text = settings.ttlMinutes.toString();
    _fixedRequestsEnabled = settings.fixedRequestMinPlays != null;
    _minPlaysController.text = '${settings.fixedRequestMinPlays ?? _defaultMinPlays}';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await _adminRepository.updateSessionRequestSettings(
      SessionRequestSettings(
        ttlMinutes: int.parse(_ttlController.text),
        fixedRequestMinPlays: _fixedRequestsEnabled ? int.parse(_minPlaysController.text) : null,
      ),
    );

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (updated) {
        setState(() {
          _show(updated);
          _isSaving = false;
        });

        SnackbarsFunctions.showSuccessSnackbar(context, "Configuración guardada.");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: _isLoading,
      child: SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveBuilder.isMobile(context) ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        const ReadOnlyNotice(permissions: [Permissions.CONFIGURACION_SOLICITUDES]),
        TourAnchor(id: 'requests.settings', child: PermissionLock(
        permissions: const [Permissions.CONFIGURACION_SOLICITUDES],
        child: Form(
        key: _formKey,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Solicitudes de turno",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Minutos que un cliente puede esperar la aprobación de un turno "
                "antes de que la solicitud expire automáticamente y el horario "
                "vuelva a estar libre.",
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ttlController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Minutos para expirar",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');

                  if (parsed == null || parsed <= 0) {
                    return "Ingresá un número entero mayor a 0.";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text(
                "Pedidos de turno fijo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Un cliente que viene seguido al mismo turno puede pedir "
                "dejarlo fijo desde la app. Cada pedido lo aceptás o lo "
                "rechazás en Turnos fijos.",
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Ofrecerlo a los clientes"),
                value: _fixedRequestsEnabled,
                onChanged: (value) => setState(() => _fixedRequestsEnabled = value),
              ),
              if (_fixedRequestsEnabled) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _minPlaysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Veces que tiene que haber venido",
                    helperText: "Al mismo día y hora. No hace falta que sean semanas seguidas.",
                    helperMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');

                    if (parsed == null || parsed < 1 || parsed > _maxMinPlays) {
                      return "Ingresá un número entero entre 1 y $_maxMinPlays.";
                    }

                    return null;
                  },
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              TourAnchor(id: 'requests.save', child: SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const InlineSpinner(size: 16)
                      : const Text("Guardar"),
                ),
              )),
            ],
          ),
        ),
      ),
      )),
        ],
      ),
    ),
    );
  }
}
