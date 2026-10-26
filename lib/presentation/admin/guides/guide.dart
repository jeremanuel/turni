import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/router/app_router.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/onboarding/onboarding_tour.dart';
import '../../../core/presentation/components/onboarding/tour_anchor.dart';
import '../../../core/utils/admin_vocabulary.dart';
import '../../../core/utils/permissions.dart';
import '../../../domain/entities/partition_vocabulary.dart';
import '../../core/cubit/auth/auth_cubit.dart';

/// Una guía del centro de ayuda: un recorrido ([OnboardingTour]) con título
/// y descripción para buscarla, y la pantalla donde arranca.
///
/// Los pasos resaltan [TourAnchor]s por nombre, así que una guía puede
/// recorrer varias pantallas: un paso abre la siguiente con
/// [TourAnchors.activate] en su `before` (ej. "abrir el primer cliente").
class Guide {
  const Guide({
    required this.id,
    required this.section,
    required this.title,
    required this.description,
    required this.icon,
    required this.steps,
    this.keywords = const [],
    this.permissions = const [],
    this.isAvailable,
    this.route,
    this.stayOn,
  });

  /// Identifica la guía (y si el admin ya la vio).
  final String id;

  /// Grupo del centro de ayuda ("Turnos", "Clientes"...).
  final String section;

  final String title;

  /// Una o dos líneas: qué vas a aprender.
  final String description;

  final IconData icon;

  /// Otras palabras con las que se puede buscar.
  final List<String> keywords;

  /// Alcanza con uno; vacío = cualquier admin.
  final List<String> permissions;

  /// Condición extra para mostrarla (ej. el club tiene gimnasio).
  final bool Function()? isAvailable;

  /// Ruta donde arranca. null = donde esté el admin.
  final String? route;

  /// Si ya está en una ruta que matchea, no navega a [route] (ej. la guía
  /// de la ficha arranca en la ficha que esté abierta).
  final RegExp? stayOn;

  /// Los pasos, con el vocabulario de los servicios del club ("cancha",
  /// "sala"...): ningún texto dice "cancha" fijo.
  final List<OnboardingStep> Function(PartitionVocabulary vocabulary) steps;

  bool get isVisible => (permissions.isEmpty || Permissions.canAny(permissions)) && (isAvailable?.call() ?? true);

  String get _seenId => 'guide:$id:${sl<AuthCubit>().state.userCredential?.userId ?? ''}';

  Future<bool> hasSeen() => OnboardingTour.hasSeen(_seenId);

  /// Busca en el título, la descripción, la sección y las palabras clave,
  /// sin importar tildes ni mayúsculas. Todas las palabras tienen que estar.
  bool matches(String query) {
    final words = normalizeForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return true;
    final haystack = normalizeForSearch([title, description, section, ...keywords].join(' '));
    return words.every(haystack.contains);
  }

  /// Va a la pantalla de la guía y la recorre.
  Future<OnboardingResult> run() async {
    final router = sl<GoRouter>();
    final route = this.route;
    if (route != null) {
      // La de arriba de todo: `currentConfiguration.uri` no cuenta lo que
      // se abrió con `push` (ej. el detalle de un torneo).
      final current = router.state.uri.toString();
      final stay = stayOn?.hasMatch(Uri.parse(current).path) ?? false;
      if (!stay && current != route) router.go(route);
    }
    // Que la navegación llegue a armar la pantalla nueva.
    await WidgetsBinding.instance.endOfFrame;
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return OnboardingResult.none;
    return OnboardingTour.show(context, id: _seenId, steps: steps(adminVocabulary()));
  }
}

/// Minúsculas y sin tildes, para buscar "configuracion" y encontrar
/// "Configuración".
String normalizeForSearch(String text) {
  const from = 'áéíóúüñ';
  const to = 'aeiouun';
  final lower = text.toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    final i = from.indexOf(char);
    buffer.write(i < 0 ? char : to[i]);
  }
  return buffer.toString();
}

/// `before` de un paso: activa el anchor [id] (abrir esa tab, ese turno...).
Future<void> Function() activate(String id) => () async {
      await TourAnchors.activate(id);
    };

/// `before` de un paso: si [anchor] no está a la vista, activa [via] (la
/// tab o la sección que lo muestra). En el celular la sección ya puede
/// estar abierta, tapando la lista desde la que se abre.
Future<void> Function() reveal(String anchor, {required String via}) => () async {
      await WidgetsBinding.instance.endOfFrame;
      if (!TourAnchors.isMounted(anchor)) await TourAnchors.activate(via);
    };

/// `before` de un paso: va a [location] si no está ahí.
Future<void> Function() goTo(String location) => () async {
      final router = sl<GoRouter>();
      if (router.state.uri.toString() != location) router.go(location);
      await WidgetsBinding.instance.endOfFrame;
    };
