import 'package:get/get.dart';

import '../controllers/register_validation_controller.dart';

class RegisterValidationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RegisterValidationController>(
      () => RegisterValidationController(),
    );
  }
}
