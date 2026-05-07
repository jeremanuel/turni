class Product {
  final int productId;
  final int? clubId;
  final String name;
  final double price;

  const Product({
    required this.productId,
    this.clubId,
    required this.name,
    required this.price,
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
    );
  }
}
