import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/utils/value_transformers.dart';

part 'admin_product.g.dart';

/// Shape de `/admin/product` (CRUD nuevo), distinto del `Product` ya
/// existente que consume el endpoint viejo de solo lectura `/admin/products`.
@JsonSerializable()
class AdminProduct {
  AdminProduct({
    required this.productId,
    required this.clubId,
    required this.categoryId,
    required this.name,
    required this.price,
    required this.active,
  });

  @JsonKey(name: 'product_id')
  final int productId;
  @JsonKey(name: 'club_id')
  final int clubId;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  final String name;
  @JsonKey(fromJson: ValueTransformers.fromJsonDouble)
  final double price;
  final bool active;

  Map<String, dynamic> toJson() => _$AdminProductToJson(this);
  factory AdminProduct.fromJson(Map<String, dynamic> json) =>
      _$AdminProductFromJson(json);
}
