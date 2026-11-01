import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/client.dart';
import '../../../../domain/repositories/admin_repository.dart';
import '../../../config/router/app_routes.dart';
import '../../../config/service_locator.dart';
import '../../../utils/either.dart';
import '../../../utils/responsive_builder.dart';
import '../links/entity_links.dart';
import 'dropdown_placement.dart';

/// Dato opcional a la derecha de cada fila de cliente ("Debe $18.000",
/// "Abono activo", "Ya está"). Lo da cada pantalla. [disabled]: la fila se
/// ve atenuada y no se puede elegir ("Tiene otro fijo a esa hora").
class ClientRowInfo {
  const ClientRowInfo(this.text, {this.error = false, this.disabled = false});

  final String text;

  /// Pinta el dato en `error` con borde `errorContainer` (una deuda).
  final bool error;
  final bool disabled;
}

/// Buscador de clientes del Design System: un campo que despliega la lista de
/// clientes pegada debajo mientras se escribe (en el celular abre una pantalla
/// completa). Sin texto muestra los recientes; al pie siempre está "Crear
/// cliente", que lleva lo escrito al alta.
///
/// - Uno: [ClientSearchField]. Al elegir, el campo pasa a ser el cliente (mismo
///   alto) con una X para cambiarlo.
/// - Varios: [ClientSearchField.multiple]. Los elegidos quedan como chips dentro
///   del campo; elegir no cierra la lista.
/// - [dense]: 40 de alto, para filtros arriba de una tabla.
///
/// Para un `FormBuilder`, usar [ClientSearchFormField].
class ClientSearchField extends StatefulWidget {
  const ClientSearchField({
    super.key,
    this.label,
    required this.value,
    required ValueChanged<Client?> this.onChanged,
    this.hintText = 'Buscar por nombre, email o teléfono',
    this.dense = false,
    this.enabled = true,
    this.locked = false,
    this.errorText,
    this.rowInfo,
    this.onCreate,
    this.showCreate = true,
    this.autofocus = false,
  })  : multiple = false,
        values = const [],
        onValuesChanged = null,
        max = null;

  const ClientSearchField.multiple({
    super.key,
    this.label,
    required this.values,
    required ValueChanged<List<Client>> this.onValuesChanged,
    this.max,
    this.hintText = 'Sumar…',
    this.dense = false,
    this.enabled = true,
    this.errorText,
    this.rowInfo,
    this.onCreate,
    this.showCreate = true,
    this.autofocus = false,
  })  : multiple = true,
        value = null,
        onChanged = null,
        locked = false;

  final String? label;
  final bool multiple;

  final Client? value;
  final ValueChanged<Client?>? onChanged;

  final List<Client> values;
  final ValueChanged<List<Client>>? onValuesChanged;

  /// Tope de clientes en [ClientSearchField.multiple]; se muestra "n de max".
  final int? max;

  final String hintText;
  final bool dense;
  final bool enabled;

  /// El cliente viene dado (ej. desde su ficha): se muestra con un candado y
  /// el nombre lleva a la ficha; no se puede cambiar.
  final bool locked;
  final String? errorText;
  final ClientRowInfo? Function(Client client)? rowInfo;

  /// Alta desde "Crear cliente" con lo escrito. Devuelve el cliente creado para
  /// elegirlo, o null si la pantalla se encarga sola. Por defecto abre el alta
  /// de cliente.
  final Future<Client?> Function(String query)? onCreate;
  final bool showCreate;
  final bool autofocus;

  @override
  State<ClientSearchField> createState() => _ClientSearchFieldState();
}

class _ClientSearchFieldState extends State<ClientSearchField> {
  final _search = _ClientSearch();
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _portal = OverlayPortalController();
  final _link = LayerLink();
  final _fieldKey = GlobalKey();
  final _group = Object();
  int _active = 0;
  double _width = 0;

  bool get _mobile => ResponsiveBuilder.isMobile(context);

  Set<String> get _selectedIds => {
        for (final c in widget.values)
          if (c.clientId != null) c.clientId!,
      };

