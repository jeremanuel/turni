import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.g.dart';

@JsonSerializable()
class ProductCategory {
  ProductCategory({
    required this.categoryId,
    required this.clubId,
    required this.name,
    required this.active,
  });

  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'club_id')
  final int clubId;
  final String name;
  final bool active;

  Map<String, dynamic> toJson() => _$ProductCategoryToJson(this);
  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryFromJson(json);
}
