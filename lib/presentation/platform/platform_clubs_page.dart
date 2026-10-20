import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/router/app_routes.dart';
import '../../core/config/service_locator.dart';
import '../../core/utils/either.dart';
import '../../domain/repositories/platform_repository.dart';
import '../auth/widgets/auth_card_scaffold.dart';
import '../core/cubit/auth/auth_cubit.dart';

/// Alta de un club con su dueño (`/platform/clubs`). Solo la ven los
/// operadores de Turni. El dueño queda vinculado la primera vez que entra al
/// panel con la cuenta de Google de ese email: no hay link ni código.
class PlatformClubsPage extends StatefulWidget {
  const PlatformClubsPage({super.key});

  @override
  State<PlatformClubsPage> createState() => _PlatformClubsPageState();
}

class _PlatformClubsPageState extends State<PlatformClubsPage> {
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _formKey = GlobalKey<FormState>();
  final _clubName = TextEditingController();
  final _name = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();

  bool _saving = false;
  String? _error;
  ({String clubName, CreatedClub club})? _created;

  @override
  void dispose() {
    _clubName.dispose();
    _name.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty ? 'Obligatorio' : null;

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Obligatorio';
    return _emailPattern.hasMatch(email) ? null : 'Email no válido';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final clubName = _clubName.text.trim();
    final result = await sl<PlatformRepository>().createClub(
      clubName: clubName,
      name: _name.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted) return;

    result.when(
      left: (failure) => setState(() {
        _saving = false;
        _error = failure.message;
      }),
      right: (club) => setState(() {
        _saving = false;
        _created = (clubName: clubName, club: club);
      }),
    );
  }

  void _reset() {
    for (final controller in [_clubName, _name, _lastName, _email]) {
      controller.clear();
    }
    setState(() => _created = null);
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return AuthCardScaffold(child: created == null ? _buildForm(context) : _buildCreated(context, created));
  }

  Widget _buildForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alta de establecimiento', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'El dueño entra al panel con la cuenta de Google de este email y queda como Super administrador.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _clubName,
            decoration: const InputDecoration(labelText: 'Nombre del establecimiento'),
            maxLength: 120,
            textInputAction: TextInputAction.next,
            validator: _required,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Nombre del dueño'),
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                  validator: _required,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Apellido (opcional)'),
                  maxLength: 60,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'Email de Google del dueño'),
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            validator: _validateEmail,
            onFieldSubmitted: (_) => _saving ? null : _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _LeaveButton(),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Dar de alta'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreated(BuildContext context, ({String clubName, CreatedClub club}) created) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, size: 36, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('${created.clubName} quedó dado de alta', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Avisale al dueño que entre al panel con la cuenta de Google ${created.club.email}. '
          'Va a arrancar en Configuración para cargar los datos del establecimiento.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              _LeaveButton(),
              FilledButton(onPressed: _reset, child: const Text('Dar de alta otro')),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un operador que además es admin de un club vuelve al panel; uno sin club
/// no tiene otra pantalla, así que solo puede cerrar sesión.
class _LeaveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authCubit = sl<AuthCubit>();
    final hasPanel = authCubit.isAdmin() && !authCubit.isDisabledAdmin();
    return hasPanel
        ? TextButton(onPressed: () => context.go(AppRoutes.DASHBOARD_ROUTE.path), child: const Text('Volver al panel'))
        : TextButton(onPressed: authCubit.signOutGoogle, child: const Text('Cerrar sesión'));
  }
}