  bool get _full => widget.max != null && widget.values.length >= widget.max!;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onResults);
    _focus.addListener(_onFocus);
    _focus.onKeyEvent = _onKey;
    if (widget.autofocus) WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _search.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onResults() {
    if (!mounted) return;
    setState(() => _active = _firstEnabled(_search.visible));
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _search.loadRecents();
      _portal.show();
    } else {
      _portal.hide();
    }
    setState(() {});
  }

  int _firstEnabled(List<Client> list) {
    final i = list.indexWhere((c) => widget.rowInfo?.call(c)?.disabled != true);
    return i < 0 ? 0 : i;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final list = _search.visible;
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown when list.isNotEmpty:
        if (!_portal.isShowing) _portal.show();
        setState(() => _active = (_active + 1) % list.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp when list.isNotEmpty:
        setState(() => _active = (_active - 1 + list.length) % list.length);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter || LogicalKeyboardKey.numpadEnter when _portal.isShowing && _active < list.length:
        _pick(list[_active]);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape when _portal.isShowing:
        _portal.hide();
        setState(() {});
        return KeyEventResult.handled;
      case LogicalKeyboardKey.backspace when widget.multiple && _text.text.isEmpty && widget.values.isNotEmpty:
        _remove(widget.values.last);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _onQuery(String text) {
    _search.query = text;
    if (!_portal.isShowing) _portal.show();
    setState(() {});
  }

  void _clearQuery() {
    _text.clear();
    _search.query = '';
    setState(() {});
  }

  void _pick(Client client) {
    if (widget.rowInfo?.call(client)?.disabled == true) return;
    if (!widget.multiple) {
      _text.clear();
      _search.query = '';
      _focus.unfocus();
      widget.onChanged!(client);
      return;
    }
    // Varios: elegir no cierra la lista; limpia el texto para sumar otro.
    if (_selectedIds.contains(client.clientId)) {
      _remove(client);
    } else if (!_full) {
      widget.onValuesChanged!([...widget.values, client]);
    }
    _clearQuery();
    _focus.requestFocus();
  }

  void _remove(Client client) =>
      widget.onValuesChanged!(widget.values.where((c) => c.clientId != client.clientId).toList());

  /// Vuelve a buscar con el texto vacío (la X o un click en el elegido).
  void _change() {
    widget.onChanged!(null);
    _clearQuery();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_mobile) _focus.requestFocus();
    });
  }

  Future<void> _create(String query) async {
    _focus.unfocus();
    final client = await (widget.onCreate ?? (q) => _createClient(context, q))(query.trim());
    if (client == null || !mounted) return;
    _clearQuery();
    if (widget.multiple) {
      if (!_full) widget.onValuesChanged!([...widget.values, client]);
    } else {
      widget.onChanged!(client);
    }
  }

  Future<void> _openSheet() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => _ClientSearchSheet(
        search: _search,
        multiple: widget.multiple,
        initialValues: widget.values,
        max: widget.max,
        rowInfo: widget.rowInfo,
        showCreate: widget.showCreate,
        onPick: (client) => widget.multiple ? widget.onValuesChanged!([...widget.values, client]) : widget.onChanged!(client),
        onValuesChanged: widget.onValuesChanged,
        onCreate: _create,
      ),
    ));
    _search.query = '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasError = widget.errorText != null;
    final counter = widget.multiple && widget.max != null ? '${widget.values.length} de ${widget.max}' : null;

    Widget field;
    if (widget.locked && widget.value != null) {
      field = _LockedClient(client: widget.value!, dense: widget.dense);
    } else if (!widget.multiple && widget.value != null) {
      field = _PickedClient(client: widget.value!, dense: widget.dense, onChange: widget.enabled ? _change : null);
    } else {
      field = _searchBox(context);
    }

    final labelColor = !widget.enabled ? scheme.onSurface : (hasError ? scheme.error : scheme.onSurfaceVariant);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Row(children: [
            Expanded(child: Text(widget.label!, style: TextStyle(fontSize: 12, color: labelColor))),
            if (counter != null) Text(counter, style: TextStyle(fontSize: 12, color: labelColor)),
          ]),
          const SizedBox(height: 4),
        ],
        LayoutBuilder(builder: (context, constraints) {
          _width = constraints.maxWidth;
          return CompositedTransformTarget(key: _fieldKey, link: _link, child: field);
        }),
        if (hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 0, 0),
            child: Text(widget.errorText!, style: TextStyle(fontSize: 12, color: scheme.error)),
          ),
      ],
    );

    if (!widget.enabled) return Opacity(opacity: 0.38, child: IgnorePointer(child: content));

    return TapRegion(
      groupId: _group,
      onTapOutside: (_) => _focus.unfocus(),
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _dropdown,
        child: content,
      ),
    );
  }

  Widget _searchBox(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = _focus.hasFocus;
    final hasError = widget.errorText != null;
    final dense = widget.dense;
    final iconColor = !widget.enabled ? scheme.onSurface : (hasError ? scheme.error : (focused ? scheme.primary : scheme.onSurfaceVariant));
    final borderColor = !widget.enabled ? scheme.onSurface : (hasError ? scheme.error : (focused ? scheme.primary : scheme.outline));
    final borderWidth = focused ? 2.0 : 1.0;
    final hasQuery = _text.text.isNotEmpty;
    // El borde de 2 px no corre el contenido: se descuenta del padding.
    final inset = (dense ? 10.0 : 12.0) - (borderWidth - 1);

    final input = TextField(
      controller: _text,
      focusNode: _focus,
      groupId: _group,
      enabled: widget.enabled,
      readOnly: _mobile,
      onTap: _mobile ? _openSheet : null,
      onChanged: _onQuery,
      style: TextStyle(fontSize: 14, color: scheme.onSurface),
      cursorColor: scheme.primary,
      decoration: InputDecoration.collapsed(
        hintText: widget.multiple && widget.values.isEmpty ? 'Buscar por nombre, email o teléfono' : widget.hintText,
        hintStyle: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
      ),
    );

    final trailing = <Widget>[
      if (hasQuery) _IconButton(icon: Icons.close, tooltip: 'Borrar búsqueda', onTap: _clearQuery, size: dense ? 18 : 20),
      if (hasError && !hasQuery)
        Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.error, size: 20, color: scheme.error)),
    ];

    Widget body;
    if (widget.multiple && widget.values.isNotEmpty) {
      body = Padding(
        padding: EdgeInsets.fromLTRB(inset - 1, 7 - (borderWidth - 1), 6 - borderWidth, 7 - (borderWidth - 1)),
        child: Row(children: [
          Icon(Icons.group_add_outlined, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final c in widget.values) _ClientChip(client: c, onRemove: () => _remove(c)),
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 80, maxWidth: _width > 120 ? _width - 80 : 80),
                  child: IntrinsicWidth(child: input),
                ),
              ],
            ),
          ),
          ...trailing,
        ]),
      );
    } else {
      body = Padding(
        padding: EdgeInsets.only(left: inset, right: hasQuery ? 6 - borderWidth : inset),
        child: Row(children: [
          Icon(widget.multiple ? Icons.group_add_outlined : Icons.search, size: dense ? 18 : 20, color: iconColor),
          SizedBox(width: dense ? 8 : 10),
          Expanded(child: input),
          ...trailing,
        ]),
      );
    }

    return Container(
      constraints: BoxConstraints(minHeight: dense ? 40 : 48),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: body,
    );
  }

  Widget _dropdown(BuildContext context) {
    if (_mobile || (!widget.multiple && widget.value != null)) return const SizedBox.shrink();
    // Cerca del borde de abajo se abre hacia arriba; nunca queda cortada.
    final placement = DropdownPlacement.of(_fieldKey.currentContext, preferredHeight: _ClientDropdown.preferredHeight(widget.dense));
    return CompositedTransformFollower(
      link: _link,
      targetAnchor: placement.targetAnchor,
      followerAnchor: placement.followerAnchor,
      offset: placement.offset,
      showWhenUnlinked: false,
      child: Align(
        alignment: placement.alignment,
        child: TapRegion(
          groupId: _group,
          child: Container(
            width: _width,
            constraints: BoxConstraints(maxHeight: placement.maxHeight),
            child: _ClientDropdown(
              search: _search,
              active: _active,
              onHover: (i) => setState(() => _active = i),
              onPick: _pick,
              selectedIds: _selectedIds,
              multiple: widget.multiple,
              full: _full,
              rowInfo: widget.rowInfo,
              onCreate: widget.showCreate ? () => _create(_text.text) : null,
              dense: widget.dense,
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo para `FormBuilder` con el buscador de un cliente. El valor del campo
/// [name] es el [Client] elegido.
class ClientSearchFormField extends StatelessWidget {
  const ClientSearchFormField({
    super.key,
    required this.name,
    this.label = 'Cliente',
    this.initialValue,
    this.isRequired = false,
    this.requiredMessage = 'Elegí un cliente para seguir.',
    this.locked = false,
    this.onChanged,
    this.rowInfo,
    this.onCreate,
  });

  final String name;
  final String? label;
  final Client? initialValue;
  final bool isRequired;
  final String requiredMessage;
  final bool locked;
  final ValueChanged<Client?>? onChanged;
  final ClientRowInfo? Function(Client client)? rowInfo;
  final Future<Client?> Function(String query)? onCreate;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<Client?>(
      name: name,
      initialValue: initialValue,
      validator: (value) => isRequired && value == null ? requiredMessage : null,
      onChanged: onChanged,
      builder: (field) => ClientSearchField(
        label: label,
        value: field.value,
        locked: locked,
        errorText: field.errorText,
        rowInfo: rowInfo,
        onCreate: onCreate,
        onChanged: field.didChange,
      ),
    );
  }
}

/// Reparte lo escrito en el buscador para precargar un alta: "Agus" va al
/// nombre, "Juan Pérez" a nombre y apellido, un teléfono o un email a su campo.
({String name, String lastName, String phone, String email}) splitClientQuery(String query) {
  final text = query.trim();
  if (text.contains('@')) return (name: '', lastName: '', phone: '', email: text);
  if (text.isNotEmpty && RegExp(r'^[\d\s+()-]+$').hasMatch(text)) {
    return (name: '', lastName: '', phone: text.replaceAll(RegExp(r'\D'), ''), email: '');
  }
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  return (name: words.firstOrNull ?? '', lastName: words.skip(1).join(' '), phone: '', email: '');
}

/// Abre el alta de cliente con lo escrito y devuelve el cliente creado.
Future<Client?> _createClient(BuildContext context, String query) {
  final completer = Completer<Client?>();
  context
      .pushNamed(AppRoutes.NEW_CLIENT_ROUTE.name, extra: {
        'initialName': query,
        'onClientCreated': (Client client) {
          context.pop();
          if (!completer.isCompleted) completer.complete(client);
        },
      })
      .whenComplete(() {
        if (!completer.isCompleted) completer.complete(null);
      });
  return completer.future;
}

/// Búsqueda compartida por el desplegable y la pantalla del celular: recientes
/// sin texto; con texto, espera 300 ms después de la última tecla y mantiene
/// los resultados anteriores mientras llega la respuesta.
class _ClientSearch extends ChangeNotifier {
  static const _maxResults = 6;
  static const _maxRecents = 4;

  String _query = '';
  List<Client>? _recents;
  List<Client> _results = const [];
  bool loading = false;
  Timer? _debounce;
  int _request = 0;
  bool _disposed = false;

  String get query => _query.trim();
  List<Client> get visible => query.isEmpty ? (_recents ?? const []) : _results;
  bool get waitingRecents => query.isEmpty && _recents == null;

  set query(String value) {
    if (value == _query) return;
    _query = value;
    _debounce?.cancel();
    final q = query;
    if (q.isEmpty) {
      _request++;
      loading = false;
      _results = const [];
      _notify();
      return;
    }
    loading = true;
    _notify();
    _debounce = Timer(const Duration(milliseconds: 300), () => _fetch(q));
  }

  Future<void> loadRecents() async {
    if (_recents != null) return;
    final list = await _get('');
    _recents = list.take(_maxRecents).toList();
    _notify();
  }

  Future<void> _fetch(String q) async {
    final request = ++_request;
    final list = await _get(q);
    if (request != _request) return;
    _results = list.take(_maxResults).toList();
    loading = false;
    _notify();
  }

  Future<List<Client>> _get(String q) async {
    final result = await sl<AdminRepository>().getClients(q);
    return switch (result) {
      Right(:final value) => value.data.where((c) => c.clientId != null).toList(),
      _ => const <Client>[],
    };
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}

/// La lista pegada debajo del campo.
class _ClientDropdown extends StatelessWidget {
  const _ClientDropdown({
    required this.search,
    required this.active,
    required this.onHover,
    required this.onPick,
    required this.selectedIds,
    required this.multiple,
    required this.full,
    required this.rowInfo,
    required this.onCreate,
    required this.dense,
  });

  final _ClientSearch search;
  final int active;
  final ValueChanged<int> onHover;
  final ValueChanged<Client> onPick;
  final Set<String> selectedIds;
  final bool multiple;
  final bool full;
  final ClientRowInfo? Function(Client)? rowInfo;
  final VoidCallback? onCreate;
  final bool dense;

  static const _listHeight = 6 * 56.0;

  /// Alto con todo a la vista: progreso, encabezado, 6 filas, crear y atajos.
  static double preferredHeight(bool dense) => 2 + 31 + _listHeight + 49 + (dense ? 0 : 33) + 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: search,
      builder: (context, _) => Material(
        color: scheme.surfaceContainerHighest,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.45),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: scheme.outlineVariant)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: _ClientResults(
              search: search,
              active: active,
              onHover: onHover,
              onPick: onPick,
              selectedIds: selectedIds,
              multiple: multiple,
              full: full,
              rowInfo: rowInfo,
              maxHeight: _listHeight,
              ),
            ),
            if (onCreate != null) ...[
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              _CreateRow(query: search.query, onTap: onCreate!),
            ],
            if (!dense) ...[
              Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              const _Shortcuts(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Encabezado ("Recientes" / "Resultados · n"), filas, vacío y carga. Lo usan
/// el desplegable y la pantalla del celular.
class _ClientResults extends StatelessWidget {
  const _ClientResults({
    required this.search,
    required this.active,
    required this.onPick,
    required this.selectedIds,
    required this.multiple,
    required this.full,
    required this.rowInfo,
    this.onHover,
    this.maxHeight,
  });

  final _ClientSearch search;
  final int? active;
  final ValueChanged<int>? onHover;
  final ValueChanged<Client> onPick;
  final Set<String> selectedIds;
  final bool multiple;
  final bool full;
  final ClientRowInfo? Function(Client)? rowInfo;

  /// Con tope, la lista se achica a su contenido (desplegable); sin tope ocupa
  /// lo que tenga (celular).
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = search.query;
    final list = search.visible;
    final skeleton = (search.loading && list.isEmpty) || search.waitingRecents;
    final empty = query.isNotEmpty && !search.loading && list.isEmpty;
    final section = skeleton && query.isNotEmpty
        ? 'BUSCANDO…'
        : query.isEmpty
            ? 'RECIENTES'
            : 'RESULTADOS · ${list.length}';

    final rows = <Widget>[
      if (skeleton)
        for (var i = 0; i < 2; i++) _SkeletonRow(width: i == 0 ? 0.6 : 0.5)
      else
        for (final (i, c) in list.indexed)
          _ClientRow(
            client: c,
            query: query,
            active: i == active,
            onHover: onHover == null ? null : () => onHover!(i),
            onTap: () => onPick(c),
            multiple: multiple,
            selected: selectedIds.contains(c.clientId),
            info: rowInfo?.call(c),
            blocked: full && !selectedIds.contains(c.clientId),
          ),
    ];

    final scroll = ListView(padding: EdgeInsets.zero, shrinkWrap: maxHeight != null, children: rows);

    return Column(
      mainAxisSize: maxHeight != null ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 2, child: search.loading ? LinearProgressIndicator(minHeight: 2, color: scheme.primary, backgroundColor: scheme.primaryContainer) : null),
        if (!empty && !(query.isEmpty && !skeleton && list.isEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Text(section, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: scheme.onSurfaceVariant)),
          ),
        if (empty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
            child: Column(children: [
              Icon(Icons.person_search_outlined, size: 28, color: scheme.outline),
              const SizedBox(height: 6),
              Text('No hay clientes con “$query”', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: scheme.onSurface)),
              const SizedBox(height: 6),
              Text('Revisá cómo está escrito o crealo ahora.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ]),
          )
        else if (maxHeight != null)
          Flexible(child: ConstrainedBox(constraints: BoxConstraints(maxHeight: maxHeight!), child: scroll))
        else
          Expanded(child: scroll),
      ],
    );
  }
}

class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.client,
    required this.query,
    required this.active,
    required this.onTap,
    required this.multiple,
    required this.selected,
    required this.info,
    required this.blocked,
    this.onHover,
  });

  final Client client;
  final String query;
  final bool active;
  final VoidCallback? onHover;
  final VoidCallback onTap;
  final bool multiple;
  final bool selected;
  final ClientRowInfo? info;

  /// Ya se llegó al tope de [ClientSearchField.multiple].
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = _name(client);
    final disabled = info?.disabled == true || blocked;
    final tag = info ?? (multiple && selected ? const ClientRowInfo('Ya está') : null);
    final contact = _contact(client);

    final row = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: active ? scheme.onSurface.withValues(alpha: 0.10) : null,
      child: Row(children: [
        if (multiple) ...[
          _Check(checked: selected),
          const SizedBox(width: 12),
        ],
        ClientAvatar(name: name),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                _highlight(name, query, TextStyle(fontSize: 14, color: scheme.onSurface), TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (contact.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(contact, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ],
          ),
        ),
        if (tag != null) ...[
          const SizedBox(width: 12),
          _Tag(info: tag, outlined: !(multiple && selected && info == null)),
        ],
      ]),
    );

    return Semantics(
      selected: multiple ? selected : active,
      button: true,
      enabled: !disabled,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: InkWell(
          canRequestFocus: false,
          onTap: disabled ? null : onTap,
          onHover: (hovering) {
            if (hovering && !disabled) onHover?.call();
          },
          child: row,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.info, required this.outlined});

  final ClientRowInfo info;

  /// "Ya está" de un elegido va sin borde.
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = info.error ? scheme.error : scheme.onSurfaceVariant;
    final style = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color);
    if (!outlined || info.disabled) return Text(info.text, style: style);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: info.error ? scheme.errorContainer : scheme.outlineVariant),
      ),
      child: Text(info.text, style: style),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: checked ? scheme.primary : null,
        borderRadius: BorderRadius.circular(2),
        border: checked ? null : Border.all(color: scheme.outline, width: 2),
      ),
      child: checked ? Icon(Icons.check, size: 16, color: scheme.onPrimary) : null,
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(widthFactor: width, child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 6),
                FractionallySizedBox(widthFactor: width * 0.66, child: Container(height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _CreateRow extends StatelessWidget {
  const _CreateRow({required this.query, required this.onTap});

  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      canRequestFocus: false,
      onTap: onTap,
      hoverColor: scheme.primary.withValues(alpha: 0.08),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(children: [
          Icon(Icons.person_add_alt, size: 20, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              query.isEmpty ? 'Crear cliente nuevo' : 'Crear cliente “$query”',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.primary),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(fontSize: 11, color: scheme.onSurfaceVariant);
    Widget key(String k) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(4)),
          child: Text(k, style: style.copyWith(fontWeight: FontWeight.w500)),
        );
    Widget hint(List<String> keys, String label) => Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: [...keys.map(key), Text(label, style: style)]);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Wrap(spacing: 14, runSpacing: 4, children: [
        hint(['↑', '↓'], 'moverse'),
        hint(['Enter'], 'elegir'),
        hint(['Esc'], 'cerrar'),
      ]),
    );
  }
}

