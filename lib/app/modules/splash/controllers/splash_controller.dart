import 'package:get/get.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _checkSessionAndNavigate();
  }

  Future<void> _checkSessionAndNavigate() async {
    try {
      // Jeda minimum 800ms agar animasi splash terlihat
      await Future.delayed(const Duration(milliseconds: 800));

      // Ambil token & role dengan timeout agar tidak pernah menggantung
      final token = await StorageService.getToken().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      final role = await StorageService.getRole().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );

      if (token != null && token.isNotEmpty) {
        if (role == 'admin') {
          Get.offAllNamed(Routes.ADMIN_HOME);
          return;
        }
      }
    } catch (_) {
      // Abaikan error & lanjut ke Halaman Utama
    }

    // Default Fallback: Selalu masuk ke Halaman Utama Customer (Home)
    Get.offAllNamed(Routes.HOME);
  }
}
