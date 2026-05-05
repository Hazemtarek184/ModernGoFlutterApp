import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/home/presentation/bloc/home_bloc.dart';
import 'package:modern_go/features/home/presentation/widgets/home_header.dart';
import 'package:modern_go/features/home/presentation/widgets/store_card.dart';
import 'package:modern_go/features/home/presentation/widgets/product_card.dart';
import 'package:modern_go/features/home/presentation/pages/store_detail_page.dart';
import 'package:modern_go/features/home/presentation/pages/product_stores_page.dart';
import 'package:modern_go/features/home/presentation/pages/all_stores_page.dart';
import 'package:modern_go/features/home/presentation/pages/all_products_page.dart';
import 'package:modern_go/features/home/presentation/pages/search_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback? onNavigateToStores;

  const HomePage({super.key, this.onNavigateToStores});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeBloc _homeBloc;

  @override
  void initState() {
    super.initState();
    _homeBloc = GetIt.instance<HomeBloc>();
    _homeBloc.add(HomeLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            _homeBloc.add(HomeLoadRequested());
            // Wait for state change
            await _homeBloc.stream.firstWhere(
              (s) =>
                  s.status == HomeStatus.loaded || s.status == HomeStatus.error,
            );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Green Header + Search ───────────────────
                HomeHeader(
                  onSearchTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SearchPage(
                          allStores: _homeBloc.state.stores,
                          allProducts: _homeBloc.state.featuredProducts,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Stores Near You ─────────────────────────
                _buildSectionTitle('Stores Near You', 'View All', onTap: () {
                  if (widget.onNavigateToStores != null) {
                    widget.onNavigateToStores!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AllStoresPage(stores: _homeBloc.state.stores),
                      ),
                    );
                  }
                }),
                const SizedBox(height: 12),
                _buildStoresSection(),
                const SizedBox(height: 28),

                // ── Available Products ──────────────────────
                _buildSectionTitle('Available Products', 'See All >>', onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AllProductsPage(products: _homeBloc.state.featuredProducts),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _buildProductsSection(),
                const SizedBox(height: 24),

                // ── Deals Banner ────────────────────────────
                _buildDealsBanner(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String actionText,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stores Section ────────────────────────────────────────────────

  Widget _buildStoresSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading) {
          return _buildShimmerRow(itemWidth: 120, itemHeight: 130);
        }

        if (state.status == HomeStatus.error || state.stores.isEmpty) {
          return _buildEmptySection(
            icon: Icons.storefront_outlined,
            message: state.status == HomeStatus.error
                ? 'Could not load stores'
                : 'No stores found nearby',
          );
        }

        return SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.stores.length,
            itemBuilder: (context, index) {
              final store = state.stores[index];
              return StoreCard(
                store: store,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoreDetailPage(store: store),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Products Section ──────────────────────────────────────────────

  Widget _buildProductsSection() {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.status == HomeStatus.loading) {
          return _buildShimmerRow(itemWidth: 170, itemHeight: 220);
        }

        if (state.status == HomeStatus.error ||
            state.featuredProducts.isEmpty) {
          return _buildEmptySection(
            icon: Icons.shopping_bag_outlined,
            message: state.status == HomeStatus.error
                ? 'Could not load products'
                : 'No products available',
          );
        }

        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: state.featuredProducts.length,
            itemBuilder: (context, index) {
              final sp = state.featuredProducts[index];
              return ProductCard(
                storeProduct: sp,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductStoresPage(storeProduct: sp),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Deals Banner ──────────────────────────────────────────────────

  Widget _buildDealsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crazy deals!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Discover amazing offers from stores near you',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  Widget _buildShimmerRow(
      {required double itemWidth, required double itemHeight}) {
    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: itemWidth,
                height: itemHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptySection({required IconData icon, required String message}) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
