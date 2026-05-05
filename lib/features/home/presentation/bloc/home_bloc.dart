import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:modern_go/core/utils/location_service.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/features/home/domain/repositories/home_repository.dart';
import 'package:modern_go/features/stores/domain/entities/store.dart';

// ─── Events ──────────────────────────────────────────────────────────

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Load the home page data: nearby stores + products from those stores.
class HomeLoadRequested extends HomeEvent {}

/// Load all products for a specific store (used by StoreDetailPage).
class StoreProductsRequested extends HomeEvent {
  final String storeId;
  StoreProductsRequested(this.storeId);
  @override
  List<Object?> get props => [storeId];
}

/// Load all stores selling a specific product (used by ProductStoresPage).
class ProductStoresRequested extends HomeEvent {
  final String productId;
  ProductStoresRequested(this.productId);
  @override
  List<Object?> get props => [productId];
}

// ─── State ───────────────────────────────────────────────────────────

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final List<Store> stores;
  final List<StoreProduct> featuredProducts;
  final String? errorMessage;
  final double? userLatitude;
  final double? userLongitude;

  const HomeState({
    this.status = HomeStatus.initial,
    this.stores = const [],
    this.featuredProducts = const [],
    this.errorMessage,
    this.userLatitude,
    this.userLongitude,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<Store>? stores,
    List<StoreProduct>? featuredProducts,
    String? errorMessage,
    double? userLatitude,
    double? userLongitude,
  }) {
    return HomeState(
      status: status ?? this.status,
      stores: stores ?? this.stores,
      featuredProducts: featuredProducts ?? this.featuredProducts,
      errorMessage: errorMessage,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }

  @override
  List<Object?> get props => [
        status,
        stores,
        featuredProducts,
        errorMessage,
        userLatitude,
        userLongitude
      ];
}

// ─── Bloc ────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _homeRepository;
  final LocationService _locationService;

  HomeBloc({
    required HomeRepository homeRepository,
    required LocationService locationService,
  })  : _homeRepository = homeRepository,
        _locationService = locationService,
        super(const HomeState()) {
    on<HomeLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    HomeLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    // 1) Try to get user location
    final position = await _locationService.getCurrentPosition();
    final hasLocation = position != null;
    double? lat = position?.latitude;
    double? lng = position?.longitude;

    // 2) Fetch stores (nearby if location available, all stores otherwise)
    List<Store> stores = [];
    if (hasLocation) {
      final result = await _homeRepository.getNearbyStores(
        longitude: lng!,
        latitude: lat!,
      );
      result.fold(
        (failure) {
          debugPrint(
              '[HomeBloc] Nearby stores failed: ${failure.message}, falling back to all stores');
        },
        (data) => stores = data,
      );
    }

    // Fallback to all stores if no location or nearby returned empty
    if (stores.isEmpty) {
      final result = await _homeRepository.getAllStores();
      result.fold(
        (failure) {
          debugPrint('[HomeBloc] All stores also failed: ${failure.message}');
          emit(state.copyWith(
            status: HomeStatus.error,
            errorMessage: failure.message,
          ));
          return;
        },
        (data) => stores = data,
      );
    }

    // 3) Fetch products from the first few stores to populate "Available Products"
    List<StoreProduct> allProducts = [];
    final storesToFetch =
        stores.take(3); // Fetch from first 3 stores for variety
    for (final store in storesToFetch) {
      final result = await _homeRepository.getStoreProducts(store.id);
      result.fold(
        (failure) => debugPrint(
            '[HomeBloc] Products for ${store.name} failed: ${failure.message}'),
        (products) => allProducts.addAll(products),
      );
    }

    // Remove duplicates by product ID
    final seen = <String>{};
    final uniqueProducts = allProducts.where((sp) {
      final isNew = seen.add(sp.product.id);
      return isNew;
    }).toList();

    emit(state.copyWith(
      status: HomeStatus.loaded,
      stores: stores,
      featuredProducts: uniqueProducts,
      userLatitude: lat,
      userLongitude: lng,
    ));
  }
}
