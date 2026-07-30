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
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final parts = token.split('.');
      if (parts.length != 3) return;

      final payload = parts[1];
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final userMap = json.decode(decoded);
      
      final idVal = userMap['id'];
      if (idVal != null) {
        userId.value = idVal;

        // 1. Fetch fresh user info
        final res = await _apiProvider.getUserById(idVal);
        if (res['success'] == true && res['data'] != null) {
          final uData = res['data'];
          userName.value = uData['fullName'] ?? 'Pelanggan Localize';
          userEmail.value = uData['email'] ?? 'customer@mail.com';
          userPhone.value = uData['phoneNumber'] ?? '';
          userAvatarUrl.value = uData['imageUrl'] ?? '';
        }

        // 2. Fetch user primary address
        final locations = await _apiProvider.getMyLocations();
        if (locations.isNotEmpty) {
          final primary = locations.firstWhere(
            (loc) => loc['is_primary'] == 1 || loc['is_primary'] == true,
            orElse: () => locations.first,
          );
          userAddress.value = primary['address_text'] ?? 'Belum Menambahkan Alamat';
        }
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

  Future<void> logout() async {
    await StorageService.clearSession();
    Get.snackbar(
      'Keluar Akun',
      'Anda berhasil keluar dari akun.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
    Get.offAllNamed(Routes.LOGIN);
  }
}
