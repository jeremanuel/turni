import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/presentation/components/inputs/snackbars/snackbars_functions.dart';
import '../../../../core/utils/domain_error.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/repositories/admin_repository.dart';

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
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _adminRepository.getPendingRequestTtlMinutes();

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        });
      },
      right: (minutes) {
        setState(() {
          _ttlController.text = minutes.toString();
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final minutes = int.parse(_ttlController.text);
    final result =
        await _adminRepository.updatePendingRequestTtlMinutes(minutes);

    if (!mounted) return;

    result.when(
      left: (failure) {
        setState(() {
          _errorMessage = failure.message;
          _isSaving = false;
        });
      },
      right: (updatedMinutes) {
        setState(() {
          _ttlController.text = updatedMinutes.toString();
          _isSaving = false;
        });

        SnackbarsFunctions.showSuccessSnackbar(context, "Configuración guardada.");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 40,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Guardar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
