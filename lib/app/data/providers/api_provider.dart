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
    String? imagePath,
    List<int>? imageBytes,
    String? addressText,
    double? latitude,
    double? longitude,
  }) async {
    if ((imagePath != null && imagePath.isNotEmpty) || (imageBytes != null && imageBytes.isNotEmpty)) {
      final request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.register));
      request.fields['fullName'] = fullName;
      request.fields['email'] = email;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['password'] = password;
      request.fields['role'] = role;
      if (addressText != null) request.fields['addressText'] = addressText;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      if (imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(http.MultipartFile.fromBytes(
          'imageFile',
          imageBytes,
          filename: 'avatar.jpg',
        ));
      } else if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'imageFile',
          imagePath,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } else {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: await _getHeaders(withToken: false),
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          'password': password,
          'role': role,
          if (addressText != null) 'addressText': addressText,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );
      return jsonDecode(response.body);
    }
  }

  // PUT /api/auth/users/:id
  Future<Map<String, dynamic>> updateUser({
    required int id,
    String? fullName,
    String? phoneNumber,
    String? role,
    String? imagePath,
    List<int>? imageBytes,
  }) async {
    final request = http.MultipartRequest('PUT', Uri.parse('${ApiEndpoints.baseUrl}/auth/users/$id'));
    final headers = await _getHeaders(withToken: true);
    request.headers.addAll(headers);

    if (fullName != null) request.fields['fullName'] = fullName;
    if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;
    if (role != null) request.fields['role'] = role;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'imageFile',
        imageBytes,
        filename: 'avatar.jpg',
      ));
    } else if (imagePath != null && imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath(
        'imageFile',
        imagePath,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
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

  // GET /api/auth/users/:id
  Future<Map<String, dynamic>> getUserById(int id) async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/auth/users/$id'),
      headers: await _getHeaders(withToken: true),
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
    String? addressNotes,
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
        'addressNotes': addressNotes ?? '',
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

  // ===========================================================================
  // 5. KERANJANG BELANJA (CART)
  // ===========================================================================

  // GET /api/cart
  Future<List<dynamic>> getMyCart() async {
    final response = await http.get(
      Uri.parse('${ApiEndpoints.baseUrl}/cart'),
      headers: await _getHeaders(withToken: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Gagal memuat keranjang belanja');
    }
  }

  // POST /api/cart
  Future<Map<String, dynamic>> addToCart({
    required int productId,
    required String size,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiEndpoints.baseUrl}/cart'),
      headers: await _getHeaders(withToken: true),
      body: jsonEncode({
        'productId': productId,
        'size': size,
        'quantity': quantity,
      }),
    );
    return jsonDecode(response.body);
  }

  // PUT /api/cart/:id
  Future<Map<String, dynamic>> updateCartItem({
    required int id,
    required int quantity,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiEndpoints.baseUrl}/cart/$id'),
      headers: await _getHeaders(withToken: true),
      body: jsonEncode({
        'quantity': quantity,
      }),
    );
    return jsonDecode(response.body);
  }

  // DELETE /api/cart/:id
  Future<Map<String, dynamic>> removeCartItem(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/cart/$id'),
      headers: await _getHeaders(withToken: true),
    );
    return jsonDecode(response.body);
  }

  // DELETE /api/cart
  Future<Map<String, dynamic>> clearMyCart() async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/cart'),
      headers: await _getHeaders(withToken: true),
    );
    return jsonDecode(response.body);
  }

  // POST /api/orders/:id/payment-proof
  Future<Map<String, dynamic>> uploadPaymentProof({
    required int orderId,
    required String imagePath,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId/payment-proof'));
    final headers = await _getHeaders(withToken: true);
    request.headers.addAll(headers);

    request.files.add(await http.MultipartFile.fromPath(
      'imageFile',
      imagePath,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return jsonDecode(response.body);
  }

  // POST /api/orders/:id/cancel → user membatalkan pesanannya sendiri
  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final response = await http.post(
      Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId/cancel'),
      headers: await _getHeaders(withToken: true),
    );
    return jsonDecode(response.body);
  }

  // GET /api/users/locations
  Future<List<dynamic>> getMyLocations() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.userLocations),
      headers: await _getHeaders(withToken: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Gagal memuat daftar lokasi');
    }
  }

  // PUT /api/users/locations/:id
  Future<Map<String, dynamic>> updateLocation({
    required int id,
    String? label,
    required String addressText,
    String? addressNotes,
    required double latitude,
    required double longitude,
    int? isPrimary,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiEndpoints.userLocations}/$id'),
      headers: await _getHeaders(withToken: true),
      body: jsonEncode({
        'label': label ?? 'Rumah',
        'addressText': addressText,
        'addressNotes': addressNotes ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'isPrimary': isPrimary ?? 1,
      }),
    );
    return jsonDecode(response.body);
  }

  // POST /api/users/locations
  Future<Map<String, dynamic>> addLocation({
    String? label,
    required String addressText,
    String? addressNotes,
    required double latitude,
    required double longitude,
    int? isPrimary,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.userLocations),
      headers: await _getHeaders(withToken: true),
      body: jsonEncode({
        'label': label ?? 'Rumah',
        'addressText': addressText,
        'latitude': latitude,
        'longitude': longitude,
        'isPrimary': isPrimary ?? 1,
      }),
    );
    return jsonDecode(response.body);
  }

  // ===========================================================================
  // 6. ADMIN API (PRODUK & PESANAN)
  // ===========================================================================

  // GET /api/orders/admin
  Future<List<dynamic>> getAdminOrders() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.adminOrders),
      headers: await _getHeaders(withToken: true),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] ?? [];
    } else {
      throw Exception('Gagal memuat daftar pesanan admin');
    }
  }

  // PUT /api/orders/:id/status (Admin ubah status pesanan: dibayar, dikirim, selesai, batal)
  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId/status'),
      headers: await _getHeaders(withToken: true),
      body: jsonEncode({'status': status}),
    );
    return jsonDecode(response.body);
  }

  // POST /api/products (Tambah Produk dengan Opsional Gambar File)
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String brand,
    required String description,
    required double price,
    required Map<String, dynamic> sizeStock,
    String? imageUrl,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      final request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.products));
      final headers = await _getHeaders(withToken: true);
      request.headers.addAll(headers);

      request.fields['name'] = name;
      request.fields['brand'] = brand;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['sizeStock'] = jsonEncode(sizeStock);
      if (imageUrl != null) request.fields['imageUrl'] = imageUrl;

      request.files.add(await http.MultipartFile.fromPath('imageFile', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } else {
      final response = await http.post(
        Uri.parse(ApiEndpoints.products),
        headers: await _getHeaders(withToken: true),
        body: jsonEncode({
          'name': name,
          'brand': brand,
          'description': description,
          'price': price,
          'sizeStock': sizeStock,
          'imageUrl': imageUrl ?? '',
        }),
      );
      return jsonDecode(response.body);
    }
  }

  // PUT /api/products/:id (Update Produk)
  Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String name,
    required String brand,
    required String description,
    required double price,
    required Map<String, dynamic> sizeStock,
    String? imageUrl,
    String? imagePath,
  }) async {
    if (imagePath != null && imagePath.isNotEmpty) {
      final request = http.MultipartRequest('PUT', Uri.parse('${ApiEndpoints.products}/$id'));
      final headers = await _getHeaders(withToken: true);
      request.headers.addAll(headers);

      request.fields['name'] = name;
      request.fields['brand'] = brand;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['sizeStock'] = jsonEncode(sizeStock);
      if (imageUrl != null) request.fields['imageUrl'] = imageUrl;

      request.files.add(await http.MultipartFile.fromPath('imageFile', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } else {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.products}/$id'),
        headers: await _getHeaders(withToken: true),
        body: jsonEncode({
          'name': name,
          'brand': brand,
          'description': description,
          'price': price,
          'sizeStock': sizeStock,
          'imageUrl': imageUrl ?? '',
        }),
      );
      return jsonDecode(response.body);
    }
  }

  // DELETE /api/products/:id (Hapus Produk)
  Future<Map<String, dynamic>> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.products}/$id'),
      headers: await _getHeaders(withToken: true),
    );
    return jsonDecode(response.body);
  }
}