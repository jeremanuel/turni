import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import '../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';

/// Login de prueba, solo en builds de debug: entra con un email cualquiera
/// sin pasar por Google (el login de Google no funciona en local). Hace el
/// mismo signup que Google con un id_token falso; el backend lo acepta solo
/// con `GOOGLE_ID_TOKEN_SKIP_VERIFY=true` y fuera de producción, y lo da por
/// verificado, así que sirve para probar el link de invitación de admin.
class DevLoginButton extends StatelessWidget {
  const DevLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return TextButton.icon(
      onPressed: () => showDialog<void>(context: context, builder: (_) => const _DevLoginDialog()),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      icon: const Icon(Icons.bug_report_outlined),
      label: const Text('Entrar sin Google (solo dev)'),
    );
  }
}

class _DevLoginDialog extends StatefulWidget {
  const _DevLoginDialog();

  @override
  State<_DevLoginDialog> createState() => _DevLoginDialogState();
}

class _DevLoginDialogState extends State<_DevLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim();
    Navigator.of(context).pop();

    // Mismo email => mismo usuario: el signup busca por email.
    sl<AuthCubit>().googleCallback(
      GoogleSignInUserData(id: 'dev-$email', email: email, displayName: name.isEmpty ? null : name),
      idToken: 'dev-login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Entrar sin Google'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Solo para desarrollo. Un email nuevo crea un usuario nuevo; uno que ya existe entra con ese usuario.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (value) => (value ?? '').contains('@') ? null : 'Ingresá un email',
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre y apellido (opcional)', border: OutlineInputBorder()),
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(onPressed: _submit, child: const Text('Entrar')),
      ],
    );
  }
}
