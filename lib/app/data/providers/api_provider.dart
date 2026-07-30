import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_endpoints.dart';
import '../services/storage_service.dart';

class ApiProvider {
  // Generater Header HTTP
  Future<Map<String, String>> _getHeaders({bool withToken = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (withToken) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ===========================================================================
  // 1. AUTENTIKASI & USER
  // ===========================================================================

  // POST /api/auth/login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: await _getHeaders(withToken: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(response.body);
  }

  // POST /api/auth/register
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    String role = 'customer',
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.register),
      headers: await _getHeaders(withToken: false),
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'password': password,
        'role': role,
      }),
    );
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // 2. KATALOG PRODUK
  // ===========================================================================

  // GET /api/products
  Future<List<dynamic>> getProducts() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.products),
      headers: await _getHeaders(withToken: false),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Gagal memuat katalog produk');
    }
  }

  // GET /api/products/:id
  Future<Map<String, dynamic>> getProductById(int id) async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.productDetail(id)),
      headers: await _getHeaders(withToken: false),
    );
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // 3. TRANSAKSI & LOKASI GPS (LBS)
  // ===========================================================================

  // POST /api/orders
  Future<Map<String, dynamic>> createOrder({
    required int userId,
    required String shippingAddress,
    required double latitude,
    required double longitude,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.createOrder),
      headers: await _getHeaders(withToken: true),
      body: jsonEncode({
        'userId': userId,
        'shippingAddress': shippingAddress,
        'latitude': latitude,
        'longitude': longitude,
        'items': items,
      }),
    );
    return jsonDecode(response.body);
  }

  // GET /api/orders/my-orders
  Future<List<dynamic>> getMyOrders() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.myOrders),
      headers: await _getHeaders(withToken: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Gagal memuat riwayat pesanan');
    }
  }

  // ===========================================================================
  // 4. LOKASI TOKO
  // ===========================================================================

  // GET /api/store
  Future<Map<String, dynamic>> getStoreInfo() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.storeSettings),
      headers: await _getHeaders(withToken: false),
    );
    return jsonDecode(response.body);
  }
}