import 'package:equatable/equatable.dart';
import 'product.dart';

/// Represents the many-to-many relationship between a Store and a Product.
/// Contains the store-specific price, stock, and availability.
class StoreProduct extends Equatable {
  final String id;
  final String storeId;
  final Product product;
  final double price;
  final int stock;
  final bool isAvailable;

  const StoreProduct({
    required this.id,
    required this.storeId,
    required this.product,
    required this.price,
    required this.stock,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [id, storeId, product.id, price];
}
