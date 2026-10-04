import '../../core/utils/repository_response.dart';
import '../entities/admin_product.dart';
import '../entities/product_category.dart';

/// CRUD de productos (`/admin/product`) y categorías (`/admin/product_category`)
/// para la pantalla de configuración de admin.
abstract class ProductAdminRepository {
  Future<RepositoryResponse<List<ProductCategory>>> listCategories({bool includeInactive = true});
  Future<RepositoryResponse<ProductCategory>> createCategory(String name);
  Future<RepositoryResponse<ProductCategory>> renameCategory(int categoryId, String name);
  Future<RepositoryResponse<ProductCategory>> setCategoryActive(int categoryId, bool active);

  Future<RepositoryResponse<List<AdminProduct>>> listProducts({bool includeInactive = true});
  Future<RepositoryResponse<AdminProduct>> createProduct({
    required String name,
    required double price,
    int? categoryId,
  });
  Future<RepositoryResponse<AdminProduct>> updateProduct(
    int productId, {
    String? name,
    double? price,
    int? categoryId,
  });
  Future<RepositoryResponse<AdminProduct>> setProductActive(int productId, bool active);
}
