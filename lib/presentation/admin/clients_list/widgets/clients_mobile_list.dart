import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router/app_routes.dart';
import '../../../../core/presentation/components/inputs/label_chip.dart';
import '../../../../domain/entities/client.dart';
import '../../memberships/register_payment_dialog.dart';
import '../bloc/clients_list_bloc.dart';

/// Celular: los clientes como tarjetas con scroll infinito (en lugar de la
/// grilla paginada de escritorio). Usa la misma búsqueda del bloc.
class ClientsMobileList extends StatefulWidget {
  const ClientsMobileList({super.key});

  @override
  State<ClientsMobileList> createState() => _ClientsMobileListState();
}

class _ClientsMobileListState extends State<ClientsMobileList> {
  final _clients = <Client>[];
  final _scroll = ScrollController();
  int _nextPage = 1;
  int? _total;
  bool _loading = false;
  bool _failed = false;
  late final ClientsListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ClientsListBloc>();
    _bloc.onMobileRefetch = _reload;
    _scroll.addListener(_maybeLoadMore);
    _loadMore();
  }

  @override
  void dispose() {
    if (_bloc.onMobileRefetch == _reload) _bloc.onMobileRefetch = null;
    _scroll.dispose();
    super.dispose();
  }

  bool get _hasMore => _total == null || _clients.length < _total!;

  void _reload() {
    if (!mounted) return;
    setState(() {
      _clients.clear();
      _nextPage = 1;
      _total = null;
      _failed = false;
    });
    _loadMore();
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final page = await _bloc.fetchClients(_nextPage, null, null);
      if (!mounted) return;
      setState(() {
        _clients.addAll(page.data);
        _total = page.total;
        _nextPage++;
        _failed = false;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _open(Client client) {
    context.goNamed(
      AppRoutes.CLIENT_ROUTE.name,
      pathParameters: {'clientId': client.clientId!},
      extra: {'client': client, 'bloc': _bloc, 'onUpdateClient': (Client _) => _bloc.refetchClients()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (_clients.isEmpty) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _failed
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('No se pudieron cargar los clientes.'),
                  const SizedBox(height: 8),
                  TextButton(onPressed: _reload, child: const Text('Reintentar')),
                ])
              : Text('No hay clientes para mostrar.', style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.separated(
        controller: _scroll,
        // Abajo deja lugar para el botón flotante.
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: _clients.length + 2,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                _total == null ? '' : '$_total ${_total == 1 ? 'cliente' : 'clientes'}',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            );
          }
          if (index == _clients.length + 1) {
            return _loading
                ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                : const SizedBox.shrink();
          }
          return _ClientCard(client: _clients[index - 1], onTap: () => _open(_clients[index - 1]), onPaymentCreated: () {
            Future.delayed(const Duration(seconds: 3)).then((_) => _bloc.refetchClients());
          });
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.onTap, required this.onPaymentCreated});

  final Client client;
  final VoidCallback onTap;
  final VoidCallback onPaymentCreated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final person = client.person;
    final name = person?.fullName.trim() ?? '';
    final contact = [person?.phone, person?.email].whereType<String>().where((s) => s.trim().isNotEmpty).join(' · ');
    final initials = name.isEmpty
        ? '?'
        : name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();
    final labels = client.labels ?? const [];

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: scheme.surfaceContainerHighest,
                foregroundColor: scheme.onSurface,
                child: Text(initials, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(name.isEmpty ? 'Sin nombre' : name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (contact.isNotEmpty)
                      Text(contact, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (labels.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: [for (final label in labels) Labelchip(label)]),
                    ],
                  ],
                ),
              ),
              RegisterPaymentButton(compact: true, client: client, onPaid: onPaymentCreated),
            ],
          ),
        ),
      ),
    );
  }
}
