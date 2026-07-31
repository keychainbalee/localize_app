import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';

class PesananAdminController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var adminOrders = <dynamic>[].obs;
  var isLoadingOrders = false.obs;
  var selectedStatusFilter = 'semua'.obs;

  @override
  void onInit() {
    super.onInit();
    loadAdminOrders();
  }

  Future<void> loadAdminOrders() async {
    try {
      isLoadingOrders.value = true;
      final list = await _apiProvider.getAdminOrders();
      adminOrders.value = list;
    } catch (e) {
      Get.snackbar('Error Pesanan Admin', 'Gagal memuat daftar transaksi: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoadingOrders.value = false;
    }
  }

  List<dynamic> get filteredOrders {
    if (selectedStatusFilter.value == 'semua') {
      return adminOrders;
    }
    return adminOrders.where((order) {
      final status = (order['status'] ?? 'dipesan').toString().toLowerCase();
      return status == selectedStatusFilter.value;
    }).toList();
  }

  // Admin Ubah Status Pesanan
  Future<void> changeOrderStatus(int orderId, String newStatus) async {
    final statusLabels = {
      'dibayar': 'Konfirmasi Pembayaran (DIBAYAR)',
      'dikirim': 'Kirim Pesanan (DIKIRIM)',
      'selesai': 'Tandai Selesai (SELESAI)',
      'batal': 'Batalkan Pesanan (BATAL)',
    };

    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Ubah Status Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Ubah status pesanan ID #$orderId menjadi "${statusLabels[newStatus] ?? newStatus}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == 'batal' ? Colors.red : const Color(0xFFFFB800),
              foregroundColor: newStatus == 'batal' ? Colors.white : Colors.black87,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Ubah Status'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await _apiProvider.updateOrderStatus(orderId, newStatus);
      Get.back();

      if (res['success'] == true) {
        Get.snackbar(
          'Status Diperbarui',
          res['message'] ?? 'Status pesanan berhasil diubah',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        loadAdminOrders();
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal memperbarui status',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  // Tampilkan Dialog Bukti Bayar
  void showPaymentProofDialog(String? proofUrl, int orderId) {
    if (proofUrl == null || proofUrl.isEmpty) {
      Get.snackbar('Bukti Belum Diunggah', 'Pelanggan belum mengunggah foto bukti pembayaran.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bukti Bayar Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  proofUrl,
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('Gagal memuat gambar bukti bayar', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Get.back();
                    changeOrderStatus(orderId, 'dibayar');
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Verifikasi & Setuju (DIBAYAR)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
