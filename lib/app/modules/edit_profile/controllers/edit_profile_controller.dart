import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../admin_home/controllers/admin_home_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile_admin/controllers/profile_admin_controller.dart';

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
      final storedUserId = await StorageService.getUserIdAsync();
      final token = await StorageService.getToken();

      int targetUserId = storedUserId ?? 0;

      if (targetUserId == 0 && token != null && token.isNotEmpty) {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
          final userMap = json.decode(decoded);
          targetUserId = userMap['id'] ?? 0;
        }
      }

      if (targetUserId != 0) {
        userId.value = targetUserId;
        
        // 1. Fetch fresh user details
        final freshRes = await _apiProvider.getUserById(targetUserId);
        if (freshRes['success'] == true && freshRes['data'] != null) {
          final uData = freshRes['data'];
          nameController.text = uData['fullName'] ?? uData['full_name'] ?? '';
          phoneController.text = uData['phoneNumber'] ?? uData['phone_number'] ?? uData['phone'] ?? '';
          currentAvatarUrl.value = uData['imageUrl'] ?? uData['avatar_url'] ?? '';
        }

        // 2. Fetch user address details from /users/locations
        final locations = await _apiProvider.getMyLocations();
        if (locations.isNotEmpty) {
          final primary = locations.firstWhere(
            (loc) => loc['is_primary'] == 1 || loc['is_primary'] == true || loc['isPrimary'] == 1,
            orElse: () => locations.first,
          );
          locationId.value = primary['id'] ?? 0;
          addressController.text = primary['address_text'] ?? primary['addressText'] ?? '';
          addressNotesController.text = primary['address_notes'] ?? primary['addressNotes'] ?? '';
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
      Get.snackbar('Validasi Gagal', 'Nama Lengkap dan Nomor Handphone wajib diisi',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      isLoading.value = true;
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      // 1. Update user info (Name, Phone, Profile Image)
      final userRes = await _apiProvider.updateUser(
        id: userId.value,
        fullName: name,
        phoneNumber: phone,
        imagePath: imagePath.value.isNotEmpty ? imagePath.value : null,
      );

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

      Get.back(); // Close loading dialog

      if (userRes['success'] == true) {
        Get.snackbar(
          'Sukses',
          'Profil Anda berhasil diperbarui!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh states & reload profile Controllers
        if (Get.isRegistered<ProfileController>()) {
          final profileCtrl = Get.find<ProfileController>();
          await profileCtrl.loadUserInfo();
        }
        if (Get.isRegistered<ProfileAdminController>()) {
          final adminProfileCtrl = Get.find<ProfileAdminController>();
          await adminProfileCtrl.loadAdminProfile();
        }
        if (Get.isRegistered<AdminHomeController>()) {
          final adminHomeCtrl = Get.find<AdminHomeController>();
          adminHomeCtrl.selectedBottomIndex.value = 2; // Kembalikan ke tab Profil Admin (Tab 2)
        }
        if (Get.isRegistered<HomeController>()) {
          final homeCtrl = Get.find<HomeController>();
          await homeCtrl.loadDashboardData();
        }

        // Navigasi kembali ke halaman profil
        Get.back();
      } else {
        Get.snackbar('Gagal', userRes['message'] ?? 'Gagal memperbarui profil',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
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
