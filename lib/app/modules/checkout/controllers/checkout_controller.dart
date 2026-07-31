import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/auth_guard.dart';
import '../../home/controllers/home_controller.dart';

class CheckoutController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var isFromCart = false.obs;
  var items = [].obs;
  var selectedSize = ''.obs;
  var maxSizeStock = 999.obs; // Stok maksimum untuk ukuran yang dipilih

  // LBS Store & GPS states
  var storeInfo = {}.obs;
  var addressController = TextEditingController();
  var addressNotesController = TextEditingController();
  var isGettingLocation = false.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var locationName = ''.obs;
  var distance = 0.0.obs;
  var shippingFee = 0.0.obs;
  var isLoading = false.obs;

  double get totalItemsPrice {
    double total = 0;
    for (var item in items) {
      final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
      final qty = item['quantity'] ?? 1;
      total += price * qty;
    }
    return total;
  }

  double get grandTotal => totalItemsPrice + shippingFee.value;

  @override
  void onInit() {
    super.onInit();
    loadStoreSettings();
    parseArguments();
  }

  void parseArguments() {
    final args = Get.arguments;
    if (args is Map && args['isFromCart'] == true) {
      isFromCart.value = true;
      items.value = args['items'] ?? [];
    } else if (args != null) {
      isFromCart.value = false;
      final product = args;
      
      final Map<dynamic, dynamic> sizeStock = (product['size_stock'] is Map)
          ? product['size_stock']
          : {};

      final List<String> availableSizes = [];
      sizeStock.forEach((key, value) {
        final stock = int.tryParse(value.toString()) ?? 0;
        if (stock > 0) {
          availableSizes.add(key.toString());
        }
      });

      if (availableSizes.isNotEmpty) {
        selectedSize.value = availableSizes.first;
        // Set stok max sesuai ukuran pertama yang tersedia
        maxSizeStock.value = int.tryParse(sizeStock[availableSizes.first]?.toString() ?? '1') ?? 1;
      }

      items.value = [
        {
          'id': product['id'],
          'name': product['name'],
          'price': product['price'],
          'image_url': product['image_url'],
          'quantity': 1,
          'size': selectedSize.value.isNotEmpty ? selectedSize.value : '39',
          'size_stock': sizeStock, // simpan size_stock di item untuk referensi
        }
      ];
    }
  }

  void updateDirectBuySize(String size) {
    selectedSize.value = size;
    if (items.isNotEmpty && !isFromCart.value) {
      items[0]['size'] = size;

      // Update maxSizeStock dari size_stock produk
      final args = Get.arguments;
      if (args != null && args['size_stock'] is Map) {
        final sizeStock = args['size_stock'] as Map;
        maxSizeStock.value = int.tryParse(sizeStock[size]?.toString() ?? '1') ?? 1;
      }

      // Clamp kuantitas agar tidak melebihi stok ukuran baru
      final currentQty = items[0]['quantity'] ?? 1;
      if (currentQty > maxSizeStock.value) {
        items[0]['quantity'] = maxSizeStock.value;
      }

      items.refresh();
    }
  }

  void updateDirectBuyQty(int qty) {
    if (qty <= 0) return;
    if (qty > maxSizeStock.value) {
      Get.snackbar(
        'Stok Tidak Cukup',
        'Stok ukuran ini hanya tersisa ${maxSizeStock.value}',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    if (items.isNotEmpty && !isFromCart.value) {
      items[0]['quantity'] = qty;
      items.refresh();
    }
  }

  Future<void> loadStoreSettings() async {
    try {
      final res = await _apiProvider.getStoreInfo();
      if (res['success'] == true) {
        storeInfo.value = res['data'] ?? {};
      }
      // Load user's primary address after store info is loaded
      await loadUserPrimaryAddress();
    } catch (e) {
      print('Error loading store info: $e');
    }
  }

  Future<void> loadUserPrimaryAddress() async {
    try {
      final locations = await _apiProvider.getMyLocations();
      if (locations.isNotEmpty) {
        // Cari lokasi primer atau ambil lokasi pertama
        final primary = locations.firstWhere(
          (loc) => loc['is_primary'] == 1 || loc['is_primary'] == true,
          orElse: () => locations.first,
        );

        latitude.value = double.tryParse(primary['latitude']?.toString() ?? '0.0') ?? 0.0;
        longitude.value = double.tryParse(primary['longitude']?.toString() ?? '0.0') ?? 0.0;
        locationName.value = primary['address_text'] ?? '';
        addressController.text = locationName.value;
        addressNotesController.text = primary['address_notes'] ?? '';

        calculateShippingFee();
      }
    } catch (e) {
      print('Error loading user address: $e');
    }
  }

  void calculateShippingFee() {
    final double lat = latitude.value;
    final double lng = longitude.value;
    final String addr = locationName.value.isEmpty ? addressController.text.toLowerCase() : locationName.value.toLowerCase();
    
    bool isJawa = false;

    // Check by coordinates first
    if (lat >= -9.0 && lat <= -5.5 && lng >= 105.0 && lng <= 115.0) {
      isJawa = true;
    }

    // Check by address keywords
    if (addr.contains('jawa') || 
        addr.contains('jakarta') || 
        addr.contains('banten') || 
        addr.contains('yogyakarta') || 
        addr.contains('diy') || 
        addr.contains('bandung') || 
        addr.contains('semarang') || 
        addr.contains('surabaya') || 
        addr.contains('solo') || 
        addr.contains('malang') ||
        addr.contains('bogor') ||
        addr.contains('tangerang') ||
        addr.contains('bekasi') ||
        addr.contains('depok')) {
      isJawa = true;
    }

    shippingFee.value = isJawa ? 20000.0 : 50000.0;

    final double storeLat = double.tryParse(storeInfo['latitude']?.toString() ?? '0') ?? -6.1953;
    final double storeLng = double.tryParse(storeInfo['longitude']?.toString() ?? '0') ?? 106.8203;
    if (lat != 0.0 && lng != 0.0) {
      final double distInMeters = Geolocator.distanceBetween(lat, lng, storeLat, storeLng);
      distance.value = distInMeters / 1000.0;
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      isGettingLocation.value = true;
      final result = await Get.toNamed(Routes.MAP_PICKER);
      if (result != null && result is Map) {
        latitude.value = result['latitude'] ?? 0.0;
        longitude.value = result['longitude'] ?? 0.0;
        locationName.value = result['address'] ?? '';
        addressController.text = locationName.value;
      }
      calculateShippingFee();
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuka penunjuk peta: $e');
    } finally {
      isGettingLocation.value = false;
    }
  }

  Future<void> submitOrder() async {
    final loggedIn = await AuthGuard.checkLoggedIn(actionTitle: 'membuat pesanan');
    if (!loggedIn) return;

    final address = addressController.text.trim();
    if (address.isEmpty) {
      Get.snackbar('Peringatan', 'Alamat pengiriman wajib diisi');
      return;
    }

    if (latitude.value == 0.0 || longitude.value == 0.0) {
      Get.snackbar('Peringatan', 'Dapatkan lokasi GPS Anda terlebih dahulu');
      return;
    }

    try {
      isLoading.value = true;
      
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        Get.toNamed(Routes.LOGIN);
        return;
      }

      final parts = token.split('.');
      final payload = parts[1];
      final decoded = utf8.decode(base64Url.decode(base64Url.normalize(payload)));
      final userMap = json.decode(decoded);
      final userId = userMap['id'] ?? 1;

      final res = await _apiProvider.createOrder(
        userId: userId,
        shippingAddress: address,
        addressNotes: addressNotesController.text.trim(),
        latitude: latitude.value,
        longitude: longitude.value,
        items: items.map((item) => {
          'productId': item['id'],
          'size': item['size'],
          'quantity': item['quantity'],
          'price': item['price'],
        }).toList(),
      );

      if (res['success'] == true) {
        if (isFromCart.value) {
          await _apiProvider.clearMyCart();
        }

        Get.snackbar('Sukses', 'Pesanan berhasil dibuat! Silakan unggah bukti transfer.',
            backgroundColor: Colors.green, colorText: Colors.white);

        final homeCtrl = Get.find<HomeController>();
        homeCtrl.changeTab(1);
        Get.offAllNamed(Routes.HOME);
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal memproses pesanan',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addToCart() async {
    if (isFromCart.value || items.isEmpty) return;
    
    try {
      isLoading.value = true;
      final directItem = items[0];
      final res = await _apiProvider.addToCart(
        productId: directItem['id'],
        size: directItem['size'],
        quantity: directItem['quantity'],
      );

      if (res['success'] == true) {
        await Get.defaultDialog(
          title: 'Sukses',
          middleText: 'anda telah memasukan ke keranjang',
          textConfirm: 'OK',
          confirmTextColor: Colors.white,
          buttonColor: const Color(0xFFFFB800),
          onConfirm: () {
            Get.back(); // Close dialog
          },
        );
        Get.back(); // Go back to catalogue
      } else {
        Get.snackbar('Gagal', res['message'] ?? 'Gagal menambahkan ke keranjang',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('Error', 'Terjadi kesalahan: $e',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    addressController.dispose();
    addressNotesController.dispose();
    super.onClose();
  }
}
