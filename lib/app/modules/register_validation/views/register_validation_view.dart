import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/register_validation_controller.dart';

class RegisterValidationView extends GetView<RegisterValidationController> {
  const RegisterValidationView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFFFB800);
    const Color darkText = Color(0xFF333333);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                  child: GestureDetector(
                    onTap: () => controller.pickImage(),
                    child: Obx(
                      () => Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          image: controller.imagePath.value.isNotEmpty
                              ? DecorationImage(
                                  image: FileImage(File(controller.imagePath.value)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: controller.imagePath.value.isEmpty
                            ? const Icon(
                                Icons.add_a_photo_outlined,
                                size: 36,
                                color: brandYellow,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Column(
                children: [
                  // Hint Upload Foto
                  Obx(
                    () => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        controller.imagePath.value.isEmpty
                            ? 'Tap ikon kamera di atas untuk upload foto profil (opsional)'
                            : 'Foto profil terpilih!',
                        style: TextStyle(
                          fontSize: 12,
                          color: controller.imagePath.value.isEmpty ? Colors.grey[600] : Colors.green,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  // Field HP
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Nomor Handphone',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.phone_outlined,
                        color: Colors.black54,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: brandYellow, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Deteksi Lokasi GPS LBS
                  Obx(
                    () => OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: const BorderSide(color: brandYellow, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      onPressed: controller.isGettingLocation.value
                          ? null
                          : () => controller.getCurrentLocation(),
                      icon: controller.isGettingLocation.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.my_location,
                              color: darkText,
                              size: 20,
                            ),
                      label: Text(
                        controller.locationName.value.isEmpty
                            ? 'Pilih Lokasi GPS Saat Ini'
                            : 'Lokasi: ${controller.locationName.value}',
                        style: const TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Field Alamat Jalan
                  TextField(
                    controller: controller.addressController,
                    decoration: InputDecoration(
                      hintText: 'Nama Jalan / Detail Rumah',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.map_outlined,
                        color: Colors.black54,
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black12),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: brandYellow, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Action Button
                  Obx(
                    () => SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandYellow,
                          foregroundColor: darkText,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : () => controller.submitRegister(),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: darkText,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Selesaikan Pendaftaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
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
}

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
