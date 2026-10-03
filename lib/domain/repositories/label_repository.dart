import '../../core/utils/repository_response.dart';
import '../entities/label.dart';

abstract class LabelRepository {

  Future<RepositoryResponse<Label>> addLabelToClient(int clientId, Map<String, dynamic> labelData);

  Future<RepositoryResponse<List<Label>>> getLabels();

}