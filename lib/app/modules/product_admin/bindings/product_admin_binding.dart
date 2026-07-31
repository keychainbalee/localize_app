import 'package:get/get.dart';

import '../controllers/product_admin_controller.dart';

class ProductAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductAdminController>(
      () => ProductAdminController(),
    );
  }
}
