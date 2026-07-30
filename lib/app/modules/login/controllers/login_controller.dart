import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  // Text Editing Controller untuk Form Login
  final emailController = TextEditingController(text: 'budi@mail.com');
  final passwordController = TextEditingController(text: 'password123');

  // Reactive State Variables
  var isLoading = false.obs;
  var isObscure = true.obs;

  // Toggle Tampilkan / Sembunyikan Password
  void toggleObscure() => isObscure.value = !isObscure.value;

  // Pindah ke Halaman Registrasi
  void goToRegister() {
    Get.toNamed(Routes.REGISTER);
  }

  // Fungsi Eksekusi Login
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Email dan password wajib diisi!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFB800),
        colorText: Colors.black87,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await _apiProvider.login(email, password);

      if (response['success'] == true) {
        final String token = response['token'] ?? '';
        final String role = response['user']?['role'] ?? 'customer';

        // Simpan JWT Token & Role ke Storage Lokal (Persistensi Data)
        await StorageService.saveToken(token);
        await StorageService.saveRole(role);

        Get.snackbar(
          'Berhasil Login',
          'Selamat datang! Login sebagai ${role.toUpperCase()}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Routing Kondisional Berdasarkan Role User
        if (role == 'admin') {
          Get.offAllNamed(Routes.ADMIN_HOME);
        } else {
          Get.offAllNamed(Routes.HOME);
        }
      } else {
        Get.snackbar(
          'Gagal Login',
          response['message'] ?? 'Email atau password salah',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error Server',
        'Gagal terhubung ke API: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}