import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/currency_formatter.dart';
import '../controllers/pesanan_admin_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class PesananAdminView extends GetView<PesananAdminController> {
  const PesananAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Kelola Pesanan Masuk', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter status pesanan
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _buildFilterChip('Semua', 'semua'),
                  _buildFilterChip('Dipesan', 'dipesan'),
                  _buildFilterChip('Dibayar', 'dibayar'),
                  _buildFilterChip('Dikirim', 'dikirim'),
                  _buildFilterChip('Selesai', 'selesai'),
                  _buildFilterChip('Dibatalkan', 'batal'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () => controller.loadAdminOrders(),
              child: Obx(() {
                if (controller.isLoadingOrders.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = controller.filteredOrders;
                if (list.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada transaksi dengan status "${controller.selectedStatusFilter.value}".',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final order = list[index];
                    final orderId = int.tryParse((order['order_id'] ?? order['id'] ?? '0').toString()) ?? 0;
                    final status = (order['status'] ?? 'dipesan').toString().toLowerCase();
                    final proofUrl = order['payment_proof_url']?.toString();
                    final customerName = order['customer_name']?.toString() ?? 'Pelanggan';
                    final phone = order['phone_number']?.toString() ?? '-';
                    final address = order['shipping_address']?.toString() ?? '-';
                    final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
                    final productName = order['product_name']?.toString() ?? 'Produk Sepatu';
                    final size = order['ordered_size']?.toString() ?? '-';
                    final qty = order['ordered_quantity']?.toString() ?? '1';

                    Color statusColor;
                    switch (status) {
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

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header: Order ID & Badge Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order ID #$orderId',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(40),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),

                            // Customer & Product Info
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: brandYellow.withAlpha(50),
                                  child: const Icon(Icons.person, color: darkText),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      Text('📞 $phone', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('📦 $productName (Size $size) x $qty pcs',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text('📍 Alamat: $address',
                                      style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Pembayaran:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                Text(
                                  formatCurrency(totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Action Buttons Admin
                            Row(
                              children: [
                                // Button Lihat Bukti Bayar
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      side: BorderSide(color: (proofUrl != null && proofUrl.isNotEmpty) ? Colors.blue : Colors.grey),
                                    ),
                                    onPressed: () => controller.showPaymentProofDialog(proofUrl, orderId),
                                    icon: Icon(Icons.receipt_long, size: 16, color: (proofUrl != null && proofUrl.isNotEmpty) ? Colors.blue : Colors.grey),
                                    label: Text(
                                      (proofUrl != null && proofUrl.isNotEmpty) ? 'Bukti Bayar Ada' : 'Belum Ada Bukti',
                                      style: TextStyle(fontSize: 11, color: (proofUrl != null && proofUrl.isNotEmpty) ? Colors.blue : Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Button Ganti Status
                                PopupMenuButton<String>(
                                  onSelected: (newStatus) => controller.changeOrderStatus(orderId, newStatus),
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'dibayar', child: Text('Mark: DIBAYAR')),
                                    const PopupMenuItem(value: 'dikirim', child: Text('Mark: DIKIRIM')),
                                    const PopupMenuItem(value: 'selesai', child: Text('Mark: SELESAI')),
                                    const PopupMenuItem(value: 'batal', child: Text('Mark: BATAL', style: TextStyle(color: Colors.red))),
                                  ],
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: brandYellow,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      children: [
                                        Text('Ubah Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkText)),
                                        Icon(Icons.arrow_drop_down, color: darkText),
                                      ],
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Obx(() {
      final isSelected = controller.selectedStatusFilter.value == value;
      return GestureDetector(
        onTap: () => controller.selectedStatusFilter.value = value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? brandYellow : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? darkText : Colors.grey[700],
            ),
          ),
        ),
      );
    });
  }
}
