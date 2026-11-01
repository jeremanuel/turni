import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/either.dart';
import '../../../domain/entities/client.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../client_page/client_page.dart';

/// Trae el cliente (si no vino de la lista) y lo deja en [ClientInherited]
/// para [child]. Mientras carga, o si falla, muestra [placeholder].
class WrapperClientProvider extends StatefulWidget {
  const WrapperClientProvider({
    super.key,
    required this.clientId,
    required this.child,
    required this.placeholder,
    this.client,
    required this.onUpdateClient,
  });

  final Client? client;
  final int clientId;
  final Widget child;

  /// La pantalla sin cliente todavía: [error] es null mientras carga.
  final Widget Function(String? error, VoidCallback retry) placeholder;
  final Function(Client) onUpdateClient;

  @override
  State<WrapperClientProvider> createState() => _WrapperClientProviderState();
}

class _WrapperClientProviderState extends State<WrapperClientProvider> {
  Client? client;
  String? error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant WrapperClientProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientId != widget.clientId) _initialize();
  }

  void _initialize() {
    client = widget.client;
    error = null;
    if (client == null) _load();
  }

  Future<void> _load() async {
    if (error != null) setState(() => error = null);
    final id = widget.clientId;
    final result = await sl<AdminRepository>().getClientById(id);
    // Llegó tarde: ya se está mostrando otro cliente.
    if (!mounted || id != widget.clientId) return;
    setState(() {
      switch (result) {
        case Right(:final value):
          client = value;
        case Left(:final failure):
          error = failure.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = client;
    if (current == null) return widget.placeholder(error, _load);

    return ClientInherited((newClient) {
      setState(() => client = newClient);
    }, client: current, child: widget.child);
  }
}
