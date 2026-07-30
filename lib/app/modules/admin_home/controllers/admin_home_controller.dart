import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../../../data/providers/api_provider.dart';
import '../../../data/services/api_endpoints.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class AdminHomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var isLoading = true.obs;
  var selectedTab = 0.obs;

  var productsList = [].obs;
  var adminOrdersList = [].obs;
  var usersList = [].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminDashboard();
  }

  // Mengambil data terpadu untuk Dashboard Admin
  Future<void> fetchAdminDashboard() async {
    try {
      isLoading.value = true;
      
      final products = await _apiProvider.getProducts();
      productsList.value = products;

      await fetchAdminOrders();
      await fetchUsers();
    } catch (e) {
      Get.snackbar('Error Admin', 'Gagal memuat statistik dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // GET /api/orders/admin
  Future<void> fetchAdminOrders() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.adminOrders));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        adminOrdersList.value = data['data'] ?? [];
      }
    } catch (_) {}
  }

  // GET /api/auth/users
  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.users));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        usersList.value = data['data'] ?? [];
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    Get.offAllNamed(Routes.LOGIN);
  }
}