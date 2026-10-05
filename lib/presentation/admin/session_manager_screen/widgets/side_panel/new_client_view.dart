import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/entities/client.dart';
import '../../../../../domain/entities/person.dart';
import '../../../../../domain/entities/session.dart';
import '../../bloc/session_manager_bloc.dart';
import '../../bloc/session_manager_event.dart';
import 'panel_common.dart';

/// "Nuevo cliente": alta mínima (nombre, apellido, teléfono, email) y
/// reserva del turno en un paso. El backend crea el cliente al reservar con
/// un cliente sin id.
class NewClientView extends StatefulWidget {
  const NewClientView({super.key, required this.session, required this.subtitle, required this.onBack});

  final Session session;
  final String subtitle;
  final VoidCallback onBack;

  @override
  State<NewClientView> createState() => _NewClientViewState();
}

class _NewClientViewState extends State<NewClientView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _lastName, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _ready => _name.text.trim().isNotEmpty && _lastName.text.trim().isNotEmpty;

  void _create() {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final email = _email.text.trim();
    final phone = _phone.text.trim();
    context.read<SessionManagerBloc>().add(
          ReserveEvent(
            widget.session,
            Client(
              person: Person(
                name: _name.text.trim(),
                lastName: _lastName.text.trim(),
                email: email.isEmpty ? null : email,
                phone: phone.isEmpty ? null : phone,
              ),
            ),
          ),
        );
    // Al reservarse el turno el panel vuelve solo al detalle; si falla, se
    // vuelve a habilitar el botón.
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _saving = false);
    });
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    String? Function(String?)? validator,
    bool autofocus = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboard,
          validator: validator,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 14, color: scheme.onSurface),
          decoration: panelInputDecoration(context, hintText: hint),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String? required(String? v) => (v ?? '').trim().isEmpty ? 'Obligatorio' : null;

    return Form(
      key: _form,
      child: PanelFrame(
        footer: Row(
          children: [
            PanelTextButton(label: 'Cancelar', onPressed: widget.onBack),
            const Spacer(),
            PanelFilledButton(
              label: 'Crear y reservar',
              icon: Icons.check,
              loading: _saving,
              onPressed: _ready ? _create : null,
            ),
          ],
        ),
        children: [
          PanelSubHeader(
            title: 'Nuevo cliente',
            subtitle: widget.subtitle,
            onBack: widget.onBack,
            backTooltip: 'Volver a elegir cliente',
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _field('Nombre *', _name, hint: 'Nombre', validator: required, autofocus: true)),
              const SizedBox(width: 12),
              Expanded(child: _field('Apellido *', _lastName, hint: 'Apellido', validator: required)),
            ],
          ),
          _field('Teléfono', _phone, hint: '2284 00-0000', keyboard: TextInputType.phone),
          _field(
            'Email',
            _email,
            hint: 'nombre@mail.com',
            keyboard: TextInputType.emailAddress,
            validator: (v) {
              final text = (v ?? '').trim();
              if (text.isEmpty) return null;
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text) ? null : 'Email inválido';
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Icon(Icons.info_outline, size: 18, color: scheme.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Con teléfono o email el cliente puede recibir recordatorios del turno. '
                    'El resto de su ficha se completa después desde Clientes.',
                    style: TextStyle(fontSize: 12, height: 16 / 12, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
