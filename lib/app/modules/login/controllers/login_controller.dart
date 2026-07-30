import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:localize/app/data/providers/api_provider.dart';
import 'package:localize/app/data/services/storage_service.dart';
import 'package:localize/app/routes/app_pages.dart';

class LoginController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  // Controller untuk Text Field Form
  final emailController = TextEditingController(text: 'budi@mail.com');
  final passwordController = TextEditingController(text: 'password123');

  // Reactive State Variables
  var isLoading = false.obs;
  var isObscure = true.obs;

  // Toggle Tampilkan / Sembunyikan Password
  void toggleObscure() {
    isObscure.value = !isObscure.value;
  }

  // Pemanggilan Endpoint Login
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
        // Simpan JWT Token ke local storage (Data Persistence)
        final String token = response['token'] ?? '';
        await StorageService.saveToken(token);

        Get.snackbar(
          'Berhasil',
          response['message'] ?? 'Selamat datang kembali!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Pindah ke Halaman Home dan hapus tumpukan Route Login
        Get.offAllNamed(Routes.HOME);
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
        'Error',
        'Gagal terhubung ke server: $e',
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