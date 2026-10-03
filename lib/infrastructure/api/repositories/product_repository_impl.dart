import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/repositories/product_repository.dart';
import 'base/base_repository.dart';

class ProductRepositoryImpl extends BaseRepository implements ProductRepository {
  final dioInstance = sl<Dio>();

  @override
  Future<RepositoryResponse<List<Product>>> getProducts() {
    return safeCall(() async {
      final response = await dioInstance.get('/admin/products');

      return (response.data['products'] as List)
          .map((product) => Product.fromJson(product as Map<String, dynamic>))
          .toList();
    });
  }
}
