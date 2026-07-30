import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class EditProfileController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final addressNotesController = TextEditingController();

  // States
  var userId = 0.obs;
  var locationId = 0.obs;
  var imagePath = ''.obs;
  var currentAvatarUrl = ''.obs;
  var isLoading = false.obs;
  var isGettingLocation = false.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
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
        
        // 1. Fetch fresh user details
        final freshRes = await _apiProvider.getUserById(idVal);
        if (freshRes['success'] == true && freshRes['data'] != null) {
          final uData = freshRes['data'];
          nameController.text = uData['fullName'] ?? '';
          phoneController.text = uData['phoneNumber'] ?? '';
          currentAvatarUrl.value = uData['imageUrl'] ?? '';
        }

        // 2. Fetch user address details
        final locations = await _apiProvider.getMyLocations();
        if (locations.isNotEmpty) {
          final primary = locations.firstWhere(
            (loc) => loc['is_primary'] == 1 || loc['is_primary'] == true,
            orElse: () => locations.first,
          );
          locationId.value = primary['id'] ?? 0;
          addressController.text = primary['address_text'] ?? '';
          addressNotesController.text = primary['address_notes'] ?? '';
          latitude.value = double.tryParse(primary['latitude']?.toString() ?? '0.0') ?? 0.0;
          longitude.value = double.tryParse(primary['longitude']?.toString() ?? '0.0') ?? 0.0;
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data profil: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        imagePath.value = pickedFile.path;
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memilih gambar: $e');
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      isGettingLocation.value = true;
      final result = await Get.toNamed(Routes.MAP_PICKER);
      if (result != null && result is Map) {
        latitude.value = result['latitude'] ?? 0.0;
        longitude.value = result['longitude'] ?? 0.0;
        addressController.text = result['address'] ?? '';
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuka penunjuk peta: $e');
    } finally {
      isGettingLocation.value = false;
    }
  }

  Future<void> submitUpdate() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final notes = addressNotesController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Nama Lengkap dan Nomor Handphone wajib diisi');
      return;
    }

    try {
      isLoading.value = true;

      // 1. Update user info (Name, Phone, Profile Image)
      final userRes = await _apiProvider.updateUser(
        id: userId.value,
        fullName: name,
        phoneNumber: phone,
        imagePath: imagePath.value.isNotEmpty ? imagePath.value : null,
      );

      if (userRes['success'] != true) {
        Get.snackbar('Gagal', userRes['message'] ?? 'Gagal memperbarui profil');
        return;
      }

      // 2. Update/Save location info
      if (address.isNotEmpty) {
        if (locationId.value != 0) {
          // Update existing location
          await _apiProvider.updateLocation(
            id: locationId.value,
            addressText: address,
            addressNotes: notes,
            latitude: latitude.value,
            longitude: longitude.value,
          );
        } else {
          // Create new location if none existed
          await _apiProvider.addLocation(
            addressText: address,
            addressNotes: notes,
            latitude: latitude.value,
            longitude: longitude.value,
          );
        }
      }

      Get.snackbar('Sukses', 'Profil Anda berhasil diperbarui!',
          backgroundColor: Colors.green, colorText: Colors.white);

      // Refresh states dynamically if controllers are registered
      if (Get.isRegistered<ProfileController>()) {
        final profileCtrl = Get.find<ProfileController>();
        await profileCtrl.loadUserInfo();
      }
      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        await homeCtrl.loadDashboardData();
      }

      Get.back(); // Go back to profile view
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    addressNotesController.dispose();
    super.onClose();
  }
}
