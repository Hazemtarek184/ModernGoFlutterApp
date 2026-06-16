import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:modern_go/core/api/api_client.dart';
import 'package:modern_go/core/constants/api_constants.dart';
import 'package:modern_go/core/constants/app_colors.dart';
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});
  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}
class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final List<dynamic> _orders = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  static const int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _scrollController.addListener(_onScroll);
  }
  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _currentPage < _totalPages) {
      _fetchMoreOrders();
    }
  }
  Future<void> _fetchOrders() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
      _orders.clear();
      _currentPage = 1;
    });
    try {
      final client = GetIt.instance<ApiClient>();
      final response = await client.get(
        ApiConstants.myOrders,
        queryParameters: {'page': 1, 'limit': _pageSize},
      );
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['data'] == null ||
            responseData['data']['orders'] == null) {
          throw Exception(
              "Response data doesn't contain 'data.orders' payload.");
        }
        final ordersList =
            responseData['data']['orders'] as List<dynamic>;
        setState(() {
          _orders.addAll(ordersList);
          _currentPage = responseData['data']['page'] ?? 1;
          _totalPages = responseData['data']['totalPages'] ?? 1;
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ??
              'Failed to load orders (Status ${response.statusCode})';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      debugPrint("Error fetching orders: $e");
      final message = e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout
          ? 'Server is unreachable. Please check your connection and try again.'
          : e.type == DioExceptionType.connectionError
              ? 'Could not connect to the server. Please try again later.'
              : 'Failed to load orders. Please try again.';
      setState(() {
        _errorMessage = message;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching orders: $e");
      setState(() {
        _errorMessage = 'Failed to connect to server. Please try again.';
        _loading = false;
      });
    }
  }
  Future<void> _fetchMoreOrders() async {
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
    });
    try {
      final client = GetIt.instance<ApiClient>();
      final nextPage = _currentPage + 1;
      final response = await client.get(
        ApiConstants.myOrders,
        queryParameters: {'page': nextPage, 'limit': _pageSize},
      );
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        final ordersList =
            responseData['data']['orders'] as List<dynamic>? ?? [];
        setState(() {
          _orders.addAll(ordersList);
          _currentPage = responseData['data']['page'] ?? nextPage;
          _totalPages = responseData['data']['totalPages'] ?? _totalPages;
          _loadingMore = false;
        });
      } else {
        setState(() {
          _loadingMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching more orders: $e");
      setState(() {
        _loadingMore = false;
      });
    }
  }
  Widget _buildImage(String? base64Image, {double size = 50}) {
    if (base64Image == null || base64Image.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.image, color: Colors.grey),
      );
    }
    try {
      String cleanBase64 = base64Image;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
      while (cleanBase64.length % 4 != 0) {
        cleanBase64 += '=';
      }
      return Image.memory(
        base64Decode(cleanBase64),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: size,
          height: size,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text(
          'Order History',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchOrders,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No Orders Yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Your shopping activities and orders history will appear here once you make a purchase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          );
        }
        final order = _orders[index];
        final orderId = order['_id'] ?? '';
        final shortOrderId = orderId.length > 8
            ? orderId.substring(orderId.length - 8).toUpperCase()
            : orderId;
        final store = order['storeId'] ?? {};
        final storeName = store is Map ? (store['name'] ?? 'Store') : 'Store';
        final storePhoto = store is Map ? store['profilePhoto'] : null;
        final totalAmount = (order['totalAmount'] ?? 0.0).toDouble();
        final status = order['status'] ?? 'completed';
        final createdAtStr = order['createdAt'];
        DateTime? createdAt;
        if (createdAtStr != null) {
          createdAt = DateTime.tryParse(createdAtStr);
        }
        final formattedDate = createdAt != null
            ? DateFormat('MMM d, yyyy - h:mm a').format(createdAt.toLocal())
            : 'Unknown Date';
        final items = order['items'] as List<dynamic>? ?? [];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFD4EAD1), width: 1),
          ),
          elevation: 2,
          shadowColor: const Color(0xFFD4EAD1).withValues(alpha: 0.3),
          color: Colors.white,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImage(storePhoto, size: 48),
              ),
              title: Text(
                storeName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order ID: #$shortOrderId',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontFamily: 'monospace'),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusBadge(status),
                ],
              ),
              children: [
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFE8F8E5)),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Items Purchased',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) {
                        final storeProduct = item['storeProductId'] ?? {};
                        final product = storeProduct is Map
                            ? (storeProduct['productId'] ?? {})
                            : {};
                        final name = product is Map
                            ? (product['name'] ?? 'Product')
                            : 'Product';
                        final price = (item['price'] ?? 0.0).toDouble();
                        final quantity = item['quantity'] ?? 1;
                        final images = product is Map
                            ? (product['images'] as List<dynamic>? ?? [])
                            : <dynamic>[];
                        final image = images.isNotEmpty ? images.first : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildImage(image, size: 40),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Qty: $quantity x \$${price.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '\$${(price * quantity).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildStatusBadge(String status) {
    final isCompleted = status.toLowerCase() == 'completed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFE8F8E5)
            : const Color(0xFFFFECEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFFBBE5B3)
              : const Color(0xFFFFC5C1),
          width: 0.5,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isCompleted
              ? const Color(0xFF2E7D32)
              : const Color(0xFFC62828),
        ),
      ),
    );
  }
}
