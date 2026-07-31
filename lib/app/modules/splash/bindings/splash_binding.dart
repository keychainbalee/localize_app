import 'package:get/get.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Gunakan Get.put agar SplashController langsung diinstansi & onInit() langsung berjalan!
    Get.put<SplashController>(SplashController());
  }
}
