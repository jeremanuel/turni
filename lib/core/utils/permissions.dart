// ignore_for_file: constant_identifier_names

import '../config/service_locator.dart';
import '../../presentation/core/cubit/auth/auth_cubit.dart';

/// Códigos de acción del admin. Son los mismos que el catálogo del backend
/// (`turni_mono_be/src/domain/entities/permissions/PermissionCatalog.ts`),
/// que es la fuente de verdad: la app solo oculta o bloquea lo que el backend
/// igual rechazaría con 403.
class Permissions {
  static const AGENDA_VER = 'agenda.ver';
  static const AGENDA_CREAR = 'agenda.crear';
  static const AGENDA_EDITAR = 'agenda.editar';
  static const AGENDA_ELIMINAR = 'agenda.eliminar';
  static const AGENDA_RESERVAR = 'agenda.reservar';
  static const AGENDA_SOLICITUDES = 'agenda.solicitudes';
  static const AGENDA_COBRAR = 'agenda.cobrar';
  static const AGENDA_GESTION_MASIVA = 'agenda.gestion_masiva';

  static const CLIENTES_VER = 'clientes.ver';
  static const CLIENTES_EDITAR = 'clientes.editar';
  static const CLIENTES_ABONOS = 'clientes.abonos';

  static const PAGOS_VER = 'pagos.ver';
  static const PAGOS_REGISTRAR = 'pagos.registrar';

  static const CONFIGURACION_VER = 'configuracion.ver';
  static const CONFIGURACION_CLUB = 'configuracion.club';
  static const CONFIGURACION_CANCHAS = 'configuracion.canchas';
  static const CONFIGURACION_TARIFAS = 'configuracion.tarifas';
  static const CONFIGURACION_PRODUCTOS = 'configuracion.productos';
  static const CONFIGURACION_SOLICITUDES = 'configuracion.solicitudes';
  static const CONFIGURACION_COBROS_ONLINE = 'configuracion.cobros_online';

  static const MAPA_VER = 'mapa.ver';
  static const MAPA_EDITAR = 'mapa.editar';

  static const ROLES_VER = 'roles.ver';
  static const ROLES_EDITAR = 'roles.editar';

  static const ADMINISTRADORES_VER = 'administradores.ver';
  static const ADMINISTRADORES_INVITAR = 'administradores.invitar';
  static const ADMINISTRADORES_EDITAR = 'administradores.editar';

  /// true si el admin logueado tiene el permiso.
  static bool can(String permission) => sl<AuthCubit>().can(permission);

  /// true si tiene al menos uno.
  static bool canAny(Iterable<String> permissions) => sl<AuthCubit>().canAny(permissions);
}
