import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isObscure = true.obs;

  void toggleObscure() => isObscure.value = !isObscure.value;

  void validateAndNext() {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Nama lengkap wajib diisi');
      return;
    }

    if (email.isEmpty || !GetUtils.isEmail(email)) {
      Get.snackbar('Validasi Gagal', 'Masukkan format email yang valid');
      return;
    }

    if (password.length < 6) {
      Get.snackbar('Validasi Gagal', 'Password minimal harus 6 karakter');
      return;
    }

    // Navigasi ke Page 2 (Register Validation)
    Get.toNamed(
      Routes.REGISTER_VALIDATION,
      arguments: {
        'fullName': fullName,
        'email': email,
        'password': password,
      },
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}