import 'package:flutter/material.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/features/home/presentation/widgets/product_card.dart';
import 'package:modern_go/features/home/presentation/pages/product_stores_page.dart';

enum ProductSortOption { none, priceLowToHigh, priceHighToLow }
enum ProductPriceFilter { all, under20, between20And50, over50 }

class AllProductsPage extends StatefulWidget {
  final List<StoreProduct> products;

  const AllProductsPage({super.key, required this.products});

  @override
  State<AllProductsPage> createState() => _AllProductsPageState();
}

class _AllProductsPageState extends State<AllProductsPage> {
  ProductSortOption _sortOption = ProductSortOption.none;
  ProductPriceFilter _priceFilter = ProductPriceFilter.all;
  late List<StoreProduct> _filteredProducts;

  @override
  void initState() {
    super.initState();
    _applyFiltersAndSorting();
  }

  void _applyFiltersAndSorting() {
    List<StoreProduct> result = List.from(widget.products);

    // Apply Price Filter
    result = result.where((sp) {
      final price = sp.product.salePrice > 0 ? sp.product.salePrice : sp.product.mainPrice;
      switch (_priceFilter) {
        case ProductPriceFilter.all:
          return true;
        case ProductPriceFilter.under20:
          return price < 20;
        case ProductPriceFilter.between20And50:
          return price >= 20 && price <= 50;
        case ProductPriceFilter.over50:
          return price > 50;
      }
    }).toList();

    // Apply Sorting
    if (_sortOption == ProductSortOption.priceLowToHigh) {
      result.sort((a, b) {
        final aPrice = a.product.salePrice > 0 ? a.product.salePrice : a.product.mainPrice;
        final bPrice = b.product.salePrice > 0 ? b.product.salePrice : b.product.mainPrice;
        return aPrice.compareTo(bPrice);
      });
    } else if (_sortOption == ProductSortOption.priceHighToLow) {
      result.sort((a, b) {
        final aPrice = a.product.salePrice > 0 ? a.product.salePrice : a.product.mainPrice;
        final bPrice = b.product.salePrice > 0 ? b.product.salePrice : b.product.mainPrice;
        return bPrice.compareTo(aPrice);
      });
    }

    setState(() {
      _filteredProducts = result;
    });
  }

  void _showFilterSortModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter & Sort',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Sort By', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSortChip('Default', ProductSortOption.none, setModalState),
                      _buildSortChip('Price: Low to High', ProductSortOption.priceLowToHigh, setModalState),
                      _buildSortChip('Price: High to Low', ProductSortOption.priceHighToLow, setModalState),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('All Prices', ProductPriceFilter.all, setModalState),
                      _buildFilterChip('Under \$20', ProductPriceFilter.under20, setModalState),
                      _buildFilterChip('\$20 - \$50', ProductPriceFilter.between20And50, setModalState),
                      _buildFilterChip('Over \$50', ProductPriceFilter.over50, setModalState),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFiltersAndSorting();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSortChip(String label, ProductSortOption option, StateSetter setModalState) {
    final isSelected = _sortOption == option;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setModalState(() {
          _sortOption = option;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
    );
  }

  Widget _buildFilterChip(String label, ProductPriceFilter filter, StateSetter setModalState) {
    final isSelected = _priceFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setModalState(() {
          _priceFilter = filter;
        });
      },
      backgroundColor: Colors.grey.shade100,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Available Products', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSortModal,
          ),
        ],
      ),
      body: _filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No products match your criteria.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _sortOption = ProductSortOption.none;
                        _priceFilter = ProductPriceFilter.all;
                        _applyFiltersAndSorting();
                      });
                    },
                    child: const Text('Clear Filters', style: TextStyle(color: AppColors.primary)),
                  )
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
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
            ),
    );
  }
}
