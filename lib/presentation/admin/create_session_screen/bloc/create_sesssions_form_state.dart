part of 'create_sesssions_form_bloc.dart';

@freezed
sealed class CreateSesssionsFormState with _$CreateSesssionsFormState {
  const factory CreateSesssionsFormState({
    @Default([]) List<ClubPartition> selectedClubPartitions,
    @Default([]) List<PhysicalPartition> selectedPhysicalPartitions,
    TimeInterval? interval,
    @Default([]) List<Session> sessions,

    @Default(false) bool savedSessions,

    /// true mientras la carga masiva está en vuelo (desde que se dispara
    /// CreateSessions hasta que el backend responde) — controla el spinner
    /// del botón "Crear turnos" y evita doble submit.
    @Default(false) bool isSubmitting,

    /// Turnos descartados en la última carga masiva (superposición u otro motivo).
    @Default([]) List<SkippedSession> skippedSessions,

    /// Cuántos turnos se crearon exitosamente en la última carga masiva.
    @Default(0) int createdCount,

    /// Preset de rango de fechas elegido (reemplaza al calendario como
    /// forma principal de elegir el rango — ver DatePreset).
    @Default(DatePreset.week) DatePreset datePreset,

    /// Turnos de la plantilla quitados SOLO para esta cancha (partition
    /// physical id -> sesiones de `sessions` excluidas en esa columna).
    @Default({}) Map<int, List<Session>> courtRemovedSessions,

    /// Turnos agregados SOLO para esta cancha, fuera de la plantilla.
    @Default({}) Map<int, List<Session>> courtExtraSessions,

    /// Tarifas por horario de cada modalidad seleccionada (club partition
    /// id -> tarifas). Se cargan al seleccionar la modalidad.
    @Default({}) Map<int, List<PriceTariff>> tariffsByClubPartition,

    /// true mientras se están trayendo tarifas del backend.
    @Default(false) bool isLoadingTariffs,

    /// Día de la semana (1 = lunes ... 7 = domingo) con el que se previsualizan
    /// los precios en el paso "Canchas": la plantilla es un único día que se
    /// repite en todo el rango, y una tarifa puede cobrar distinto según el día.
    @Default(1) int priceDayOfWeek,

    /// Precio pisado a mano por el admin para un turno puntual de una cancha
    /// (partition physical id -> turno -> precio). Aplica a todos los días.
    @Default({}) Map<int, Map<Session, double>> courtManualPrices,
  }) = _CreateSessionManagerState;

  const CreateSesssionsFormState._();

  /// La plantilla aplicada a una cancha puntual, con sus ajustes propios
  /// (quitados/agregados) ya resueltos — lo que realmente se va a crear ahi.
  List<Session> effectiveSessionsForPartition(int partitionPhysicalId) {
    final removed = courtRemovedSessions[partitionPhysicalId] ?? const [];
    final extra = courtExtraSessions[partitionPhysicalId] ?? const [];
    final base = sessions.where((s) => !removed.contains(s));
    return [...base, ...extra]..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Resolvedor de precios con las tarifas cargadas de todas las modalidades.
  SessionPriceResolver get priceResolver => SessionPriceResolver(
        tariffsByClubPartition.values.expand((tariffs) => tariffs).toList(),
      );

  double? manualPriceFor(int partitionPhysicalId, Session session) =>
      courtManualPrices[partitionPhysicalId]?[session];

  /// Precio de [session] en [partition] para el día [dayOfWeek] (por default,
  /// el día elegido para previsualizar), con la regla que lo determina.
  ResolvedSessionPrice resolvePrice(
    PhysicalPartition partition,
    Session session, {
    SessionPriceResolver? resolver,
    int? dayOfWeek,
  }) {
    return (resolver ?? priceResolver).resolve(
      partition: partition,
      dayOfWeek: dayOfWeek ?? priceDayOfWeek,
      startMinutes: session.startTime.hour * 60 + session.startTime.minute,
      manualPrice: manualPriceFor(partition.partitionPhysicalId, session),
    );
  }
}
