import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../utils/currency_formatter.dart';
import '../controllers/pesanan_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class PesananView extends GetView<PesananController> {
  const PesananView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Shopee Style Status Filter Bar — scrollable
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusTab('Dipesan', 'dipesan'),
                  _buildStatusTab('Dibayar', 'dibayar'),
                  _buildStatusTab('Dikirim', 'dikirim'),
                  _buildStatusTab('Selesai', 'selesai'),
                  _buildStatusTab('Dibatalkan', 'batal'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadMyOrders(),
              child: Obx(() {
                if (controller.isLoadingOrders.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredList = controller.myOrders.where((order) {
                  final status = (order['status'] ?? 'dipesan').toString().toLowerCase();
                  return status == controller.selectedOrderStatusFilter.value;
                }).toList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada pesanan dengan status "${controller.selectedOrderStatusFilter.value}".',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final order = filteredList[index];
                    final status = order['status'] ?? 'dipesan';

                    Color statusColor;
                    switch (status.toString().toLowerCase()) {
                      case 'dibayar':
                        statusColor = Colors.blue;
                        break;
                      case 'dikirim':
                        statusColor = Colors.orange;
                        break;
                      case 'selesai':
                        statusColor = Colors.green;
                        break;
                      case 'batal':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = brandYellow;
                    }

                    return GestureDetector(
                      onTap: () => Get.toNamed(Routes.ORDER_DETAIL, arguments: order),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: nama produk + badge status
                              Row(
                                children: [
                                  // Gambar produk kecil
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: (order['product_image'] != null && order['product_image'].toString().isNotEmpty)
                                        ? Image.network(order['product_image'].toString(),
                                            width: 40, height: 40, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _imgPlaceholder())
                                        : _imgPlaceholder(),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      order['product_name']?.toString() ?? 'Produk',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(40),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      status.toString().toUpperCase(),
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text(
                                order['shipping_address']?.toString() ?? '-',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (order['address_notes'] != null && order['address_notes'].toString().isNotEmpty)
                                Text(
                                  '📍 ${order['address_notes']}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ukuran ${order['ordered_size'] ?? '-'}  ·  ${order['ordered_quantity'] ?? 1} pcs',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  Text(
                                    formatCurrency(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Tombol & Info
                              if (status.toString().toLowerCase() == 'dipesan') ...[              
                                if (order['expires_at'] != null)
                                  Builder(builder: (context) {
                                    final expiresAt = DateTime.tryParse(order['expires_at'].toString());
                                    if (expiresAt == null) return const SizedBox.shrink();
                                    final now = DateTime.now();
                                    final diff = expiresAt.difference(now);
                                    final isExpired = diff.isNegative;
                                    final hours = diff.inHours;
                                    final minutes = diff.inMinutes % 60;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isExpired ? Colors.red.shade50 : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isExpired ? Colors.red.shade200 : Colors.amber.shade300),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.timer_outlined, size: 14,
                                              color: isExpired ? Colors.red : Colors.amber.shade800),
                                          const SizedBox(width: 6),
                                          Text(
                                            isExpired
                                                ? 'Batas waktu pembayaran telah habis'
                                                : 'Bayar sebelum: ${hours}j ${minutes}m lagi',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isExpired ? Colors.red : Colors.amber.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                const SizedBox(height: 10),
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
                                        onPressed: () => controller.cancelOrder(order['order_id'] ?? order['id']),
                                        icon: const Icon(Icons.cancel_outlined, size: 16),
                                        label: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: brandYellow,
                                          foregroundColor: darkText,
                                          visualDensity: VisualDensity.compact,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () => controller.uploadProof(order['order_id'] ?? order['id']),
                                        icon: const Icon(Icons.upload_file, size: 16),
                                        label: const Text('Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (status.toString().toLowerCase() != 'dipesan')
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ketuk untuk melihat detail',
                                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTab(String label, String status) {
    return Obx(() {
      final isSelected = controller.selectedOrderStatusFilter.value == status;
      return GestureDetector(
        onTap: () => controller.selectedOrderStatusFilter.value = status,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? brandYellow : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? darkText : Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
      );
    });
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.image_not_supported_rounded, size: 20, color: Colors.grey),
    );
  }
}
