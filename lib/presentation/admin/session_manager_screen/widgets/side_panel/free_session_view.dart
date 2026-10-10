import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../../core/utils/permissions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/router/app_routes.dart';
import '../../../../../core/config/service_locator.dart';
import '../../../../../core/utils/either.dart';
import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/session.dart';
import '../../../../../domain/repositories/admin_repository.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import 'panel_common.dart';

/// Turno libre: precio y "Reservar para" (buscar o elegir un cliente
/// reciente, o crear uno nuevo).
class FreeSessionView extends StatefulWidget {
  const FreeSessionView({super.key, required this.session, required this.header, required this.onCreateClient});

  final Session session;
  final Widget header;
  final VoidCallback onCreateClient;

  @override
  State<FreeSessionView> createState() => _FreeSessionViewState();
}

class _FreeSessionViewState extends State<FreeSessionView> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _request = 0;

  List<Client>? _clients;
  Client? _picked;
  bool _reserving = false;

  @override
  void initState() {
    super.initState();
    _load('');
  }

  @override
  void didUpdateWidget(covariant FreeSessionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.sessionId != widget.session.sessionId) {
      _picked = null;
      _reserving = false;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(String query) async {
    final request = ++_request;
    final result = await sl<AdminRepository>().getClients(query.trim());
    if (!mounted || request != _request) return;
    setState(() {
      _clients = switch (result) {
        Right(:final value) => value.data.take(5).toList(),
        _ => const [],
      };
    });
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _load(text));
  }

  void _reserve() {
    setState(() => _reserving = true);
    context.read<SessionManagerBloc>().add(ReserveEvent(widget.session, _picked!));
    // Si la reserva falla el turno sigue libre: se vuelve a habilitar.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _reserving = false);
    });
  }

  Future<void> _delete() async {
    final ok = await confirmPanelAction(
      context,
      title: 'Eliminar turno',
      message: 'El turno se borra de la agenda. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
    );
    if (!ok || !mounted) return;
    context.read<SessionManagerBloc>().add(DeleteSession(widget.session.sessionId));
    context.go(AppRoutes.SESSION_MANAGER_ROUTE.path);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final searching = _search.text.trim().isNotEmpty;

    return PanelFrame(
      footer: Row(
        children: [
          if (Permissions.can(Permissions.AGENDA_ELIMINAR))
            PanelTextButton(label: 'Eliminar turno', color: scheme.error, onPressed: _delete),
          const Spacer(),
          PanelFilledButton(
            label: 'Reservar turno',
            icon: Icons.check,
            loading: _reserving,
            onPressed: _picked == null || !Permissions.can(Permissions.AGENDA_RESERVAR) ? null : _reserve,
          ),
        ],
      ),
      children: [
        widget.header,
        PanelCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Precio del turno', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              Text(
                panelPrice(widget.session.price),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: scheme.onSurface),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Reservar para', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface)),
            const SizedBox(height: 10),
            TextField(
              controller: _search,
              onChanged: (text) {
                setState(() {});
                _onSearch(text);
              },
              style: TextStyle(fontSize: 14, color: scheme.onSurface),
              decoration: panelInputDecoration(
                context,
                hintText: 'Nombre, teléfono o email',
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Icon(Icons.search, size: 18, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(searching ? 'Resultados' : 'Clientes recientes', style: TextStyle(fontSize: 12, color: scheme.outline)),
            const SizedBox(height: 10),
            if (_clients == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
              )
            else if (_clients!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  searching ? 'No hay clientes que coincidan.' : 'Todavía no hay clientes.',
                  style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                ),
              )
            else
              Semantics(
                label: 'Cliente',
                child: Column(
                  children: [
                    for (final c in _clients!) ...[
                      _ClientOption(
                        client: c,
                        selected: _picked?.clientId == c.clientId,
                        onTap: () => setState(() => _picked = _picked?.clientId == c.clientId ? null : c),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: const Offset(-8, 0),
                child: TextButton.icon(
                  onPressed: Permissions.can(Permissions.AGENDA_RESERVAR) ? widget.onCreateClient : null,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    foregroundColor: scheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    textStyle: panelButtonText(context),
                  ),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Crear cliente nuevo'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClientOption extends StatelessWidget {
  const _ClientOption({required this.client, required this.selected, required this.onTap});

  final Client client;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final person = client.person;
    final fg = selected ? scheme.onSecondaryContainer : scheme.onSurface;
    final meta = [
      if (person?.hasPhone() ?? false) person!.phone!,
      if (person?.hasEmail() ?? false) person!.email!,
    ].join(' · ');

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? scheme.secondaryContainer : scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: selected ? scheme.primary : Colors.transparent),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  PanelAvatar(name: person?.fullName ?? '', size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          person?.fullName ?? 'Cliente',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: fg),
                        ),
                        if (meta.isNotEmpty)
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: scheme.primary, width: 5)
                          : Border.all(color: scheme.outline, width: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
