import '../../core/utils/entities/range_date.dart';
import '../entities/client.dart';
import '../entities/generic_search_item.dart';

abstract class AdminRepository {
    Future<List<Client>> getClients(String search);
    Future<List<GenericSearchItem>> genericSearch(String searchType, RangeDate rangeDate);
}