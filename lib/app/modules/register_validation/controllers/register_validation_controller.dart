import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class RegisterValidationController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  // Data Passing dari Page 1
  late String fullName;
  late String email;
  late String password;

  // Form Controller
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // GPS LBS States
  var isGettingLocation = false.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var locationName = ''.obs; // Menyimpan ringkasan nama jalan/daerah

  // Image State
  var imagePath = ''.obs;
  final ImagePicker _picker = ImagePicker();

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

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final Map<String, dynamic> args = Get.arguments ?? {};
    fullName = args['fullName'] ?? '';
    email = args['email'] ?? '';
    password = args['password'] ?? '';
  }

  // Deteksi GPS LBS + Translasi Nama Jalan (Reverse Geocoding)
  Future<void> getCurrentLocation() async {
    try {
      isGettingLocation.value = true;
      final result = await Get.toNamed(Routes.MAP_PICKER);
      if (result != null && result is Map) {
        latitude.value = result['latitude'] ?? 0.0;
        longitude.value = result['longitude'] ?? 0.0;
        locationName.value = result['address'] ?? '';
        addressController.text = locationName.value;

        Get.snackbar(
          'Lokasi Terpilih',
          'Alamat terpilih: ${addressController.text}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuka penunjuk peta: $e');
    } finally {
      isGettingLocation.value = false;
    }
  }

  // Submit Registrasi Lengkap
  Future<void> submitRegister() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Nomor handphone wajib diisi');
      return;
    }

    if (latitude.value == 0.0 || longitude.value == 0.0) {
      Get.snackbar('Validasi Gagal', 'Tekan tombol lokasi GPS Anda terlebih dahulu');
      return;
    }

    try {
      isLoading.value = true;

      final response = await _apiProvider.register(
        fullName: fullName,
        email: email,
        phoneNumber: phone,
        password: password,
        role: 'customer',
        imagePath: imagePath.value.isNotEmpty ? imagePath.value : null,
        addressText: addressController.text.isNotEmpty ? addressController.text : null,
        latitude: latitude.value != 0.0 ? latitude.value : null,
        longitude: longitude.value != 0.0 ? longitude.value : null,
      );

      if (response['success'] == true) {
        final String token = response['token'] ?? '';
        if (token.isNotEmpty) {
          await StorageService.saveToken(token);
          await StorageService.saveRole('customer');
        }

        Get.snackbar(
          'Registrasi Berhasil',
          response['message'] ?? 'Selamat datang di Localize!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed(Routes.HOME);
      } else {
        Get.snackbar('Gagal Registrasi', response['message'] ?? 'Terjadi kesalahan pada server');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses pendaftaran: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    addressController.dispose();
    super.onClose();
  }
}