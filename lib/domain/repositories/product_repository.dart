import '../../core/utils/repository_response.dart';
import '../entities/product.dart';

abstract class ProductRepository {
  Future<RepositoryResponse<List<Product>>> getProducts();
}
