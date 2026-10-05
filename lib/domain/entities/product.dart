class Product {
  final int productId;
  final int? clubId;
  final String name;
  final double price;

  /// Categoría (ej. "Bebidas"), para filtrar en "Agregar consumo".
  final String? categoryName;

  const Product({
    required this.productId,
    this.clubId,
    required this.name,
    required this.price,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];

    return Product(
      productId: (json['product_id'] as num).toInt(),
      clubId: (json['club_id'] as num?)?.toInt(),
      name: (json['name'] ?? '').toString(),
      price: rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice?.toString() ?? '0') ?? 0,
      categoryName: json['category_name'] as String?,
    );
  }
}
