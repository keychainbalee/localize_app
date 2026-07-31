import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/admin_bottom_nav_bar.dart';
import '../../pesanan_admin/views/pesanan_admin_view.dart';
import '../../profile_admin/views/profile_admin_view.dart';
import '../controllers/admin_home_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class AdminHomeView extends GetView<AdminHomeController> {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedIndex = controller.selectedBottomIndex.value;

      final List<Widget> pages = [
        _buildProductsTab(context),
        const PesananAdminView(),
        const ProfileAdminView(),
      ];

      return Scaffold(
        body: pages[selectedIndex],
        bottomNavigationBar: AdminBottomNavBar(
          currentIndex: selectedIndex,
          onTap: (index) => controller.changeTab(index),
        ),
      );
    });
  }

  // ── Tab 1: Daftar Produk Toko (admin_home) ────────────────────────────────
  Widget _buildProductsTab(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Produk Toko (Admin)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => controller.logout(),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchAdminDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field produk
              TextField(
                onChanged: (val) => controller.searchQuery.value = val,
                decoration: InputDecoration(
                  hintText: 'Cari produk toko atau brand...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.black12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary Stat Cards
              Obx(() => Row(
                    children: [
                      _buildStatCard('Total Produk', '${controller.productsList.length}', Icons.inventory_2_outlined, brandYellow),
                      const SizedBox(width: 8),
                      _buildStatCard('Total Stok', '${controller.totalStockCount}', Icons.warehouse_outlined, Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatCard('Terjual', '${controller.totalSoldCount}', Icons.shopping_bag_outlined, Colors.green),
                    ],
                  )),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Katalog Seluruh Produk Sepatu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  Obx(() => Text(
                        '${controller.filteredProductsList.length} Item',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )),
                ],
              ),
              const SizedBox(height: 10),

              // List Produk Sepatu
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }

                final list = controller.filteredProductsList;
                if (list.isEmpty) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text('Belum ada produk sepatu dalam katalog toko.', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final productId = int.tryParse((item['id'] ?? '0').toString()) ?? 0;
                    final name = item['name']?.toString() ?? 'Sepatu';
                    final brand = item['brand']?.toString() ?? 'Lokal';
                    final price = double.tryParse((item['price'] ?? '0').toString()) ?? 0.0;
                    final stock = int.tryParse((item['stock'] ?? '0').toString()) ?? 0;
                    final sold = int.tryParse((item['sold_count'] ?? '0').toString()) ?? 0;
                    final imageUrl = item['image_url']?.toString() ?? '';
                    final sizeStockMap = item['size_stock'] is Map ? item['size_stock'] as Map : {};

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Gambar Produk
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _imgPlaceholder(),
                                        )
                                      : _imgPlaceholder(),
                                ),
                                const SizedBox(width: 12),

                                // Detail Info Produk
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text('Brand: $brand', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      Text(
                                        formatCurrency(price),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Detail Stok per Ukuran & Badge Terjual
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 14, color: stock > 0 ? Colors.green : Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Stok: $stock pasang',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: stock > 0 ? Colors.green[700] : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.local_mall_outlined, size: 14, color: Colors.amber[800]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Terjual: $sold',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Rincian stok per size (Size 38: 5, 39: 2, ...)
                            if (sizeStockMap.isNotEmpty)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: sizeStockMap.entries.map((e) {
                                    final sizeNum = e.key.toString();
                                    final sizeQty = int.tryParse(e.value.toString()) ?? 0;
                                    return Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: sizeQty > 0 ? Colors.grey[200] : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: sizeQty > 0 ? Colors.black12 : Colors.red.shade200),
                                      ),
                                      child: Text(
                                        'Size $sizeNum: $sizeQty',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: sizeQty > 0 ? Colors.black87 : Colors.red,
                                          fontWeight: sizeQty > 0 ? FontWeight.normal : FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 10),

                            // Action Buttons: Edit / Detail Produk ke product_admin & Hapus Produk
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      foregroundColor: Colors.red,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => controller.deleteProduct(productId, name),
                                    icon: const Icon(Icons.delete_outline, size: 16),
                                    label: const Text('Hapus', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: brandYellow,
                                      foregroundColor: darkText,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () async {
                                      await Get.toNamed(Routes.PRODUCT_ADMIN, arguments: item);
                                      controller.fetchAdminDashboard();
                                    },
                                    icon: const Icon(Icons.edit_note, size: 16),
                                    label: const Text('Detail & Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 4,
        onPressed: () async {
          await Get.toNamed(Routes.PRODUCT_ADMIN);
          controller.fetchAdminDashboard();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText)),
            Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
    );
  }
}