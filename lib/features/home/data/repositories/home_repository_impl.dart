import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:modern_go/core/api/api_client.dart';
import 'package:modern_go/core/constants/api_constants.dart';
import 'package:modern_go/core/error/failures.dart';
import 'package:modern_go/features/home/data/models/store_model.dart';
import 'package:modern_go/features/home/data/models/store_product_model.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/features/home/domain/repositories/home_repository.dart';
import 'package:modern_go/features/stores/domain/entities/store.dart';

class HomeRepositoryImpl implements HomeRepository {
  final ApiClient apiClient;

  HomeRepositoryImpl(this.apiClient);

  @override
  Future<Either<Failure, List<Store>>> getNearbyStores({
    required double longitude,
    required double latitude,
    int maxDistance = 5000,
  }) async {
    try {
      final response = await apiClient.get(
        ApiConstants.storeNearby,
        queryParameters: {
          'longitude': longitude,
          'latitude': latitude,
          'maxDistance': maxDistance,
        },
      );

      final storesJson = response.data['data']['stores'] as List? ?? [];
      final stores = storesJson
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      debugPrint('[Home] Fetched ${stores.length} nearby stores');
      return Right(stores);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      debugPrint('[Home] Error fetching nearby stores: $e');
      return Left(ServerFailure('Failed to load nearby stores: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Store>>> getAllStores() async {
    try {
      final response = await apiClient.get(ApiConstants.stores);

      final storesJson = response.data['data']['stores'] as List? ?? [];
      final stores = storesJson
          .map((e) => StoreModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      debugPrint('[Home] Fetched ${stores.length} stores (all)');
      return Right(stores);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      debugPrint('[Home] Error fetching all stores: $e');
      return Left(ServerFailure('Failed to load stores: $e'));
    }
  }

  @override
  Future<Either<Failure, List<StoreProduct>>> getStoreProducts(
      String storeId) async {
    try {
      final response = await apiClient.get(ApiConstants.storeProducts(storeId));

      final productsJson =
          response.data['data']['storeProducts'] as List? ?? [];
      final products = productsJson
          .map((e) =>
              StoreProductModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      debugPrint(
          '[Home] Fetched ${products.length} products for store $storeId');
      return Right(products);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      debugPrint('[Home] Error fetching store products: $e');
      return Left(ServerFailure('Failed to load products: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductStore>>> getProductStores(
      String productId) async {
    try {
      final response =
          await apiClient.get(ApiConstants.productStores(productId));

      final storesJson = response.data['data']['productStores'] as List? ?? [];
      final productStores = storesJson.map((e) {
        final json = Map<String, dynamic>.from(e as Map);
        // storeId is populated with full store object
        final storeData = json['storeId'];
        final store = storeData is Map
            ? StoreModel.fromJson(Map<String, dynamic>.from(storeData))
            : StoreModel(
                id: storeData?.toString() ?? '',
                name: 'Unknown Store',
                email: '',
                address: '',
                phone: '',
                location: const StoreLocationModel(
                    type: 'Point', coordinates: [0, 0]),
                categories: const [],
              );

        return ProductStore(
          store: store,
          price: (json['price'] as num?)?.toDouble() ?? 0,
          stock: (json['stock'] as num?)?.toInt() ?? 0,
          isAvailable: json['isAvailable'] as bool? ?? true,
        );
      }).toList();

      debugPrint(
          '[Home] Fetched ${productStores.length} stores for product $productId');
      return Right(productStores);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      debugPrint('[Home] Error fetching product stores: $e');
      return Left(ServerFailure('Failed to load stores for product: $e'));
    }
  }

  @override
  Future<Either<Failure, List<dynamic>>> searchNearby({
    required String query,
    required double longitude,
    required double latitude,
    int maxDistance = 5000,
  }) async {
    try {
      final response = await apiClient.get(
        ApiConstants.productStoresNearbySearch,
        queryParameters: {
          'query': query,
          'longitude': longitude,
          'latitude': latitude,
          'maxDistance': maxDistance,
        },
      );

      final results = response.data['data']['stores'] as List? ?? [];
      debugPrint('[Home] Search "$query" found ${results.length} results');
      return Right(results);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      debugPrint('[Home] Error searching: $e');
      return Left(ServerFailure('Search failed: $e'));
    }
  }

  String _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      return e.response!.data['message'] ?? 'An error occurred';
    }
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout';
    if (e.type == DioExceptionType.receiveTimeout)
      return 'Server is not responding';
    if (e.type == DioExceptionType.connectionError)
      return 'No internet connection';
    return 'Network error: ${e.message}';
  }
}
