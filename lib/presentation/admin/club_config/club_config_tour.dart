import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/onboarding/onboarding_tour.dart';
import '../../../domain/entities/club_info.dart';
import '../../core/cubit/auth/auth_cubit.dart';

/// Widgets de Configuración que resalta el recorrido ([OnboardingTour]).
class ClubConfigTourKeys {
  final name = GlobalKey(debugLabel: 'tour.name');
  final address = GlobalKey(debugLabel: 'tour.address');
  final map = GlobalKey(debugLabel: 'tour.map');
  final save = GlobalKey(debugLabel: 'tour.save');
  final partitionsTab = GlobalKey(debugLabel: 'tour.partitionsTab');
  final tariffsTab = GlobalKey(debugLabel: 'tour.tariffsTab');
  final paymentsTab = GlobalKey(debugLabel: 'tour.paymentsTab');
}

/// Recorrido de Configuración para el dueño de un club recién dado de alta.
class ClubConfigTour {
  ClubConfigTour._();

  static String get _id => 'club_config:${sl<AuthCubit>().state.userCredential?.userId ?? ''}';

  /// Club sin dirección o sin ubicación: recién dado de alta.
  static bool isIncomplete(ClubInfo info) =>
      (info.address ?? '').trim().isEmpty || info.lat == null || info.lng == null;

  static List<OnboardingStep> steps(ClubConfigTourKeys keys, {required Future<void> Function() showInfoTab}) => [
        OnboardingStep(
          target: keys.name,
          before: showInfoTab,
          title: 'Te damos la bienvenida a Turni',
          body: 'Empecemos por los datos de tu establecimiento. Este nombre es el que ven tus clientes al buscarte.',
        ),
        OnboardingStep(
          target: keys.address,
          title: 'Dirección',
          body: 'Escribila y tocá la lupa: te la ubicamos en el mapa.',
        ),
        OnboardingStep(
          target: keys.map,
          title: 'Ubicación en el mapa',
          body: 'Tocá el mapa justo donde está el establecimiento y después "Confirmar ubicación". '
              'Con esto te encuentran los clientes que buscan cerca.',
        ),
        OnboardingStep(
          target: keys.save,
          title: 'Guardá los cambios',
          body: 'Nada se guarda hasta que tocás "Guardar cambios".',
        ),
        OnboardingStep(
          target: keys.partitionsTab,
          title: 'Servicios y espacios',
          body: 'Después cargá lo que ofrecés (ej. pádel, una sala, un profesional) y sus espacios. '
              'Sin servicios todavía no se pueden tomar turnos.',
        ),
        OnboardingStep(
          target: keys.tariffsTab,
          title: 'Tarifas por horario',
          body: 'Definí cuánto sale cada turno según el día y la hora.',
        ),
        OnboardingStep(
          target: keys.paymentsTab,
          title: 'Cobros online',
          body: 'Si querés cobrar señas o turnos online, vinculá tu cuenta de Mercado Pago. '
              'Podés volver a ver este recorrido desde el botón de ayuda de arriba.',
        ),
      ];

  static Future<void> showIfNew(BuildContext context, ClubConfigTourKeys keys, {required Future<void> Function() showInfoTab}) =>
      OnboardingTour.showIfNew(context, id: _id, steps: steps(keys, showInfoTab: showInfoTab));

  static Future<void> show(BuildContext context, ClubConfigTourKeys keys, {required Future<void> Function() showInfoTab}) =>
      OnboardingTour.show(context, id: _id, steps: steps(keys, showInfoTab: showInfoTab));
}
