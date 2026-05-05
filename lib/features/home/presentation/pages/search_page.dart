import 'package:flutter/material.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/features/stores/domain/entities/store.dart';
import 'package:modern_go/features/home/presentation/widgets/product_card.dart';
import 'package:modern_go/features/home/presentation/widgets/store_card.dart';
import 'package:modern_go/features/home/presentation/pages/product_stores_page.dart';
import 'package:modern_go/features/home/presentation/pages/store_detail_page.dart';

class SearchPage extends StatefulWidget {
  final List<Store> allStores;
  final List<StoreProduct> allProducts;

  const SearchPage({
    super.key,
    required this.allStores,
    required this.allProducts,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Store> _filteredStores = [];
  List<StoreProduct> _filteredProducts = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    
    if (query == _query) return;
    
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredStores = [];
        _filteredProducts = [];
      } else {
        _filteredStores = widget.allStores
            .where((store) => store.name.toLowerCase().contains(query))
            .toList();
            
        _filteredProducts = widget.allProducts
            .where((sp) => sp.product.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _filteredProducts.isNotEmpty || _filteredStores.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search products & stores',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Type to start searching...',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            )
          : !hasResults
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No matches found for "$_query".',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    // --- Matching Products Section ---
                    if (_filteredProducts.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle('Matching Products (${_filteredProducts.length})'),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final sp = _filteredProducts[index];
                              return ProductCard(
                                storeProduct: sp,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductStoresPage(storeProduct: sp),
                                  ),
                                ),
                              );
                            },
                            childCount: _filteredProducts.length,
                          ),
                        ),
                      ),
                    ],

                    // --- Matching Stores Section ---
                    if (_filteredStores.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: _buildSectionTitle('Matching Stores (${_filteredStores.length})'),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final store = _filteredStores[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: SizedBox(
                                  height: 140, // Match Home Page StoreCard height
                                  child: StoreCard(
                                    store: store,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => StoreDetailPage(store: store),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _filteredStores.length,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}
