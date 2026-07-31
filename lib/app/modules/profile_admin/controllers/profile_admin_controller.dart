import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class ProfileAdminController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final ImagePicker _picker = ImagePicker();

  var isLoading = false.obs;
  var userId = 0.obs;
  var userName = ''.obs;
  var userEmail = ''.obs;
  var userPhone = ''.obs;
  var userAddress = ''.obs;
  var userAvatarUrl = ''.obs;
  var userRole = 'admin'.obs;
  var adminLocations = <dynamic>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAdminProfile();
  }

  Future<void> loadAdminProfile() async {
    try {
      isLoading.value = true;
      final storedId = await StorageService.getUserIdAsync();
      final token = await StorageService.getToken();

      int targetId = storedId ?? 0;

      // Dekode JWT Token secara otomatis jika storedId belum tersimpan
      if (token != null && token.isNotEmpty) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
            final userMap = json.decode(decoded);

            if (targetId == 0) {
              targetId = userMap['id'] ?? 0;
            }
            if (userName.value.isEmpty) {
              userName.value = userMap['fullName'] ?? userMap['full_name'] ?? userMap['name'] ?? '';
            }
            if (userEmail.value.isEmpty) {
              userEmail.value = userMap['email'] ?? '';
            }
            if (userPhone.value.isEmpty || userPhone.value == '-') {
              final phoneFromToken = userMap['phoneNumber'] ?? userMap['phone_number'] ?? userMap['phone'] ?? '';
              if (phoneFromToken.toString().trim().isNotEmpty) {
                userPhone.value = phoneFromToken.toString();
              }
            }
          }
        } catch (_) {}
      }

      if (targetId != 0) {
        userId.value = targetId;
        try {
          final userData = await _apiProvider.getUserById(targetId);
          if (userData['success'] == true && userData['data'] != null) {
            final data = userData['data'];
            final nameStr = data['fullName'] ?? data['full_name'] ?? data['name'] ?? '';
            if (nameStr.toString().trim().isNotEmpty) {
              userName.value = nameStr.toString();
            }

            final emailStr = data['email'] ?? '';
            if (emailStr.toString().trim().isNotEmpty) {
              userEmail.value = emailStr.toString();
            }

            final phoneStr = data['phoneNumber'] ?? data['phone_number'] ?? data['phone'] ?? '';
            if (phoneStr.toString().trim().isNotEmpty) {
              userPhone.value = phoneStr.toString();
            }

            userAvatarUrl.value = data['imageUrl'] ?? data['avatar_url'] ?? data['avatarUrl'] ?? '';
            userRole.value = data['role'] ?? 'admin';
          }
        } catch (_) {}
      }

      // Ambil lokasi terdaftar admin dari endpoint /users/locations
      try {
        final locs = await _apiProvider.getMyLocations();
        adminLocations.value = locs;

        if (locs.isNotEmpty) {
          final primaryLoc = locs.firstWhere(
            (l) => l['is_primary'] == 1 || l['isPrimary'] == 1,
            orElse: () => locs[0],
          );
          final text = primaryLoc['address_text'] ?? primaryLoc['addressText'] ?? '';
          final notes = primaryLoc['address_notes'] ?? primaryLoc['addressNotes'] ?? '';
          if (text.isNotEmpty) {
            userAddress.value = notes.isNotEmpty ? '$text ($notes)' : text;
          }
        } else {
          try {
            final storeInfo = await _apiProvider.getStoreInfo();
            if (storeInfo['success'] == true && storeInfo['data'] != null) {
              userAddress.value = storeInfo['data']['address'] ?? 'Lokasi Toko Pusat';
            }
          } catch (_) {}
        }
      } catch (_) {}

      // Fallback UI aman jika tetap belum terisi
      if (userName.value.isEmpty) {
        userName.value = 'Admin Store';
      }
      if (userPhone.value.isEmpty || userPhone.value == '-') {
        userPhone.value = '081234567890';
      }
      if (userAddress.value.isEmpty) {
        userAddress.value = 'Lokasi Toko Utama belum diset';
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat profil admin: $e');
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

      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final res = await _apiProvider.updateUser(id: userId.value, imagePath: image.path);
      Get.back();

      if (res['success'] == true) {
        Get.snackbar('Sukses', 'Foto profil admin berhasil diubah!',
            backgroundColor: Colors.green, colorText: Colors.white);
        loadAdminProfile();
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal mengubah foto profil',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Gagal memproses gambar: $e',
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
