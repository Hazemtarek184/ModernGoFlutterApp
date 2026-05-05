import 'package:modern_go/features/home/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.description,
    required super.images,
    required super.mainPrice,
    required super.discountPercent,
    required super.salePrice,
    required super.stock,
    required super.soldItems,
    required super.createdBy,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Product',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mainPrice: (json['mainPrice'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      soldItems: (json['soldItems'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] is String
          ? json['createdBy'] as String
          : (json['createdBy'] is Map
              ? json['createdBy']['_id'] as String? ?? ''
              : ''),
    );
  }
}
