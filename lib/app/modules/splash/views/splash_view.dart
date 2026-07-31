import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<SplashController>();
    return Scaffold(
      backgroundColor: brandYellow,
      body: Stack(
        children: [
          // Background Gradient Ornaments (White translucent shapes)
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(40),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(30),
              ),
            ),
          ),

          // Content Logo & Branding
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Image Logo Transparan (Telah mencakup tulisan LOCALIZE)
                Image.asset(
                  'assets/images/logo/localize logo transparent.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: darkText,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      size: 64,
                      color: brandYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline Berwarna Putih
                const Text(
                  'Sepatu Lokal Pilihan Indonesia',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),

                // Loading Indicator Berwarna Putih
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Footer Version Info Berwarna Putih
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v1.0.0 · Powered by Localize App',
                style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
