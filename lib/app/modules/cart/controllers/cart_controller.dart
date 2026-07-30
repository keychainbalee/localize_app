import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../routes/app_pages.dart';

class CartController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var cartItems = [].obs;
  var isLoading = false.obs;

  double get totalPrice {
    double total = 0;
    for (var item in cartItems) {
      final price = double.tryParse(item['product_price']?.toString() ?? '0') ?? 0.0;
      final qty = item['quantity'] ?? 1;
      total += price * qty;
    }
    return total;
  }

  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  Future<void> loadCart() async {
    try {
      isLoading.value = true;
      final list = await _apiProvider.getMyCart();
      cartItems.value = list;
    } catch (e) {
      print('Error loading cart: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateQty(int id, int newQty) async {
    if (newQty <= 0) return;
    try {
      final res = await _apiProvider.updateCartItem(id: id, quantity: newQty);
      if (res['success'] == true) {
        loadCart();
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal mengubah jumlah');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengubah jumlah: $e');
    }
  }

  Future<void> removeItem(int id) async {
    try {
      final res = await _apiProvider.removeCartItem(id);
      if (res['success'] == true) {
        loadCart();
        Get.snackbar('Sukses', 'Item dihapus dari keranjang',
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal menghapus item');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus item: $e');
    }
  }

  void proceedToCheckout() {
    if (cartItems.isEmpty) {
      Get.snackbar('Peringatan', 'Keranjang Anda kosong');
      return;
    }
    
    Get.toNamed(Routes.CHECKOUT, arguments: {
      'isFromCart': true,
      'items': cartItems.map((item) => {
        'id': item['product_id'],
        'name': item['product_name'],
        'price': item['product_price'],
        'image_url': item['product_image'],
        'quantity': item['quantity'],
        'size': item['size'],
      }).toList(),
    });
  }
}
