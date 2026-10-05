import 'package:dio/dio.dart';

import '../../../core/config/service_locator.dart';
import '../../../core/utils/domain_error.dart';
import '../../../core/utils/either.dart';
import '../../../core/utils/repository_response.dart';
import '../../../domain/entities/admin_product.dart';
import '../../../domain/entities/product_category.dart';
import '../../../domain/repositories/product_admin_repository.dart';

class ProductAdminRepositoryImpl implements ProductAdminRepository {
  final dioInstance = sl<Dio>();

  Future<RepositoryResponse<T>> _safeCall<T>(Future<T> Function() fn) async {
    try {
      final data = await fn();
      return Either.right(data);
    } on DioException catch (err) {
      final response = err.response?.data;
      if (response == null) return Either.left(DomainError.unknownError());
      return Either.left(DomainError.fromErrorResponse(response));
    }
  }

  @override
  Future<RepositoryResponse<List<ProductCategory>>> listCategories({bool includeInactive = true}) {
    return _safeCall(() async {
      final response = await dioInstance.get(
        '/admin/product_category',
        queryParameters: {'includeInactive': includeInactive},
      );

      return (response.data as List)
          .map((row) => ProductCategory.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<ProductCategory>> createCategory(String name) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/product_category', data: {'name': name});
      return ProductCategory.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ProductCategory>> renameCategory(int categoryId, String name) {
    return _safeCall(() async {
      final response = await dioInstance.put('/admin/product_category/$categoryId', data: {'name': name});
      return ProductCategory.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<ProductCategory>> setCategoryActive(int categoryId, bool active) {
    return _safeCall(() async {
      final response = await dioInstance.patch(
        '/admin/product_category/$categoryId/active',
        data: {'active': active},
      );
      return ProductCategory.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<List<AdminProduct>>> listProducts({bool includeInactive = true}) {
    return _safeCall(() async {
      final response = await dioInstance.get(
        '/admin/product',
        queryParameters: {'includeInactive': includeInactive},
      );

      return (response.data as List)
          .map((row) => AdminProduct.fromJson(row as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<RepositoryResponse<AdminProduct>> createProduct({
    required String name,
    required double price,
    int? categoryId,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.post('/admin/product', data: {
        'name': name,
        'price': price,
        if (categoryId != null) 'category_id': categoryId,
      });

      return AdminProduct.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<AdminProduct>> updateProduct(
    int productId, {
    String? name,
    double? price,
    int? categoryId,
  }) {
    return _safeCall(() async {
      final response = await dioInstance.put('/admin/product/$productId', data: {
        if (name != null) 'name': name,
        if (price != null) 'price': price,
        if (categoryId != null) 'category_id': categoryId,
      });

      return AdminProduct.fromJson(response.data as Map<String, dynamic>);
    });
  }

  @override
  Future<RepositoryResponse<AdminProduct>> setProductActive(int productId, bool active) {
    return _safeCall(() async {
      final response = await dioInstance.patch(
        '/admin/product/$productId/active',
        data: {'active': active},
      );

      return AdminProduct.fromJson(response.data as Map<String, dynamic>);
    });
  }
}
