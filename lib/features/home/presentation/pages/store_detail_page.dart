import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shimmer/shimmer.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/features/home/domain/repositories/home_repository.dart';
import 'package:modern_go/features/home/presentation/pages/product_stores_page.dart';
import 'package:modern_go/features/stores/domain/entities/store.dart';
import 'package:modern_go/core/widgets/custom_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// Detail page for a store showing info, location, and products sold.
class StoreDetailPage extends StatefulWidget {
  final Store store;

  const StoreDetailPage({super.key, required this.store});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  List<StoreProduct>? _products;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final repo = GetIt.instance<HomeRepository>();
    final result = await repo.getStoreProducts(widget.store.id);
    if (mounted) {
      setState(() {
        result.fold(
          (failure) => _error = failure.message,
          (products) => _products = products,
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _openMap() async {
    if (widget.store.location.coordinates.length < 2) return;

    final lat = widget.store.location.coordinates[1];
    final lng = widget.store.location.coordinates[0];

    // Try multiple URI schemes to ensure it opens on different platforms/emulators
    final List<Uri> urisToTry = [
      // 1. Try native Google Maps geo intent (Android)
      Uri.parse('geo:$lat,$lng?q=$lat,$lng'),
      // 2. Try native Apple Maps intent (iOS)
      Uri.parse('maps:0,0?q=$lat,$lng'),
      // 3. Fallback to web browser Google Maps
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
    ];

    bool launched = false;

    for (final url in urisToTry) {
      try {
        if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
          launched = true;
          break;
        }
      } catch (_) {
        // Ignore and try the next one
      }
    }

    // If external application mode fails, try platform default (which might open in-app browser)
    if (!launched) {
      try {
        final webUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
        launched = await launchUrl(webUrl, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Map launch error: $e');
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open map. No map application found.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3), // Dark shadow backdrop
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.store.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.store.profilePhoto != null &&
                            widget.store.profilePhoto!.isNotEmpty
                        ? CustomNetworkImage(
                            imageUrl: widget.store.profilePhoto,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              size: 72,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                    // Gradient overlay to make text readable
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 100, // Covers the bottom area behind the text
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8), // Transparent black at bottom
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Store Info ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categories
                  if (widget.store.categories.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: widget.store.categories.map((cat) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),

                  // Info cards
                  _buildInfoRow(Icons.location_on_outlined, 'Address',
                      widget.store.address),
                  _buildInfoRow(
                      Icons.phone_outlined, 'Phone', widget.store.phone),
                  _buildInfoRow(
                      Icons.email_outlined, 'Email', widget.store.email),

                  // Location coordinates
                  if (widget.store.location.coordinates.length >= 2) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _openMap,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.map_outlined,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Get Directions',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.open_in_new_rounded, 
                                     size: 16, 
                                     color: AppColors.primary.withValues(alpha: 0.6)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (widget.store.distance != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatDistance(widget.store.distance!),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (widget.store.location.address != null) ...[
                              Text(
                                widget.store.location.address!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              'Lat: ${widget.store.location.coordinates[1].toStringAsFixed(6)}\n'
                              'Lng: ${widget.store.location.coordinates[0].toStringAsFixed(6)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Text(
                    'Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All products available at this store',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Products List ────────────────────────────────────
          if (_isLoading)
            SliverToBoxAdapter(child: _buildShimmerList())
          else if (_error != null)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.grey.shade500)),
                ),
              ),
            )
          else if (_products == null || _products!.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        'No products listed yet',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sp = _products![index];
                  return _buildProductTile(sp);
                },
                childCount: _products!.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(StoreProduct sp) {
    final product = sp.product;
    final images = product.images;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductStoresPage(storeProduct: sp),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 64,
                height: 64,
                color: AppColors.surface,
                child: images.isNotEmpty
                    ? CustomNetworkImage(
                        imageUrl: images.first,
                        fit: BoxFit.cover,
                        errorWidget: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      )
                    : const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${(product.discountPercent > 0 ? sp.price - (sp.price * (product.discountPercent / 100)) : sp.price).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.discountPercent > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          '\$${sp.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Stock indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sp.stock > 0
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sp.stock > 0 ? '${sp.stock}' : 'Out',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: sp.stock > 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(3, (_) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m away';
    return '${(meters / 1000).toStringAsFixed(1)}km away';
  }
}
