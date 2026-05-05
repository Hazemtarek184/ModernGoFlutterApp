import 'package:flutter/material.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/stores/domain/entities/store.dart';
import 'package:modern_go/features/home/presentation/widgets/store_card.dart';
import 'package:modern_go/features/home/presentation/pages/store_detail_page.dart';

class AllStoresPage extends StatefulWidget {
  final List<Store> stores;

  const AllStoresPage({super.key, required this.stores});

  @override
  State<AllStoresPage> createState() => _AllStoresPageState();
}

class _AllStoresPageState extends State<AllStoresPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  late List<String> _categories;
  late List<Store> _filteredStores;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AllStoresPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stores != oldWidget.stores) {
      _initData();
    }
  }

  void _initData() {
    // Extract unique categories from all stores
    final Set<String> uniqueCategories = {};
    for (var store in widget.stores) {
      uniqueCategories.addAll(store.categories);
    }
    
    _categories = ['All', ...uniqueCategories.toList()..sort()];
    
    // Maintain selection if possible
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }
    _filterStores();
  }

  void _onCategorySelected(String category) {
    _selectedCategory = category;
    _filterStores();
  }

  void _filterStores() {
    setState(() {
      _filteredStores = widget.stores.where((store) {
        final matchesCategory = _selectedCategory == 'All' ||
            store.categories.contains(_selectedCategory);
        final matchesSearch = _searchQuery.isEmpty ||
            store.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Stores', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _searchQuery = value;
                _filterStores();
              },
              decoration: InputDecoration(
                hintText: 'Search stores...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery = '';
                          _filterStores();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_categories.length > 1) ...[
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => _onCategorySelected(category),
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _filteredStores.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No stores matching "$_searchQuery".'
                              : 'No stores found in this category.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filteredStores.length,
                    itemBuilder: (context, index) {
                      final store = _filteredStores[index];
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
          ),
        ],
      ),
    );
  }
}
