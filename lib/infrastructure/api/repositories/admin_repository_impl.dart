import '../../../domain/entities/client.dart';
import '../../../domain/repositories/admin_repository.dart';
import '../providers/admin_provider.dart';

class AdminrepositroyImpl extends AdminRepository {

  final AdminProvider adminProvider;

  AdminrepositroyImpl({required this.adminProvider});
  Future<List<Client>> getClients(String search) async {

    return adminProvider.getClients(search);

  }
}