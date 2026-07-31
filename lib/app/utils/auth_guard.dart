import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../data/services/storage_service.dart';
import '../routes/app_pages.dart';

class AuthGuard {
  /// Memeriksa status login pengguna.
  /// Jika sudah login -> mengembalikan true.
  /// Jika belum login -> menampilkan dialog konfirmasi ajakan masuk/daftar dan mengembalikan false.
  static Future<bool> checkLoggedIn({required String actionTitle}) async {
    final token = await StorageService.getToken();
    if (token != null && token.isNotEmpty) {
      return true;
    }

    // Tampilkan Dialog Konfirmasi Login
    await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFFFFB800)),
            SizedBox(width: 8),
            Text('Akses Terbatas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          'Silakan masuk atau buat akun terlebih dahulu untuk $actionTitle.',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Nanti Saja', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFB800),
              foregroundColor: const Color(0xFF2D2D2D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Get.back();
              Get.toNamed(Routes.LOGIN);
            },
            child: const Text('Masuk / Daftar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return false;
  }
}
