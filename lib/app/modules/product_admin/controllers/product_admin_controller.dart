import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/api_provider.dart';
import '../../../routes/app_pages.dart';
import '../../admin_home/controllers/admin_home_controller.dart';

class ProductAdminController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();
  final ImagePicker _picker = ImagePicker();

  // Controllers untuk TextFields
  final nameController = TextEditingController();
  final brandController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final imageUrlController = TextEditingController();

  // Stock controller per ukuran (38 - 45)
  final Map<String, TextEditingController> sizeStockControllers = {
    '38': TextEditingController(text: '0'),
    '39': TextEditingController(text: '0'),
    '40': TextEditingController(text: '0'),
    '41': TextEditingController(text: '0'),
    '42': TextEditingController(text: '0'),
    '43': TextEditingController(text: '0'),
    '44': TextEditingController(text: '0'),
  };

  var isEditMode = false.obs;
  var productId = 0.obs;
  var selectedImagePath = ''.obs;
  var isSaving = false.obs;
  var currentSoldCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      isEditMode.value = true;
      final p = Map<String, dynamic>.from(args);
      productId.value = int.tryParse(p['id']?.toString() ?? '0') ?? 0;
      nameController.text = p['name']?.toString() ?? '';
      brandController.text = p['brand']?.toString() ?? '';
      descriptionController.text = p['description']?.toString() ?? '';
      priceController.text = p['price']?.toString() ?? '';
      imageUrlController.text = p['image_url']?.toString() ?? '';
      currentSoldCount.value = int.tryParse(p['sold_count']?.toString() ?? '0') ?? 0;

      // Fill size_stock
      final Map<dynamic, dynamic> sizeStockMap = p['size_stock'] is Map ? p['size_stock'] : {};
      sizeStockMap.forEach((size, qty) {
        if (sizeStockControllers.containsKey(size.toString())) {
          sizeStockControllers[size.toString()]!.text = qty.toString();
        } else {
          sizeStockControllers[size.toString()] = TextEditingController(text: qty.toString());
        }
      });
    } else {
      isEditMode.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    brandController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imageUrlController.dispose();
    sizeStockControllers.forEach((_, c) => c.dispose());
    super.onClose();
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (image != null) {
        selectedImagePath.value = image.path;
      }
    } catch (e) {
      Get.snackbar('Error Gambar', 'Gagal memilih gambar: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  int get calculatedTotalStock {
    int total = 0;
    sizeStockControllers.forEach((_, controller) {
      total += int.tryParse(controller.text) ?? 0;
    });
    return total;
  }

  Future<void> saveProduct() async {
    final name = nameController.text.trim();
    final brand = brandController.text.trim();
    final description = descriptionController.text.trim();
    final priceStr = priceController.text.trim();
    final price = double.tryParse(priceStr) ?? 0;

    if (name.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Nama produk tidak boleh kosong',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    if (price <= 0) {
      Get.snackbar('Validasi Gagal', 'Harga produk harus lebih dari 0',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    final Map<String, dynamic> sizeStockObj = {};
    sizeStockControllers.forEach((size, c) {
      final qty = int.tryParse(c.text.trim()) ?? 0;
      if (qty > 0) {
        sizeStockObj[size] = qty;
      }
    });

    if (sizeStockObj.isEmpty) {
      Get.snackbar('Validasi Gagal', 'Harap isi minimal 1 stok ukuran sepatu',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      isSaving.value = true;
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      Map<String, dynamic> res;
      if (isEditMode.value) {
        res = await _apiProvider.updateProduct(
          id: productId.value,
          name: name,
          brand: brand.isNotEmpty ? brand : 'Lokal',
          description: description,
          price: price,
          sizeStock: sizeStockObj,
          imageUrl: imageUrlController.text.trim(),
          imagePath: selectedImagePath.value.isNotEmpty ? selectedImagePath.value : null,
        );
      } else {
        res = await _apiProvider.createProduct(
          name: name,
          brand: brand.isNotEmpty ? brand : 'Lokal',
          description: description,
          price: price,
          sizeStock: sizeStockObj,
          imageUrl: imageUrlController.text.trim(),
          imagePath: selectedImagePath.value.isNotEmpty ? selectedImagePath.value : null,
        );
      }

      Get.back(); // Dismiss loading

      if (res['success'] == true) {
        Get.snackbar(
          'Sukses',
          res['message'] ?? (isEditMode.value ? 'Produk berhasil diperbarui!' : 'Produk berhasil ditambahkan!'),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Refresh admin home dashboard & arahkan kembali ke tab Produk Toko (Tab 0)
        if (Get.isRegistered<AdminHomeController>()) {
          final adminHomeCtrl = Get.find<AdminHomeController>();
          adminHomeCtrl.selectedBottomIndex.value = 0;
          adminHomeCtrl.fetchAdminDashboard();
        }

        // Navigasi kembali ke Halaman Produk Toko (ADMIN_HOME)
        Get.offAllNamed(Routes.ADMIN_HOME);
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal menyimpan produk',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Error', 'Terjadi kesalahan saat menyimpan produk: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isSaving.value = false;
    }
  }
}
