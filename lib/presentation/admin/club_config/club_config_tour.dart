import 'package:flutter/material.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/onboarding/onboarding_tour.dart';
import '../../../domain/entities/club_info.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../guides/admin_guides.dart';

/// Recorrido de Configuración para el dueño de un club recién dado de alta.
/// Los pasos son los de [AdminGuides.clubSetupSteps] (también es una guía
/// del signo de pregunta).
class ClubConfigTour {
  ClubConfigTour._();

  static String get _id => 'club_config:${sl<AuthCubit>().state.userCredential?.userId ?? ''}';

  /// Club sin dirección o sin ubicación: recién dado de alta.
  static bool isIncomplete(ClubInfo info) =>
      (info.address ?? '').trim().isEmpty || info.lat == null || info.lng == null;

  static Future<void> showIfNew(BuildContext context) =>
      OnboardingTour.showIfNew(context, id: _id, steps: AdminGuides.clubSetupSteps());

  static Future<void> show(BuildContext context) =>
      OnboardingTour.show(context, id: _id, steps: AdminGuides.clubSetupSteps());
}
