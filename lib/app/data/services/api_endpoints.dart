class ApiEndpoints {
  // Base URL
  static const String baseUrl = 'https://localize-api-one.vercel.app/api';

  // Autentikasi
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String users = '$baseUrl/auth/users';

  // Katalog Produk
  static const String products = '$baseUrl/products';

  // Transaksi & Pesanan
  static const String createOrder = '$baseUrl/orders';
  static const String myOrders = '$baseUrl/orders/my-orders';
  static const String adminOrders = '$baseUrl/orders/admin';

  // Lokasi & Pengaturan Toko
  static const String userLocations = '$baseUrl/users/locations';
  static const String storeSettings = '$baseUrl/store';

  // Helper Endpoint dengan Parameter Path ID
  static String userDetail(int id) => '$baseUrl/auth/users/$id';
  static String productDetail(int id) => '$baseUrl/products/$id';
}