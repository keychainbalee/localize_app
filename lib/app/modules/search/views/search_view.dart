import 'package:flutter/material.dart' hide SearchController;
import 'package:get/get.dart';
import '../../../utils/currency_formatter.dart';
import '../controllers/search_controller.dart';
import '../../../routes/app_pages.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color brandYellowLight = Color(0x4DFFB800);
const Color darkText = Color(0xFF2D2D2D);

class SearchView extends GetView<SearchController> {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: controller.searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 14, color: darkText),
              decoration: InputDecoration(
                hintText: 'Cari sepatu lokal idaman...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                        onPressed: () => controller.searchController.clear(),
                      )
                    : const SizedBox()),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // Brand Filter Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Obx(() => DropdownButton<String>(
                                value: controller.selectedBrand.value,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                items: controller.brandsList.map((String brand) {
                                  return DropdownMenuItem<String>(
                                    value: brand,
                                    child: Text(brand, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.selectedBrand.value = value;
                                  }
                                },
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort Filter Dropdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Obx(() => DropdownButton<String>(
                                value: controller.sortBy.value,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                                items: <String>['Default', 'Termurah', 'Termahal'].map((String sort) {
                                  return DropdownMenuItem<String>(
                                    value: sort,
                                    child: Text(sort, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.sortBy.value = value;
                                  }
                                },
                              )),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text(
                          'Menampilkan ${controller.filteredProducts.length} produk',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                        )),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: controller.resetFilters,
                      icon: const Icon(Icons.restart_alt, size: 16, color: Colors.redAccent),
                      label: const Text('Reset Filter', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results Grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final list = controller.filteredProducts;

              if (list.isEmpty) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Produk tidak ditemukan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba kata kunci lain atau reset filter pencarian Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final item = list[index];
                  return _buildProductCard(item);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(
          Routes.CHECKOUT,
          arguments: item,
        ),
        borderRadius: BorderRadius.circular(12),
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
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        );
                      },
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: brandYellowLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item['brand'] ?? 'Local Pride',
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['name'] ?? 'Sepatu',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formatCurrency(double.tryParse(item['price']?.toString() ?? '0') ?? 0.0),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(Icons.shopping_bag_outlined, size: 9, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        'Terjual ${item['sold_count'] ?? 0}',
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.inventory_2_outlined, size: 9, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Text(
                        'Stok ${item['stock'] ?? 0}',
                        style: TextStyle(
                          fontSize: 9,
                          color: (int.tryParse(item['stock']?.toString() ?? '0') ?? 0) > 0
                              ? Colors.green[700]
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandYellow,
                        foregroundColor: darkText,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Get.toNamed(
                        Routes.CHECKOUT,
                        arguments: item,
                      ),
                      child: const Text(
                        'Beli',
                        style: TextStyle(
                          fontSize: 11,
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
      ),
    );
  }
}