/// El cliente elegido en el lugar del campo: mismo alto y borde.
class _PickedClient extends StatelessWidget {
  const _PickedClient({required this.client, required this.dense, required this.onChange});

  final Client client;
  final bool dense;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final contact = _contact(client);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: scheme.outline)),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onChange,
        child: SizedBox(
          height: dense ? 40 : 48,
          child: Padding(
            padding: EdgeInsets.only(left: dense ? 8 : 10, right: 6),
            child: Row(children: [
              ClientAvatar(name: _name(client), size: dense ? 24 : 28),
              SizedBox(width: dense ? 8 : 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: _name(client), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface)),
                    if (contact.isNotEmpty && !dense) TextSpan(text: '   $contact', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onChange != null) _IconButton(icon: Icons.close, tooltip: 'Quitar cliente', onTap: onChange!, size: dense ? 18 : 20),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Cliente que no se puede cambiar (viene de su ficha): el nombre lleva a la
/// ficha y un candado a la derecha.
class _LockedClient extends StatelessWidget {
  const _LockedClient({required this.client, required this.dense});

  final Client client;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: dense ? 40 : 48,
      padding: const EdgeInsets.only(left: 10, right: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: scheme.outlineVariant)),
      child: Row(children: [
        ClientAvatar(name: _name(client), size: dense ? 24 : 28),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: ClientLink(
              clientId: int.tryParse(client.clientId ?? ''),
              name: _name(client),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: scheme.onSurface),
            ),
          ),
        ),
        Icon(Icons.lock_outline, size: 18, color: scheme.outline),
      ]),
    );
  }
}

