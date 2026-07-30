import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../../routes/app_pages.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFFFB800);
    const Color darkText = Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Localize Store'),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(
              () => UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: brandYellow),
                accountName: Text(
                  controller.userName.value,
                  style: const TextStyle(color: darkText, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(
                  controller.userEmail.value,
                  style: const TextStyle(color: darkText),
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: controller.userAvatarUrl.value.isNotEmpty
                      ? NetworkImage(controller.userAvatarUrl.value)
                      : null,
                  child: controller.userAvatarUrl.value.isEmpty
                      ? const Icon(Icons.person, color: darkText, size: 36)
                      : null,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Beranda'),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Pesanan Saya'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onTap: () => controller.logout(),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.loadDashboardData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Geospasial GPS Toko
              Obx(
                () => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: brandYellow),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: brandYellow,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.storeInfo['name'] ?? 'Localize Store',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ongkir dinamis Rp ${controller.storeInfo['shipping_fee_per_km'] ?? 2500}/km via GPS',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Katalog Sepatu Lokal 🇮🇩',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 12),

              // Grid Katalog Sepatu
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (controller.products.isEmpty) {
                  return const Center(child: Text('Belum ada produk sepatu.'));
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final item = controller.products[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Builder(
                                builder: (context) {
                                  final rawUrl = item['image_url']?.toString() ?? '';
                                  final isBrokenPlaceholder = rawUrl.contains('v1700000000');
                                  
                                  // Set clean, working image URLs if rawUrl is empty or placeholder is broken
                                  final imageUrl = (!isBrokenPlaceholder && rawUrl.isNotEmpty)
                                      ? rawUrl
                                      : (item['name'].toString().toLowerCase().contains('compass')
                                          ? 'https://images.unsplash.com/photo-1597045566677-8cf032ed6634?q=80&w=600'
                                          : 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=600');

                                  return Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    // Handler jika link gambar 404 / rusak
                                    errorBuilder: (context, error, stackTrace) {
                                      final String fallbackUrl = item['name'].toString().toLowerCase().contains('compass')
                                          ? 'https://images.unsplash.com/photo-1597045566677-8cf032ed6634?q=80&w=600'
                                          : 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=600';
                                      return Image.network(
                                        fallbackUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (ctx, err, stack) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Icon(
                                                Icons.image_not_supported_rounded,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    // Indicator saat gambar sedang di-load dari jaringan
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: brandYellow,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Badge Brand
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: brandYellow.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['brand'] ?? 'Local Pride',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['name'] ?? 'Sepatu',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Rp ${item['price'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: darkText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Terjual: ${item['sold_count'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: brandYellow,
                                      foregroundColor: darkText,
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    onPressed: () => Get.toNamed(
                                      Routes.CHECKOUT,
                                      arguments: item,
                                    ),
                                    child: const Text(
                                      'Beli',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
