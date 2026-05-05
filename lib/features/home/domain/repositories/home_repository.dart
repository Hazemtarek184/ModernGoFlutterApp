import 'package:dartz/dartz.dart';
import 'package:modern_go/core/error/failures.dart';
import 'package:modern_go/features/stores/domain/entities/store.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';

/// Represents a store that sells a particular product, with store-specific pricing.
class ProductStore {
  final Store store;
  final double price;
  final int stock;
  final bool isAvailable;

  const ProductStore({
    required this.store,
    required this.price,
    required this.stock,
    required this.isAvailable,
  });
}

abstract class HomeRepository {
  /// Fetch stores near the given coordinates.
  Future<Either<Failure, List<Store>>> getNearbyStores({
    required double longitude,
    required double latitude,
    int maxDistance = 5000,
  });

  /// Fetch all stores (fallback when location unavailable).
  Future<Either<Failure, List<Store>>> getAllStores();

  /// Fetch all products sold by a given store.
  Future<Either<Failure, List<StoreProduct>>> getStoreProducts(String storeId);

  /// Fetch all stores that sell a given product.
  Future<Either<Failure, List<ProductStore>>> getProductStores(
      String productId);

  /// Search nearby stores by product name.
  Future<Either<Failure, List<dynamic>>> searchNearby({
    required String query,
    required double longitude,
    required double latitude,
    int maxDistance = 5000,
  });
}
