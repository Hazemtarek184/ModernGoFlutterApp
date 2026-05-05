class ApiConstants {
  static const String baseUrl = 'https://modern-go.vercel.app/api';
  // static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Socket.IO Server (real-time cart)
  // Android emulator: 10.0.2.2 maps to host localhost
  // Physical device: use your computer's LAN IP (e.g., 192.168.x.x)
  static const String socketUrl = 'http://10.0.2.2:3001';

  // Auth Endpoints
  static const String login = '/customers/login';
  static const String register = '/customers/register';
  static const String customerMe = '/customers/me';

  // Customer Profile Endpoints (append /:customerId)
  static const String customers = '/customers';

  // Stores Endpoints
  static const String stores = '/stores';
  static const String storeSearch = '/stores/search';
  static const String storeCategory = '/stores/category'; // append /:category
  static const String storeNearby = '/stores/nearby';

  // Products Endpoints
  static const String products = '/products';
  // GET /stores/:storeId/products — products in a store
  // GET /products/:productId/stores — stores selling a product
  // GET /products/:productId/stores/nearby — nearby stores for product by ID
  static const String productStoresNearbySearch =
      '/products/stores/nearby'; // query param: ?query=

  // Helper methods for dynamic paths
  static String customerProfile(String customerId) => '/customers/$customerId';
  static String customerPassword(String customerId) =>
      '/customers/$customerId/password';
  static String storeById(String storeId) => '/stores/$storeId';
  static String storeProducts(String storeId) => '/stores/$storeId/products';
  static String storesByCategory(String category) =>
      '/stores/category/$category';
  static String productStores(String productId) =>
      '/products/$productId/stores';
  static String productStoresNearby(String productId) =>
      '/products/$productId/stores/nearby';
}
