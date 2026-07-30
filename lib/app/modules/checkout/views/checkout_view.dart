import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/currency_formatter.dart';
import '../controllers/checkout_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class CheckoutView extends GetView<CheckoutController> {
  const CheckoutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Checkout Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Daftar Produk Yang Dibeli
              const Text('Daftar Produk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
              const SizedBox(height: 8),
              ...controller.items.map((item) => _buildItemCard(item)),
              const SizedBox(height: 20),

              // 2. Jika pembelian langsung (bukan dari Cart), izinkan ubah kuantitas & ukuran
              if (!controller.isFromCart.value) _buildDirectBuySelector(),

              // 3. Info Pengiriman & GPS LBS
              const Text('Info Pengiriman', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
              const SizedBox(height: 8),
              _buildShippingCard(),
              const SizedBox(height: 20),

              // 4. Rincian Pembayaran
              const Text('Rincian Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText)),
              const SizedBox(height: 8),
              _buildPaymentSummary(),
              const SizedBox(height: 32),

              // 5. Tombol Aksi
              controller.isFromCart.value
                  ? SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandYellow,
                          foregroundColor: darkText,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: controller.isLoading.value ? null : () => controller.submitOrder(),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: darkText, strokeWidth: 2),
                              )
                            : const Text('Buat Pesanan Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: brandYellow, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: controller.isLoading.value ? null : () => controller.addToCart(),
                              child: const Text('Masukkan Keranjang', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: darkText)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandYellow,
                                foregroundColor: darkText,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: controller.isLoading.value ? null : () => controller.submitOrder(),
                              child: const Text('Beli Sekarang', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildItemCard(dynamic item) {
    final rawUrl = item['image_url']?.toString() ?? '';
    final isBrokenPlaceholder = rawUrl.contains('v1700000000');
    final imageUrl = (!isBrokenPlaceholder && rawUrl.isNotEmpty)
        ? rawUrl
        : (item['name'].toString().toLowerCase().contains('compass')
            ? 'https://images.unsplash.com/photo-1597045566677-8cf032ed6634?q=80&w=600'
            : 'https://images.unsplash.com/photo-1525966222134-fcfa99b8ae77?q=80&w=600');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] ?? 'Sepatu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Ukuran: ${item['size'] ?? '-'}  |  Jumlah: ${item['quantity'] ?? 1}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(formatCurrency(double.tryParse(item['price']?.toString() ?? '0') ?? 0.0), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectBuySelector() {
    final originalArgs = Get.arguments;

    final Map<dynamic, dynamic> sizeStock = (originalArgs != null && originalArgs['size_stock'] is Map)
        ? originalArgs['size_stock']
        : {};

    return Obx(() {
      // Akses semua reactive values di sini agar Obx melacaknya
      final directItem = controller.items.isNotEmpty ? controller.items[0] : {};
      final currentQty = directItem['quantity'] ?? 1;
      final maxStock = controller.maxSizeStock.value;
      final selectedSize = controller.selectedSize.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Opsi Pembelian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Divider(height: 20),

              // Pilih Ukuran
              const Text('Pilih Ukuran', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: sizeStock.isEmpty
                    ? null
                    : () => _showSizePickerSheet(sizeStock),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedSize.isEmpty ? Colors.red.shade300 : brandYellow,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    color: selectedSize.isEmpty
                        ? Colors.red.shade50
                        : brandYellow.withAlpha(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.straighten_rounded,
                              size: 18,
                              color: selectedSize.isEmpty ? Colors.red : darkText),
                          const SizedBox(width: 8),
                          Text(
                            selectedSize.isEmpty
                                ? 'Pilih ukuran sepatu'
                                : 'Ukuran: $selectedSize',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selectedSize.isEmpty ? Colors.red : darkText,
                            ),
                          ),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_up_rounded,
                          color: selectedSize.isEmpty ? Colors.red : Colors.grey),
                    ],
                  ),
                ),
              ),
              if (sizeStock.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Stok habis', style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
              const SizedBox(height: 16),

              // Kuantitas
              const Text('Jumlah', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _qtyButton(
                    icon: Icons.remove,
                    onTap: () => controller.updateDirectBuyQty(currentQty - 1),
                    enabled: currentQty > 1,
                  ),
                  Container(
                    width: 48,
                    alignment: Alignment.center,
                    child: Text(
                      '$currentQty',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  _qtyButton(
                    icon: Icons.add,
                    onTap: () => controller.updateDirectBuyQty(currentQty + 1),
                    enabled: currentQty < maxStock,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Maks. $maxStock pcs',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: enabled ? brandYellow : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: enabled ? darkText : Colors.grey[500]),
      ),
    );
  }

  void _showSizePickerSheet(Map<dynamic, dynamic> sizeStock) {
    // Sort sizes numerically
    final sortedEntries = sizeStock.entries.toList()
      ..sort((a, b) {
        final aNum = int.tryParse(a.key.toString()) ?? 0;
        final bNum = int.tryParse(b.key.toString()) ?? 0;
        return aNum.compareTo(bNum);
      });

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Ukuran Sepatu',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Ukuran bertanda \u274c tidak tersedia',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Size chips grid
            Obx(() => Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: sortedEntries.map((entry) {
                    final size = entry.key.toString();
                    final stock = int.tryParse(entry.value.toString()) ?? 0;
                    final isAvailable = stock > 0;
                    final isSelected = controller.selectedSize.value == size;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () {
                              controller.updateDirectBuySize(size);
                              Get.back();
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 72,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? brandYellow
                              : isAvailable
                                  ? Colors.white
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? brandYellow
                                : isAvailable
                                    ? Colors.black12
                                    : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(color: brandYellow.withAlpha(80), blurRadius: 6, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  size,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? darkText
                                        : isAvailable
                                            ? Colors.black87
                                            : Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAvailable ? 'Stok $stock' : 'Habis',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isSelected
                                        ? darkText
                                        : isAvailable
                                            ? Colors.grey[600]
                                            : Colors.red[300],
                                  ),
                                ),
                              ],
                            ),
                            // Diagonal strike for unavailable
                            if (!isAvailable)
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _DiagonalLinePainter(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),
            const SizedBox(height: 20),

            // Confirm button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.selectedSize.value.isEmpty
                          ? Colors.grey[300]
                          : brandYellow,
                      foregroundColor: darkText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: controller.selectedSize.value.isEmpty ? null : () => Get.back(),
                    child: Text(
                      controller.selectedSize.value.isEmpty
                          ? 'Pilih ukuran terlebih dahulu'
                          : 'Konfirmasi Ukuran ${controller.selectedSize.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                )),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildShippingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: brandYellow, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.storeInfo['name'] ?? 'Toko Pusat Localize',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            Text(
              controller.storeInfo['address'] ?? 'Jakarta Pusat',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
            const Divider(height: 20),
            TextField(
              controller: controller.addressController,
              decoration: const InputDecoration(
                hintText: 'Alamat Pengiriman Lengkap',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.home_outlined, size: 20),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: brandYellow)),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.addressNotesController,
              decoration: const InputDecoration(
                hintText: 'Patokan Lokasi (Contoh: Pagar Hitam, Depan Masjid)',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                prefixIcon: Icon(Icons.pin_drop_outlined, size: 20),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: brandYellow)),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ' * Keterangan lokasi tambahan (patokan) di bawah lokasinya',
              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),
            Obx(() => OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    side: const BorderSide(color: brandYellow),
                  ),
                  onPressed: controller.isGettingLocation.value ? null : () => controller.getCurrentLocation(),
                  icon: controller.isGettingLocation.value
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 16, color: darkText),
                  label: Text(
                    controller.locationName.value.isEmpty
                        ? 'Dapatkan Koordinat GPS LBS Baru'
                        : 'GPS Terkunci (${controller.distance.value.toStringAsFixed(2)} km)',
                    style: const TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Belanja', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatCurrency(controller.totalItemsPrice), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Ongkos Kirim (GPS LBS)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(formatCurrency(controller.shippingFee.value), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(
                  formatCurrency(controller.grandTotal),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a diagonal line across the chip to indicate unavailable size
class _DiagonalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withAlpha(120)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_DiagonalLinePainter oldDelegate) => false;
}

