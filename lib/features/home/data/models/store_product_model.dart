import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/features/home/data/models/product_model.dart';

class StoreProductModel extends StoreProduct {
  const StoreProductModel({
    required super.id,
    required super.storeId,
    required super.product,
    required super.price,
    required super.stock,
    required super.isAvailable,
  });

  /// Parse from the API response where `productId` is a populated object.
  /// Response shape: { _id, storeId, productId: { ...product }, price, stock, isAvailable }
  factory StoreProductModel.fromJson(Map<String, dynamic> json) {
    // storeId can be a string or a populated object
    final storeId = json['storeId'] is String
        ? json['storeId'] as String
        : (json['storeId'] is Map
            ? json['storeId']['_id'] as String? ?? ''
            : '');

    // productId is typically a populated object from GET /stores/:id/products
    final productData = json['productId'];
    final product = productData is Map<String, dynamic>
        ? ProductModel.fromJson(productData)
        : ProductModel(
            id: productData?.toString() ?? '',
            name: 'Unknown',
            slug: '',
            description: '',
            images: const [],
            mainPrice: 0,
            discountPercent: 0,
            salePrice: 0,
            stock: 0,
            soldItems: 0,
            createdBy: '',
          );

    return StoreProductModel(
      id: json['_id'] as String? ?? '',
      storeId: storeId,
      product: product,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}
