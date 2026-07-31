import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class ProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final ImagePicker _picker = ImagePicker();

  var userId = 0.obs;
  var userName = 'Pelanggan Localize'.obs;
  var userEmail = 'customer@mail.com'.obs;
  var userPhone = ''.obs;
  var userAvatarUrl = ''.obs;
  var userAddress = 'Belum Menambahkan Alamat'.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    try {
      isLoading.value = true;
      final storedId = await StorageService.getUserIdAsync();
      final token = await StorageService.getToken();

      int targetUserId = storedId ?? 0;

      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
            final userMap = json.decode(decoded);
            if (targetUserId == 0) {
              targetUserId = userMap['id'] ?? 0;
            }
            if (userEmail.value == 'customer@mail.com' || userEmail.value.isEmpty) {
              userEmail.value = userMap['email'] ?? 'customer@mail.com';
            }
            if (userName.value == 'Pelanggan Localize' || userName.value.isEmpty) {
              userName.value = userMap['fullName'] ?? userMap['full_name'] ?? 'Pelanggan Localize';
            }
          }
        } catch (_) {}
      }

      if (targetUserId != 0) {
        userId.value = targetUserId;

        // 1. Fetch fresh user info
        try {
          final res = await _apiProvider.getUserById(targetUserId);
          if (res['success'] == true && res['data'] != null) {
            final uData = res['data'];
            userName.value = uData['fullName'] ?? uData['full_name'] ?? 'Pelanggan Localize';
            userEmail.value = uData['email'] ?? 'customer@mail.com';
            final rawPhone = uData['phoneNumber'] ?? uData['phone_number'] ?? uData['phone'] ?? '';
            userPhone.value = rawPhone.toString();
            userAvatarUrl.value = uData['imageUrl'] ?? uData['avatar_url'] ?? '';
          }
        } catch (_) {}

        // 2. Fetch user primary address
        try {
          final locations = await _apiProvider.getMyLocations();
          if (locations.isNotEmpty) {
            final primary = locations.firstWhere(
              (loc) => loc['is_primary'] == 1 || loc['is_primary'] == true || loc['isPrimary'] == 1,
              orElse: () => locations.first,
            );
            userAddress.value = primary['address_text'] ?? primary['addressText'] ?? 'Belum Menambahkan Alamat';
          }
        } catch (_) {}
      }
    } catch (e) {
      print('Error loading user info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeProfilePhoto() async {
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

      final res = await _apiProvider.updateUser(
        id: userId.value,
        fullName: userName.value,
        phoneNumber: userPhone.value,
        imagePath: image.path,
      );

      Get.back(); // Dismiss loading

      if (res['success'] == true) {
        Get.snackbar('Sukses', 'Foto profil berhasil diperbarui!',
            backgroundColor: Colors.green, colorText: Colors.white);
        loadUserInfo();
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal memperbarui foto profil');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Gagal memproses gambar: $e');
    }
  }

  // Validasi & Konfirmasi Logout Customer
  Future<void> logout() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearSession();
      Get.snackbar(
        'Keluar Akun',
        'Anda telah keluar dari akun.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
