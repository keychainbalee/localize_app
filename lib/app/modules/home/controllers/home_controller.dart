import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/auth_guard.dart';

class HomeController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  var selectedTabIndex = 0.obs;

  var isLoading = true.obs;
  var storeInfo = {}.obs;

  // User location states
  var userAddress = 'Loading address...'.obs;
  var latitude = 0.0.obs;
  var longitude = 0.0.obs;
  var distance = 0.0.obs;
  var shippingFee = 0.0.obs;

  // Catalog state
  var latestProducts = [].obs;
  var bestSellerProducts = [].obs;
  var allProducts = [].obs;

  // Banner slider states
  var activeSlideIndex = 0.obs;
  var bannerImages = [
    'assets/images/baner/baner1.png',
    'assets/images/baner/baner2.png',
    'assets/images/baner/baner3.png',
  ].obs;

  late PageController pageController;
  Timer? _bannerTimer;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController();
    loadDashboardData();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (bannerImages.isEmpty) return;
      int next = activeSlideIndex.value + 1;
      if (next >= bannerImages.length) {
        next = 0;
      }
      activeSlideIndex.value = next;
      if (pageController.hasClients) {
        pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void onClose() {
    _bannerTimer?.cancel();
    pageController.dispose();
    super.onClose();
  }

  // Pindah tab dengan periksa AuthGuard untuk Pesanan (tab 1) & Profil (tab 2)
  Future<void> changeTab(int index) async {
    if (index == 1) {
      final loggedIn = await AuthGuard.checkLoggedIn(actionTitle: 'melihat daftar pesanan Anda');
      if (!loggedIn) return;
    } else if (index == 2) {
      final loggedIn = await AuthGuard.checkLoggedIn(actionTitle: 'melihat profil akun Anda');
      if (!loggedIn) return;
    }
    selectedTabIndex.value = index;
  }

  // Buka Keranjang Belanja dengan AuthGuard
  Future<void> openCart() async {
    final loggedIn = await AuthGuard.checkLoggedIn(actionTitle: 'melihat keranjang belanja');
    if (!loggedIn) return;
    Get.toNamed(Routes.CART);
  }

  Future<void> loadDashboardData() async {
    try {
      isLoading.value = true;
      
      // Load store settings
      final storeRes = await _apiProvider.getStoreInfo();
      if (storeRes['success'] == true) {
        storeInfo.value = storeRes['data'] ?? {};
      }

      // Load user registered address (opsional jika guest)
      await loadUserAddress();

      // Load product catalog (bisa diakses siapa saja termasuk guest!)
      final productsRes = await _apiProvider.getProducts();
      final List<dynamic> rawList = productsRes;
      allProducts.value = rawList;

      // Terbaru: order by ID descending
      final sortedLatest = List.from(rawList);
      sortedLatest.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
        return idB.compareTo(idA);
      });
      latestProducts.value = sortedLatest.take(5).toList();

      // Terlaris: order by soldCount descending
      final sortedBest = List.from(rawList);
      sortedBest.sort((a, b) {
        final soldA = int.tryParse(a['sold_count']?.toString() ?? '0') ?? 0;
        final soldB = int.tryParse(b['sold_count']?.toString() ?? '0') ?? 0;
        return soldB.compareTo(soldA);
      });
      bestSellerProducts.value = sortedBest.take(5).toList();
    } catch (e) {
      print('Error loading beranda data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadUserAddress() async {
    try {
      final locations = await _apiProvider.getMyLocations();
      if (locations.isNotEmpty) {
        final primary = locations.firstWhere(
          (loc) => loc['is_primary'] == 1 || loc['is_primary'] == true,
          orElse: () => locations.first,
        );
        userAddress.value = primary['address_text'] ?? 'Jakarta';
        latitude.value = double.tryParse(primary['latitude']?.toString() ?? '0.0') ?? 0.0;
        longitude.value = double.tryParse(primary['longitude']?.toString() ?? '0.0') ?? 0.0;
        
        calculateRuleShippingFee();
      } else {
        userAddress.value = 'Mode Tamu / Belum Login';
        shippingFee.value = 20000.0; // Default
      }
    } catch (e) {
      userAddress.value = 'Mode Tamu / Belum Login';
      shippingFee.value = 20000.0;
    }
  }

  void calculateRuleShippingFee() {
    final double lat = latitude.value;
    final double lng = longitude.value;
    final String addr = userAddress.value.toLowerCase();
    
    bool isJawa = false;

    // Check by coordinates first (Pulau Jawa box)
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

    // Calculate physical distance to store for display
    final double storeLat = double.tryParse(storeInfo['latitude']?.toString() ?? '0') ?? -6.1953;
    final double storeLng = double.tryParse(storeInfo['longitude']?.toString() ?? '0') ?? 106.8203;
    if (lat != 0.0 && lng != 0.0) {
      final double distInMeters = Geolocator.distanceBetween(lat, lng, storeLat, storeLng);
      distance.value = distInMeters / 1000.0;
    }
  }
}