import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/register_controller.dart';
import '../../../routes/app_pages.dart';

class RegisterView extends GetView<RegisterController> {
  static const Color brandYellow = Color(0xFFFFB800);
  static const Color darkText = Color(0xFF333333);
  static const Color brandGreen = Color(0xFF4CAF50);
  static const Color brandRed = Color(0xFFE53935);
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Lengkung dengan Nama Toko LOCALIZE & Tombol Kembali
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 240,
                    width: double.infinity,
                    color: brandYellow,
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Text(
                                'LOCALIZE',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                  color: darkText,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Daftar dan cari sepatumu sekarang',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -35,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, size: 44, color: brandYellow),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Form Inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Column(
                children: [
                  TextField(
                    controller: controller.fullNameController,
                    decoration: InputDecoration(
                      hintText: 'Nama Lengkap',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.black54),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: brandYellow, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.black54),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: brandYellow, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Obx(() => TextField(
                        controller: controller.passwordController,
                        obscureText: controller.isObscure.value,
                        onChanged: (_) => controller.password.value = controller.passwordController.text,
                        decoration: InputDecoration(
                          hintText: 'Password (min. 8 karakter)',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.black54),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isObscure.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: controller.toggleObscure,
                          ),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: brandYellow, width: 2)),
                        ),
                      )),
                  const SizedBox(height: 10),

                  // Password Requirement Checklist
                  Obx(() {
                    final pwd = controller.password.value;
                    final hasMin = pwd.length >= 8;
                    final hasUpper = pwd.contains(RegExp(r'[A-Z]'));
                    final hasLower = pwd.contains(RegExp(r'[a-z]'));
                    final hasDigit = pwd.contains(RegExp(r'[0-9]'));

                    if (pwd.isEmpty) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ketentuan password:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          _buildRequirement('Minimal 8 karakter', hasMin),
                          _buildRequirement('Mengandung huruf besar (A-Z)', hasUpper),
                          _buildRequirement('Mengandung huruf kecil (a-z)', hasLower),
                          _buildRequirement('Mengandung angka (0-9)', hasDigit),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      GestureDetector(
                        onTap: () => Get.offNamed(Routes.LOGIN),
                        child: const Text('Masuk di sini', style: TextStyle(color: brandYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandYellow,
                        foregroundColor: darkText,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: () => controller.validateAndNext(),
                      child: const Text('Lanjutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 15,
            color: isMet ? brandGreen : brandRed,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? brandGreen : brandRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}