import '../../core/utils/repository_response.dart';

/// Club recién dado de alta por un operador de Turni.
class CreatedClub {
  const CreatedClub({required this.clubId, required this.email, this.inviteSent = false});

  final int clubId;

  /// Email del dueño, ya normalizado: con esa cuenta de Google entra al panel.
  final String email;

  /// Si el back ya le mandó al dueño el mail de invitación. En false (envío
  /// desactivado o fallido) el operador lo manda a mano.
  final bool inviteSent;

  factory CreatedClub.fromJson(Map<String, dynamic> json) => CreatedClub(
        clubId: (json['club_id'] as num).toInt(),
        email: json['email'] as String,
        inviteSent: (json['invite'] as Map<String, dynamic>?)?['sent'] == true,
      );
}

/// Lo que hace un operador de Turni (`/platform/...`).
abstract class PlatformRepository {
  Future<RepositoryResponse<CreatedClub>> createClub({
    required String clubName,
    required String name,
    String lastName = '',
    required String email,
  });
}
