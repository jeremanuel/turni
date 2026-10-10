import 'package:flutter/material.dart';

import '../../core/config/service_locator.dart';
import '../core/cubit/auth/auth_cubit.dart';
import 'widgets/auth_card_scaffold.dart';

/// Usuario logueado sin acceso al panel: no es admin de ningún club, o un
/// admin del club lo deshabilitó.
class NoAccessPage extends StatelessWidget {
  const NoAccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = sl<AuthCubit>();
    final textTheme = Theme.of(context).textTheme;
    final email = authCubit.state.userCredential?.person.email;
    final disabled = authCubit.isDisabledAdmin();

    return AuthCardScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(disabled ? Icons.block : Icons.lock_outline, size: 36, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            disabled ? 'Tu usuario está deshabilitado' : 'Esta cuenta no administra ningún club',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            disabled
                ? 'Un administrador de tu club deshabilitó tu acceso al panel. Si es un error, pedile que te vuelva a habilitar.'
                : 'Para entrar al panel necesitás que un administrador de tu club te invite. Abrí el link que te pasaron con esta cuenta de Google.',
            style: textTheme.bodyMedium,
          ),
          if (email != null) ...[
            const SizedBox(height: 16),
            Text('Entraste como $email', style: textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: authCubit.signOutGoogle,
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}
