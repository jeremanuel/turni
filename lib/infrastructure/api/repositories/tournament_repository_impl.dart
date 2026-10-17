import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/tournament/tournament.dart';
import '../../../domain/repositories/tournament_repository.dart';
import 'base/base_repository.dart';

class TournamentRepositoryImpl extends BaseRepository implements TournamentRepository {
  final dioInstance = sl<Dio>();

  static const _path = '/admin/tournament';

  Tournament _tournament(Response response) => Tournament.fromJson(response.data as Map<String, dynamic>);

  @override
  Future<RepositoryResponse<List<CatalogSport>>> getCatalog() {
    return safeCall(() async {
      final response = await dioInstance.get('$_path/catalog');
      return ((response.data as Map<String, dynamic>)['sports'] as List)
          .map((e) => CatalogSport.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<List<Tournament>>> getTournaments() {
    return safeCall(() async {
      final response = await dioInstance.get(_path);
      return (response.data as List).map((e) => Tournament.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<RepositoryResponse<Tournament>> getTournament(int id) {
    return safeCall(() async => _tournament(await dioInstance.get('$_path/$id')));
  }

  @override
  Future<RepositoryResponse<Tournament>> createTournament(TournamentDraft draft) {
    return safeCall(() async => _tournament(await dioInstance.post(_path, data: draft.toJson())));
  }

  @override
  Future<RepositoryResponse<Tournament>> updateTournament(int id, TournamentDraft draft) {
    return safeCall(() async => _tournament(await dioInstance.put('$_path/$id', data: draft.toJson())));
  }

  @override
  Future<RepositoryResponse<Tournament>> changeStatus(int id, TournamentStatus status) {
    return safeCall(() async => _tournament(await dioInstance.post('$_path/$id/status', data: {'status': tournamentStatusCode(status)})));
  }

  @override
  Future<RepositoryResponse<Tournament>> draw(int id, {bool force = false}) {
    return safeCall(() async => _tournament(await dioInstance.post('$_path/$id/draw', data: {'force': force})));
  }

  @override
  Future<RepositoryResponse<void>> scheduleMatch(int tournamentId, int matchId, {int? courtId, DateTime? start, int? durationMinutes}) {
    return safeCall(() async {
      await dioInstance.put('$_path/$tournamentId/matches/$matchId/schedule', data: {
        'partition_physical_id': courtId,
        'start_time': start?.toUtc().toIso8601String(),
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      });
    });
  }

  @override
  Future<RepositoryResponse<Tournament>> setMatchResult(int tournamentId, int matchId, {List<ScoreLine>? sets, ScoreLine? score}) {
    return safeCall(() async => _tournament(await dioInstance.post('$_path/$tournamentId/matches/$matchId/result', data: {
          if (sets != null) 'sets': sets.map((s) => s.toJson()).toList(),
          if (score != null) 'score': score.toJson(),
        })));
  }

  @override
  Future<RepositoryResponse<Tournament>> dropEntry(int tournamentId, int entryId) {
    return safeCall(() async => _tournament(await dioInstance.post('$_path/$tournamentId/entries/$entryId/drop')));
  }

  @override
  Future<RepositoryResponse<Tournament>> markPlayerPaid(int tournamentId, int entryId, int entryPlayerId) {
    return safeCall(() async => _tournament(await dioInstance.post('$_path/$tournamentId/entries/$entryId/players/$entryPlayerId/mark-paid')));
  }

  @override
  Future<RepositoryResponse<int>> sendPaymentReminders(int tournamentId) {
    return safeCall(() async {
      final response = await dioInstance.post('$_path/$tournamentId/reminders');
      return (response.data as Map<String, dynamic>)['sent'] as int;
    });
  }

  @override
  Future<RepositoryResponse<List<TournamentAgendaSlot>>> getAgendaSlots(DateTime from, DateTime to) {
    return safeCall(() async {
      final response = await dioInstance.get('$_path/sessions', queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      });
      return (response.data as List).map((e) => TournamentAgendaSlot.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  @override
  Future<RepositoryResponse<CategorySettings>> getCategorySettings() {
    return safeCall(() async {
      final response = await dioInstance.get('/admin/categories/settings');
      return CategorySettings.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<CategorySettings>> saveCategorySettings({Map<int, bool>? sports, ClubCity? city, bool clearCity = false}) {
    return safeCall(() async {
      final response = await dioInstance.put('/admin/categories/settings', data: {
        if (sports != null) 'sports': [for (final e in sports.entries) {'club_type_id': e.key, 'categorizes': e.value}],
        if (city != null) 'city': {'name': city.name, 'province': city.province},
        if (clearCity) 'city': null,
      });
      return CategorySettings.fromJson(response.data as Map<String, dynamic>);
    });
  }

  List<ClientSportCategories> _clientSports(Response response) =>
      ((response.data as Map<String, dynamic>)['sports'] as List).map((e) => ClientSportCategories.fromJson(e as Map<String, dynamic>)).toList();

  @override
  Future<RepositoryResponse<List<ClientSportCategories>>> getClientCategories(int clientId) {
    return safeCall(() async => _clientSports(await dioInstance.get('/admin/categories/clients/$clientId')));
  }

  @override
  Future<RepositoryResponse<List<ClientSportCategories>>> setClientCategory(
    int clientId, {
    required int clubTypeId,
    int? categoryId,
    CategoryObservation? observation,
  }) {
    return safeCall(() async => _clientSports(await dioInstance.put('/admin/categories/clients/$clientId', data: {
          'club_type_id': clubTypeId,
          if (categoryId != null) 'sport_category_id': categoryId,
          if (observation != null) 'observation': observationCode(observation),
        })));
  }

  @override
  Future<RepositoryResponse<RankingResult>> getRanking({
    required int clubTypeId,
    int? categoryId,
    TournamentBranch? branch,
    bool city = false,
  }) {
    return safeCall(() async {
      final response = await dioInstance.get('/admin/ranking', queryParameters: {
        'club_type_id': clubTypeId,
        'sport_category_id': categoryId?.toString() ?? 'null',
        if (branch != null) 'branch': branchCode(branch),
        'scope': city ? 'city' : 'club',
      });
      return RankingResult.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