class _ClientChip extends StatelessWidget {
  const _ClientChip({required this.client, required this.onRemove});

  final Client client;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: scheme.outline)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        ClientAvatar(name: _name(client), size: 22),
        const SizedBox(width: 6),
        Text(_name(client), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 2),
        Tooltip(
          message: 'Sacar a ${_name(client)}',
          child: InkResponse(
            canRequestFocus: false,
            radius: 12,
            onTap: onRemove,
            child: Padding(padding: const EdgeInsets.all(2), child: Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant)),
          ),
        ),
      ]),
    );
  }
}

/// Avatar con las iniciales del cliente (primaryContainer).
class ClientAvatar extends StatelessWidget {
  const ClientAvatar({super.key, required this.name, this.size = 32});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
      child: Text(
        _initials(name),
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w500, color: scheme.onPrimaryContainer, height: 1),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.tooltip, required this.onTap, this.size = 20});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        iconSize: size,
        focusNode: FocusNode(skipTraversal: true, canRequestFocus: false),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: onTap,
        icon: Icon(icon),
      ),
    );
  }
}

/// En el celular la búsqueda ocupa la pantalla: tocar el campo la abre y
/// elegir la cierra. Con varios, se puede marcar y desmarcar hasta volver.
class _ClientSearchSheet extends StatefulWidget {
  const _ClientSearchSheet({
    required this.search,
    required this.multiple,
    required this.initialValues,
    required this.max,
    required this.rowInfo,
    required this.showCreate,
    required this.onPick,
    required this.onValuesChanged,
    required this.onCreate,
  });

