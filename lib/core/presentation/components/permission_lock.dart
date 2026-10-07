import 'package:flutter/material.dart';

import '../../utils/permissions.dart';

/// Muestra [child] solo si el rol tiene alguno de [permissions]. Si no lo
/// tiene, lo oculta ([hide]) o lo deja a la vista pero sin poder usarlo
/// (atenuado y sin foco). El backend igual rechaza la acción con 403: esto es
/// para no ofrecer lo que no se puede hacer.
///
/// No envolver un widget que scrollea: [IgnorePointer] también bloquea el
/// scroll de lo que tiene adentro (el scroll de la pantalla, por fuera, sigue
/// funcionando).
class PermissionLock extends StatelessWidget {
  const PermissionLock({
    super.key,
    required this.permissions,
    required this.child,
    this.hide = false,
  });

  final List<String> permissions;
  final Widget child;
  final bool hide;

  @override
  Widget build(BuildContext context) {
    if (Permissions.canAny(permissions)) return child;
    if (hide) return const SizedBox.shrink();

    return ExcludeFocus(
      child: IgnorePointer(
        child: Opacity(opacity: 0.55, child: child),
      ),
    );
  }
}

/// Aviso al tope de una sección que el rol puede ver pero no editar.
class ReadOnlyNotice extends StatelessWidget {
  const ReadOnlyNotice({super.key, required this.permissions});

  final List<String> permissions;

  @override
  Widget build(BuildContext context) {
    if (Permissions.canAny(permissions)) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Solo lectura: tu rol puede ver esta sección pero no editarla.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
