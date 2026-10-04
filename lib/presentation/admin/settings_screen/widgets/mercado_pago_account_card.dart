import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/payment/club_payment_account_status.dart';
import '../../../../domain/repositories/club_payment_account_repository.dart';

/// Abre la URL de autorización de Mercado Pago. Inyectable para tests.
typedef AuthorizationUrlLauncher = Future<bool> Function(Uri url);

Future<bool> _defaultLauncher(Uri url) {
  // En web abre una pestaña nueva; la app queda en esta, esperando.
  return launchUrl(url, mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
}

/// Sección "Cobros online" de la configuración del club: vincular /
/// desvincular la cuenta de Mercado Pago del club, a la que se acreditan los
/// turnos que los clientes pagan desde la app.
///
/// El vínculo es un OAuth: "Vincular" pide al backend la URL de autorización
/// y la abre en otra pestaña; el admin inicia sesión con la cuenta de MP del
/// club y autoriza; Mercado Pago vuelve al backend (no a esta app). Por eso,
/// al volver a esta pestaña se refresca el estado solo (lifecycle `resumed`),
/// y además hay un botón para hacerlo a mano.
class MercadoPagoAccountCard extends StatefulWidget {
  final ClubPaymentAccountRepository? repository;
  final AuthorizationUrlLauncher? launcher;

  const MercadoPagoAccountCard({super.key, this.repository, this.launcher});

  @override
  State<MercadoPagoAccountCard> createState() => _MercadoPagoAccountCardState();
}

class _MercadoPagoAccountCardState extends State<MercadoPagoAccountCard> with WidgetsBindingObserver {
  late final ClubPaymentAccountRepository _repository = widget.repository ?? sl<ClubPaymentAccountRepository>();
  late final AuthorizationUrlLauncher _launch = widget.launcher ?? _defaultLauncher;

  ClubPaymentAccountStatus? _status;
  bool _isLoading = true;
  bool _isBusy = false;

  /// Se abrió la pantalla de autorización y todavía no vimos el vínculo activo.
  bool _awaitingAuthorization = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingAuthorization) {
      _loadStatus();
    }
  }

  Future<void> _loadStatus() async {
    setState(() {
      _isLoading = _status == null;
      _errorMessage = null;
    });

    final result = await _repository.getMercadoPagoStatus();
    if (!mounted) return;

    result.when(
      left: (failure) => setState(() {
        _errorMessage = failure.message;
        _isLoading = false;
      }),
      right: (status) => setState(() {
        _status = status;
        _isLoading = false;
        if (status.state == ClubPaymentAccountState.active) _awaitingAuthorization = false;
      }),
    );
  }

  Future<void> _startLink() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    final result = await _repository.startMercadoPagoLink();
    if (!mounted) return;

    await result.when(
      left: (failure) async => setState(() => _errorMessage = failure.message),
      right: (url) async {
        final opened = await _launch(Uri.parse(url));
        if (!mounted) return;
        setState(() {
          if (opened) {
            _awaitingAuthorization = true;
          } else {
            _errorMessage = "No se pudo abrir Mercado Pago. Revisá que el navegador no haya bloqueado la ventana.";
          }
        });
      },
    );

    if (mounted) setState(() => _isBusy = false);
  }

  Future<void> _unlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Desvincular Mercado Pago"),
        content: const Text(
          "Los clientes no van a poder pagar turnos online hasta que vuelvas a vincular una cuenta. "
          "Los pagos ya hechos no se ven afectados.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Cancelar")),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Desvincular")),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    final result = await _repository.unlinkMercadoPago();
    if (!mounted) return;

    result.when(
      left: (failure) => setState(() {
        _errorMessage = failure.message;
        _isBusy = false;
      }),
      right: (_) {
        setState(() {
          _status = const ClubPaymentAccountStatus.notLinked();
          _isBusy = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta de Mercado Pago desvinculada.")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Cobros online", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          "Vinculá la cuenta de Mercado Pago del club para que los clientes puedan pagar sus turnos "
          "desde la app. La plata se acredita directo en esa cuenta.",
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
        else
          _buildStatus(theme),
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
        ],
      ],
    );
  }

  Widget _buildStatus(ThemeData theme) {
    final status = _status;
    if (status == null) {
      // Falló la primera carga: solo se puede reintentar.
      return OutlinedButton.icon(
        onPressed: _loadStatus,
        icon: const Icon(Icons.refresh),
        label: const Text("Reintentar"),
      );
    }

    if (_awaitingAuthorization && status.state != ClubPaymentAccountState.active) {
      return _StatusPanel(
        icon: Icons.open_in_new,
        color: theme.colorScheme.primary,
        title: "Esperando la autorización",
        description: "Terminá de autorizar en la pestaña de Mercado Pago que se abrió y volvé acá.",
        actions: [
          FilledButton.icon(
            onPressed: _isLoading ? null : _loadStatus,
            icon: const Icon(Icons.refresh),
            label: const Text("Ya autoricé, actualizar"),
          ),
          TextButton(onPressed: _isBusy ? null : _startLink, child: const Text("Abrir de nuevo")),
        ],
      );
    }

    switch (status.state) {
      case ClubPaymentAccountState.active:
        return _StatusPanel(
          icon: Icons.check_circle,
          color: Colors.green.shade700,
          title: "Cuenta vinculada",
          description: [
            if (status.providerUserId != null) "Usuario de Mercado Pago: ${status.providerUserId}",
            if (status.liveMode == false) "Modo prueba (sandbox): no se cobra plata real.",
            if (status.expiresAt != null)
              "Permiso vigente hasta el ${DateFormat('dd/MM/yyyy').format(status.expiresAt!)} (se renueva solo).",
          ].join("\n"),
          actions: [
            OutlinedButton(onPressed: _isBusy ? null : _unlink, child: const Text("Desvincular")),
          ],
        );
      case ClubPaymentAccountState.refreshFailed:
        return _StatusPanel(
          icon: Icons.warning_amber_rounded,
          color: theme.colorScheme.error,
          title: "Hay que volver a vincular la cuenta",
          description: "Mercado Pago dejó de aceptar el permiso del club. Mientras tanto, los clientes no pueden pagar online.",
          actions: [_linkButton(label: "Volver a vincular")],
        );
      case ClubPaymentAccountState.notLinked:
        return _StatusPanel(
          icon: Icons.link_off,
          color: theme.colorScheme.outline,
          title: "Sin cuenta vinculada",
          description: "Los clientes todavía no pueden pagar turnos online.",
          actions: [_linkButton(label: "Vincular Mercado Pago")],
        );
    }
  }

  Widget _linkButton({required String label}) {
    return FilledButton.icon(
      onPressed: _isBusy ? null : _startLink,
      icon: _isBusy
          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.link),
      label: Text(label),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final List<Widget> actions;

  const _StatusPanel({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(description),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}
