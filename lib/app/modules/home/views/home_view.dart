import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../pesanan/views/pesanan_view.dart';
import '../../profile/views/profile_view.dart';
import '../../../widgets/custom_bottom_bar.dart';
import '../../../utils/currency_formatter.dart';
import '../controllers/home_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Obx(() {
        switch (controller.selectedTabIndex.value) {
          case 1:
            return const PesananView();
          case 2:
            return const ProfileView();
          default:
            return _buildHomeTab(context);
        }
      }),
      bottomNavigationBar: Obx(() => CustomBottomBar(
            currentIndex: controller.selectedTabIndex.value,
            onTap: (index) => controller.changeTab(index),
          )),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Localize',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () => Get.toNamed(Routes.CART),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadDashboardData(),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Banner Store Info & GPS LBS Terdeteksi
                _buildGeospatialBanner(),

                // 2. Search Container (Redirects to Search Page)
                _buildSearchButton(),

                // 2b. Banner Promo Image Slider
                _buildPromoSlider(),

                // 3. Section: Produk Terbaru
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Produk Terbaru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
                  ),
                ),
                _buildHorizontalProducts(controller.latestProducts),

                // 4. Section: Produk Terlaris
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Produk Terpopuler',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
                  ),
                ),
                _buildHorizontalProducts(controller.bestSellerProducts),

                // 5. Section: Semua Katalog
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(
                    'Semua Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
                  ),
                ),
                _buildProductGrid(),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGeospatialBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brandYellow, Color(0xFFFFD666)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: brandYellow.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: darkText, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  controller.storeInfo['name'] ?? 'Toko Pusat Localize',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: darkText, fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lokasi Toko: ${controller.storeInfo['address'] ?? 'Grand Indonesia, Jakarta'}',
            style: const TextStyle(color: Colors.black87, fontSize: 11),
          ),
          const Divider(color: Colors.black12, height: 16),
          Row(
            children: [
              const Icon(Icons.my_location_rounded, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Kirim Ke: ${controller.userAddress.value}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: darkText, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Jarak: ${controller.distance.value.toStringAsFixed(1)} km  |  Ongkir Flat: ${formatCurrency(controller.shippingFee.value)}',
            style: const TextStyle(fontWeight: FontWeight.bold, color: darkText, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.SEARCH),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.black12),
        ),
        child: const Row(
          children: [
            Icon(Icons.search, color: Colors.grey),
            SizedBox(width: 12),
            Text(
              'Cari sepatu impianmu di sini...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoSlider() {
    if (controller.bannerImages.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Slider
          PageView.builder(
            controller: controller.pageController,
            itemCount: controller.bannerImages.length,
            onPageChanged: (index) {
              controller.activeSlideIndex.value = index;
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  controller.bannerImages[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
          // Page Indicators
          Positioned(
            bottom: 12,
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.bannerImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: controller.activeSlideIndex.value == index ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: controller.activeSlideIndex.value == index
                            ? brandYellow
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalProducts(RxList<dynamic> productList) {
    if (productList.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('Tidak ada produk', style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 230,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: productList.length,
        itemBuilder: (context, index) {
          final p = productList[index];
          final rawUrl = p['image_url']?.toString() ?? '';
          final isBrokenPlaceholder = rawUrl.contains('v1700000000');
          final imageUrl = (!isBrokenPlaceholder && rawUrl.isNotEmpty)
              ? rawUrl
              : (p['name'].toString().toLowerCase().contains('compass')
                  ? 'https://images.unsplash.com/photo-1597045566677-8cf032ed6634?q=80&w=600'
                  : 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=600');

          return GestureDetector(
            onTap: () => Get.toNamed(Routes.CHECKOUT, arguments: p),
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      height: 100,
                      width: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 100,
                        width: 140,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['name'] ?? 'Sepatu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(p['brand'] ?? 'Lokal', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(formatCurrency(double.tryParse(p['price']?.toString() ?? '0') ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 9, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text('${p['sold_count'] ?? 0} terjual', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 9, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Text(
                              'Stok ${p['stock'] ?? 0}',
                              style: TextStyle(
                                fontSize: 9,
                                color: (int.tryParse(p['stock']?.toString() ?? '0') ?? 0) > 0 ? Colors.green[700] : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    if (controller.allProducts.isEmpty) {
      return const Center(child: Text('Katalog kosong'));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: controller.allProducts.length,
      itemBuilder: (context, index) {
        final p = controller.allProducts[index];
        final rawUrl = p['image_url']?.toString() ?? '';
        final isBrokenPlaceholder = rawUrl.contains('v1700000000');
        final imageUrl = (!isBrokenPlaceholder && rawUrl.isNotEmpty)
            ? rawUrl
            : (p['name'].toString().toLowerCase().contains('compass')
                ? 'https://images.unsplash.com/photo-1597045566677-8cf032ed6634?q=80&w=600'
                : 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=600');

        return GestureDetector(
          onTap: () => Get.toNamed(Routes.CHECKOUT, arguments: p),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p['name'] ?? 'Sepatu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(p['brand'] ?? 'Lokal', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(formatCurrency(double.tryParse(p['price']?.toString() ?? '0') ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 13)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 10, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text('${p['sold_count'] ?? 0} terjual', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                          const SizedBox(width: 6),
                          Icon(Icons.inventory_2_outlined, size: 10, color: Colors.grey[500]),
                          const SizedBox(width: 2),
                          Text(
                            'Stok ${p['stock'] ?? 0}',
                            style: TextStyle(
                              fontSize: 9,
                              color: (int.tryParse(p['stock']?.toString() ?? '0') ?? 0) > 0 ? Colors.green[700] : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
