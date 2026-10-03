import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/label.dart';
import '../../../domain/repositories/label_repository.dart';
import 'base/base_repository.dart';

class LabelRepositoryImpl extends BaseRepository implements LabelRepository {

  final dioInstance = sl<Dio>();


  @override
  Future<RepositoryResponse<Label>> addLabelToClient(int clientId, Map<String, dynamic> labelData) {

    return safeCall(() async {
        final response = await dioInstance.post(
          "/admin/addLabel", 
          queryParameters: {
            "client_id":clientId
          },
          data:{
            "label":labelData
          }
        );

        return Label.fromJson(response.data['label']);

    },);

  }
  
  @override
  Future<RepositoryResponse<List<Label>>> getLabels() {
    
    return safeCall(() async {
      final response = await dioInstance.get("/admin/label");

      return response.data['labels'].map<Label>((label) => Label.fromJson(label)).toList();

    });
  }

}