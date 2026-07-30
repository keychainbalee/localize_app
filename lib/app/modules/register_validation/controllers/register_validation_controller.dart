import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // Import Reverse Geocoding
import 'package:geolocator/geolocator.dart';
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('GPS Nonaktif', 'Aktifkan layanan GPS pada perangkat Anda');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Izin Ditolak', 'Aplikasi memerlukan izin akses lokasi GPS');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude.value = position.latitude;
      longitude.value = position.longitude;

      // =======================================================================
      // TRANSLASI KOORDINAT (LAT, LNG) -> NAMA JALAN & LOKASI
      // =======================================================================
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          String street = place.street ?? '';
          String subLocality = place.subLocality ?? ''; // Kelurahan / Desa
          String locality = place.locality ?? '';       // Kecamatan / Kota
          String city = place.subAdministrativeArea ?? ''; // Kota / Kabupaten

          // Susun format alamat yang rapi
          List<String> addressParts = [
            if (street.isNotEmpty) street,
            if (subLocality.isNotEmpty) subLocality,
            if (locality.isNotEmpty) locality,
            if (city.isNotEmpty && city != locality) city,
          ];

          String formattedAddress = addressParts.join(', ');

          locationName.value = formattedAddress.isNotEmpty
              ? formattedAddress
              : 'Jl. Terdeteksi (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';

          // Otomatis isi kolom Textfield Alamat
          addressController.text = locationName.value;
        }
      } catch (geoError) {
        // Fallback jika layanan geocoding tidak merespons (misal internet offline)
        locationName.value =
            'Terkunci: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        addressController.text =
            'Koordinat Terkunci (${position.latitude}, ${position.longitude})';
      }

      Get.snackbar(
        'GPS & Lokasi Berhasil',
        'Alamat terdeteksi: ${addressController.text}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error GPS', 'Gagal membaca koordinat lokasi: $e');
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