  final _ClientSearch search;
  final bool multiple;
  final List<Client> initialValues;
  final int? max;
  final ClientRowInfo? Function(Client)? rowInfo;
  final bool showCreate;
  final ValueChanged<Client> onPick;
  final ValueChanged<List<Client>>? onValuesChanged;
  final Future<void> Function(String query) onCreate;

  @override
  State<_ClientSearchSheet> createState() => _ClientSearchSheetState();
}

class _ClientSearchSheetState extends State<_ClientSearchSheet> {
  final _text = TextEditingController();
  late List<Client> _values = [...widget.initialValues];

  Set<String> get _ids => {
        for (final c in _values)
          if (c.clientId != null) c.clientId!,
      };

  @override
  void initState() {
    super.initState();
    widget.search.query = '';
    widget.search.loadRecents();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _pick(Client client) {
    if (widget.rowInfo?.call(client)?.disabled == true) return;
    if (!widget.multiple) {
      widget.onPick(client);
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      if (_ids.contains(client.clientId)) {
        _values = _values.where((c) => c.clientId != client.clientId).toList();
      } else if (widget.max == null || _values.length < widget.max!) {
        _values = [..._values, client];
      }
    });
    widget.onValuesChanged!(_values);
    _text.clear();
    widget.search.query = '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 56,
            child: Row(children: [
              IconButton(tooltip: 'Volver', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  onChanged: (v) => setState(() => widget.search.query = v),
                  style: TextStyle(fontSize: 16, color: scheme.onSurface),
                  cursorColor: scheme.primary,
                  decoration: InputDecoration.collapsed(
                    hintText: 'Buscar por nombre, email o teléfono',
                    hintStyle: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              if (_text.text.isNotEmpty)
                IconButton(
                  tooltip: 'Borrar búsqueda',
                  onPressed: () => setState(() {
                    _text.clear();
                    widget.search.query = '';
                  }),
                  icon: const Icon(Icons.close),
                ),
            ]),
          ),
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.search,
              builder: (context, _) => _ClientResults(
                search: widget.search,
                active: null,
                onPick: _pick,
                selectedIds: _ids,
                multiple: widget.multiple,
                full: widget.max != null && _values.length >= widget.max!,
                rowInfo: widget.rowInfo,
              ),
            ),
          ),
          if (widget.showCreate) ...[
            Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
            _CreateRow(
              query: _text.text.trim(),
              onTap: () {
                final query = _text.text;
                Navigator.of(context).pop();
                widget.onCreate(query);
              },
            ),
          ],
        ]),
      ),
    );
  }
}

