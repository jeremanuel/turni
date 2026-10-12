import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/utils/either.dart';
import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';

/// Busca un cliente del club por nombre (misma búsqueda que la reserva desde
/// la agenda) y avisa cuál se eligió. Limpia el texto al elegir si
/// [clearOnSelect] (para sumar varios, ej. integrantes).
class ClientSearchField extends StatefulWidget {
  const ClientSearchField({
    super.key,
    required this.label,
    required this.onSelected,
    this.excludeIds = const {},
    this.clearOnSelect = false,
    this.validator,
  });

  final String label;
  final ValueChanged<Client> onSelected;

  /// Clientes que no se ofrecen (ej. los ya elegidos).
  final Set<int> excludeIds;
  final bool clearOnSelect;
  final FormFieldValidator<String>? validator;

  @override
  State<ClientSearchField> createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<ClientSearchField> {
  Timer? _debounce;
  int _request = 0;
  TextEditingController? _fieldController;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<Iterable<Client>> _search(String text) async {
    final query = text.trim();
    if (query.length < 2) return const [];

    // Debounce: solo la última búsqueda vuelve con resultados.
    final request = ++_request;
    final completer = Completer<void>();
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), completer.complete);
    await completer.future;
    if (request != _request) return const [];

    final result = await sl<AdminRepository>().getClients(query);
    if (request != _request) return const [];
    return switch (result) {
      Right(:final value) => value.data
          .where((c) => c.clientId != null && !widget.excludeIds.contains(c.intClientId))
          .take(8),
      _ => const <Client>[],
    };
  }

  String _label(Client client) => client.person?.fullName.trim() ?? 'Sin nombre';

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Client>(
      displayStringForOption: _label,
      optionsBuilder: (value) => _search(value.text),
      onSelected: (client) {
        widget.onSelected(client);
        // El Autocomplete deja el nombre en el campo: se limpia para sumar otro.
        if (widget.clearOnSelect) WidgetsBinding.instance.addPostFrameCallback((_) => _fieldController?.clear());
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmit) {
        _fieldController = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Escribí al menos 2 letras',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
          ),
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280, maxWidth: 420),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  for (final client in options)
                    ListTile(
                      dense: true,
                      title: Text(_label(client)),
                      subtitle: (client.person?.phone ?? '').isEmpty ? null : Text(client.person!.phone!),
                      onTap: () => onSelected(client),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
