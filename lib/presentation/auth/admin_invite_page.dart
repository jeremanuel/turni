import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/router/app_routes.dart';
import '../../core/config/service_locator.dart';
import '../../core/utils/domain_error.dart';
import '../../core/utils/either.dart';
import '../../domain/entities/admin_roles.dart';
import '../../domain/repositories/admin_access_repository.dart';
import '../admin/states/global_data/global_data_cubit.dart';
import '../core/cubit/auth/auth_cubit.dart';
import 'widgets/auth_card_scaffold.dart';

/// Link de invitación de admin (`/invite/:token`). Quien lo abre ya entró con
/// Google (el router lo manda al login y lo trae de vuelta); al aceptar, esa
/// cuenta queda como admin del club con el rol que eligió quien invitó.
class AdminInvitePage extends StatefulWidget {
  const AdminInvitePage({super.key, required this.token});

  final String token;

  @override
  State<AdminInvitePage> createState() => _AdminInvitePageState();
}

class _AdminInvitePageState extends State<AdminInvitePage> {
  final _repository = sl<AdminAccessRepository>();
  final _authCubit = sl<AuthCubit>();

  AdminInvitationPreview? _invitation;
  String? _error;
  String? _errorCode;
  bool _loading = true;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _route => '/invite/${widget.token}';

  static String? _codeOf(DomainError failure) {
    final details = failure.details;
    return details is Map ? details['code'] as String? : null;
  }

  Future<void> _load() async {
    final result = await _repository.getInvitation(widget.token);
    if (!mounted) return;
    result.when(
      left: (failure) => setState(() {
        _loading = false;
        _error = failure.message;
        _errorCode = _codeOf(failure);
      }),
      right: (invitation) => setState(() {
        _loading = false;
        _invitation = invitation;
      }),
    );
  }

  Future<void> _accept() async {
    setState(() {
      _accepting = true;
      _error = null;
      _errorCode = null;
    });

    final result = await _repository.acceptInvitation(widget.token);
    if (!mounted) return;

    await result.when(
      left: (failure) async => setState(() {
        _accepting = false;
        _error = failure.message;
        _errorCode = _codeOf(failure);
      }),
      right: (_) async {
        // Ahora es admin: se recarga el usuario (rol y permisos) y los datos
        // del club que se pidieron cuando todavía no lo era. El link ya no
        // tiene que volver a abrirse después de un login.
        _authCubit.initialRoute = null;
        await _authCubit.refreshUser();
        final globalData = sl<GlobalDataCubit>();
        globalData.loadLabels();
        globalData.loadProducts();
        if (mounted) context.go(AppRoutes.DASHBOARD_ROUTE.path);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthCardScaffold(child: _loading ? _buildLoading() : _buildContent(context));
  }

  Widget _buildLoading() {
    return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
  }

  Widget _buildContent(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final invitation = _invitation;
    final email = _authCubit.state.userCredential?.person.email;
    final alreadyAdmin = _authCubit.isAdmin();

    final children = <Widget>[];

    if (invitation == null) {
      children.addAll([
        Text('No pudimos abrir la invitación', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(_error ?? 'Revisá el link o pedile al club uno nuevo.', style: textTheme.bodyMedium),
      ]);
    } else if (invitation.status != AdminInvitationStatus.pending) {
      children.addAll([
        Text(_statusTitle(invitation.status), style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Pedile a quien te invitó que genere un link nuevo.', style: textTheme.bodyMedium),
      ]);
    } else {
      children.addAll([
        Text(
          'Te invitaron a administrar ${invitation.clubName ?? 'un club'} en Turni',
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _InfoRow(label: 'Nombre', value: [invitation.name, invitation.lastName].where((p) => p.isNotEmpty).join(' ')),
        _InfoRow(label: 'Rol', value: invitation.roleName),
        _InfoRow(label: 'Vence', value: DateFormat('dd/MM/yyyy HH:mm').format(invitation.expiresAt.toLocal())),
        const SizedBox(height: 16),
        if (email != null)
          Text(
            'Vas a quedar como administrador con la cuenta $email.',
            style: textTheme.bodyMedium,
          ),
        if (alreadyAdmin) ...[
          const SizedBox(height: 12),
          Text(
            'Esta cuenta ya es administradora en Turni. Para aceptar, entrá con otra cuenta de Google.',
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ]);
    }

    if (_error != null && invitation != null) {
      children.addAll([
        const SizedBox(height: 12),
        Text(_error!, style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
      ]);
    }

    final canAccept = invitation?.status == AdminInvitationStatus.pending && !alreadyAdmin;
    // Sin login verificado o con una cuenta que ya es admin, la salida es
    // volver a entrar (con la misma u otra cuenta) y volver a este link.
    final needsSignIn = _errorCode == 'UNVERIFIED_LOGIN';

    children.addAll([
      const SizedBox(height: 24),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 8,
        children: [
          TextButton(
            onPressed: () => _authCubit.signOutAndReturnTo(_route),
            child: Text(needsSignIn ? 'Volver a iniciar sesión' : 'Usar otra cuenta'),
          ),
          if (canAccept && !needsSignIn)
            FilledButton(
              onPressed: _accepting ? null : _accept,
              child: _accepting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Aceptar invitación'),
            ),
          if (alreadyAdmin)
            FilledButton(
              onPressed: () => context.go(AppRoutes.DASHBOARD_ROUTE.path),
              child: const Text('Ir al panel'),
            ),
        ],
      ),
    ]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _statusTitle(AdminInvitationStatus status) {
    switch (status) {
      case AdminInvitationStatus.accepted:
        return 'Esta invitación ya fue usada';
      case AdminInvitationStatus.expired:
        return 'Esta invitación venció';
      case AdminInvitationStatus.revoked:
        return 'Esta invitación fue anulada';
      case AdminInvitationStatus.pending:
        return '';
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 72, child: Text(label, style: textTheme.bodySmall)),
          Expanded(child: Text(value, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