String _name(Client client) {
  final name = client.person?.fullName.trim() ?? '';
  return name.isEmpty ? 'Sin nombre' : name;
}

String _contact(Client client) {
  final person = client.person;
  if (person == null) return '';
  return [if (person.hasEmail()) person.email!, if (person.hasPhone()) person.phone!].join(' · ');
}

String _initials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  final first = words.first.characters.first;
  final last = words.length > 1 ? words.last.characters.first : '';
  return (first + last).toUpperCase();
}

/// Sin tildes ni mayúsculas, letra por letra (mismo largo que el original, así
/// los índices de la coincidencia sirven para el nombre real).
String _fold(String s) {
  const from = 'áàäâãéèëêíìïîóòöôõúùüûñçÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑÇ';
  const to = 'aaaaaeeeeiiiiooooouuuuncaaaaaeeeeiiiiooooouuuunc';
  final buffer = StringBuffer();
  for (final unit in s.split('')) {
    final i = from.indexOf(unit);
    buffer.write(i >= 0 ? to[i] : unit.toLowerCase());
  }
  return buffer.toString();
}

/// El nombre con la parte que coincide con lo escrito en `primary`.
TextSpan _highlight(String name, String query, TextStyle base, TextStyle hit) {
  final q = _fold(query.trim());
  final i = q.isEmpty ? -1 : _fold(name).indexOf(q);
  if (i < 0) return TextSpan(text: name, style: base);
  return TextSpan(style: base, children: [
    TextSpan(text: name.substring(0, i)),
    TextSpan(text: name.substring(i, i + q.length), style: hit),
    TextSpan(text: name.substring(i + q.length)),
  ]);
}
