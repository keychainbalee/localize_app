import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';

class PesananController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final ImagePicker _picker = ImagePicker();

  var myOrders = [].obs;
  var isLoadingOrders = false.obs;
  var selectedOrderStatusFilter = 'dipesan'.obs;

  @override
  void onInit() {
    super.onInit();
    loadMyOrders();
  }

  Future<void> loadMyOrders() async {
    try {
      isLoadingOrders.value = true;
      final list = await _apiProvider.getMyOrders();
      myOrders.value = list;
    } catch (e) {
      print('Error loading orders: $e');
    } finally {
      isLoadingOrders.value = false;
    }
  }

  Future<void> uploadProof(int orderId) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final res = await _apiProvider.uploadPaymentProof(
        orderId: orderId,
        imagePath: image.path,
      );

      Get.back(); // Dismiss loading

      if (res['success'] == true) {
        Get.snackbar(
          'Sukses',
          res['message'] ?? 'Bukti pembayaran berhasil diunggah!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        loadMyOrders();
      } else {
        Get.snackbar(
          'Gagal',
          res['message'] ?? 'Gagal mengunggah bukti pembayaran',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Gagal memproses unggahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> cancelOrder(dynamic orderId) async {
    // Tampilkan konfirmasi dulu
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini?\nStok akan dikembalikan secara otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Tidak', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final id = int.tryParse(orderId.toString()) ?? 0;
      final res = await _apiProvider.cancelOrder(id);

      Get.back(); // tutup loading

      if (res['success'] == true) {
        Get.snackbar(
          'Pesanan Dibatalkan',
          'Pesanan berhasil dibatalkan. Stok telah dikembalikan.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: const Icon(Icons.cancel_outlined, color: Colors.white),
        );
        loadMyOrders();
      } else {
        Get.snackbar(
          'Gagal',
          res['message'] ?? 'Gagal membatalkan pesanan',
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}
