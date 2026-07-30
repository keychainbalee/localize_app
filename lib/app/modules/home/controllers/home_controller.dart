import 'dart:convert';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class HomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var products = [].obs;
  var storeInfo = {}.obs;
  var isLoading = true.obs;

  // User States
  var userName = 'Pelanggan Localize'.obs;
  var userEmail = 'customer@mail.com'.obs;
  var userAvatarUrl = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    loadUserInfo();
  }

  // Memuat katalog produk & info lokasi toko dari API
  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      final productList = await _apiProvider.getProducts();
      final storeData = await _apiProvider.getStoreInfo();

      products.value = productList;
      if (storeData['success'] == true) {
        storeInfo.value = storeData['data'] ?? {};
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data beranda: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserInfo() async {
    try {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final Map<String, dynamic> userMap = json.decode(decoded);
          
          userName.value = userMap['fullName'] ?? 'Pelanggan Localize';
          userEmail.value = userMap['email'] ?? 'customer@mail.com';

          final userId = userMap['id'];
          if (userId != null) {
            final freshUser = await _apiProvider.getUserById(userId);
            if (freshUser['success'] == true && freshUser['data'] != null) {
              final userData = freshUser['data'];
              userName.value = userData['fullName'] ?? userName.value;
              userAvatarUrl.value = userData['imageUrl'] ?? '';
            }
          }
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  Future<void> logout() async {
    await StorageService.clearSession();
    Get.offAllNamed(Routes.LOGIN);
  }
}