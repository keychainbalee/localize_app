import 'package:get/get.dart';
import '../../pesanan_admin/controllers/pesanan_admin_controller.dart';
import '../../product_admin/controllers/product_admin_controller.dart';
import '../../profile_admin/controllers/profile_admin_controller.dart';
import '../controllers/admin_home_controller.dart';

class AdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminHomeController>(
      () => AdminHomeController(),
    );
    Get.lazyPut<ProductAdminController>(
      () => ProductAdminController(),
    );
    Get.lazyPut<PesananAdminController>(
      () => PesananAdminController(),
    );
    Get.lazyPut<ProfileAdminController>(
      () => ProfileAdminController(),
    );
  }
}
