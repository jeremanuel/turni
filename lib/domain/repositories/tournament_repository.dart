import '../../core/utils/repository_response.dart';
import '../entities/tournament/tournament.dart';

/// Torneos del club, categorías de los clientes y ranking. Ver `turni_mono_be`,
/// docs/feature/TORNEOS.md.
abstract class TournamentRepository {
  /// Deportes del club con modalidades, categorías y canchas (formulario).
  Future<RepositoryResponse<List<CatalogSport>>> getCatalog();

  Future<RepositoryResponse<List<Tournament>>> getTournaments();

  /// Detalle: inscripciones con pagos, partidos y tablas.
  Future<RepositoryResponse<Tournament>> getTournament(int id);

  Future<RepositoryResponse<Tournament>> createTournament(TournamentDraft draft);

  Future<RepositoryResponse<Tournament>> updateTournament(int id, TournamentDraft draft);

  /// OPEN, CLOSED, DRAFT, FINISHED o CANCELLED.
  Future<RepositoryResponse<Tournament>> changeStatus(int id, TournamentStatus status);

  /// Sortea el cuadro. Con [force] sortea aunque no llegue al mínimo de equipos.
  Future<RepositoryResponse<Tournament>> draw(int id, {bool force = false});

  /// Cancha y horario del partido. Sin [courtId] ni [start] lo desprograma.
  Future<RepositoryResponse<void>> scheduleMatch(int tournamentId, int matchId, {int? courtId, DateTime? start, int? durationMinutes});

  /// El club carga o resuelve el resultado. SETS: [sets]; POINTS: [score].
  Future<RepositoryResponse<Tournament>> setMatchResult(int tournamentId, int matchId, {List<ScoreLine>? sets, ScoreLine? score});

  Future<RepositoryResponse<Tournament>> dropEntry(int tournamentId, int entryId);

  Future<RepositoryResponse<Tournament>> markPlayerPaid(int tournamentId, int entryId, int entryPlayerId);

  /// Aviso de pagos pendientes ya. Devuelve a cuántos equipos.
  Future<RepositoryResponse<int>> sendPaymentReminders(int tournamentId);

  /// Partidos programados entre [from] y [to], para la agenda.
  Future<RepositoryResponse<List<TournamentAgendaSlot>>> getAgendaSlots(DateTime from, DateTime to);

  Future<RepositoryResponse<CategorySettings>> getCategorySettings();

  /// [sports]: club_type_id → si lo categoriza. [city] null = sin cambio; con
  /// nombre vacío la borra.
  Future<RepositoryResponse<CategorySettings>> saveCategorySettings({Map<int, bool>? sports, ClubCity? city, bool clearCity = false});

  Future<RepositoryResponse<List<ClientSportCategories>>> getClientCategories(int clientId);

  /// Categoría del club y/o "en observación".
  Future<RepositoryResponse<List<ClientSportCategories>>> setClientCategory(
    int clientId, {
    required int clubTypeId,
    int? categoryId,
    CategoryObservation? observation,
  });

  /// Ranking del club o de su ciudad. [categoryId] null = torneos sin categoría.
  Future<RepositoryResponse<RankingResult>> getRanking({
    required int clubTypeId,
    int? categoryId,
    TournamentBranch? branch,
    bool city = false,
  });
}
