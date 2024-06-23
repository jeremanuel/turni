import '../entities/client.dart';

abstract class AdminRepository {
    Future<List<Client>> getClients(String search);
}