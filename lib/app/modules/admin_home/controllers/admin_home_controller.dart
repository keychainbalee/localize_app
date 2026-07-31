import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../pesanan_admin/controllers/pesanan_admin_controller.dart';
import '../../profile_admin/controllers/profile_admin_controller.dart';

class AdminHomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var isLoading = true.obs;
  var selectedBottomIndex = 0.obs;

  var productsList = <dynamic>[].obs;
  var adminOrdersList = <dynamic>[].obs;
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminDashboard();
  }

  // Ubah tab navigasi & auto-refresh data API per tab
  void changeTab(int index) {
    selectedBottomIndex.value = index;
    if (index == 0) {
      fetchAdminDashboard();
    } else if (index == 1) {
      if (Get.isRegistered<PesananAdminController>()) {
        Get.find<PesananAdminController>().loadAdminOrders();
      }
    } else if (index == 2) {
      if (Get.isRegistered<ProfileAdminController>()) {
        Get.find<ProfileAdminController>().loadAdminProfile();
      }
    }
  }

  // Mengambil daftar produk toko
  Future<void> fetchAdminDashboard() async {
    try {
      isLoading.value = true;
      final products = await _apiProvider.getProducts();
      productsList.value = products;
    } catch (e) {
      Get.snackbar('Error Admin', 'Gagal memuat katalog produk admin: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  // Filtered product list berdasarkan pencarian
  List<dynamic> get filteredProductsList {
    if (searchQuery.value.trim().isEmpty) {
      return productsList;
    }
    final q = searchQuery.value.toLowerCase();
    return productsList.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final brand = (p['brand'] ?? '').toString().toLowerCase();
      return name.contains(q) || brand.contains(q);
    }).toList();
  }

  // Total stok & terjual
  int get totalStockCount {
    int total = 0;
    for (var p in productsList) {
      total += int.tryParse(p['stock']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  int get totalSoldCount {
    int total = 0;
    for (var p in productsList) {
      total += int.tryParse(p['sold_count']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  // Hapus produk dari katalog toko
  Future<void> deleteProduct(int productId, String productName) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Produk', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "$productName" dari katalog toko?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await _apiProvider.deleteProduct(productId);
      Get.back();

      if (res['success'] == true) {
        Get.snackbar(
          'Sukses',
          res['message'] ?? 'Produk berhasil dihapus',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchAdminDashboard();
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal menghapus produk',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari sistem admin?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearSession();
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}