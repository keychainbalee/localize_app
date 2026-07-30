import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/currency_formatter.dart';
import '../../pesanan/controllers/pesanan_controller.dart';
import '../controllers/order_detail_controller.dart';

const Color _yellow = Color(0xFFFFB800);
const Color _dark   = Color(0xFF2D2D2D);

class OrderDetailView extends GetView<OrderDetailController> {
  const OrderDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _yellow,
        foregroundColor: _dark,
        elevation: 0,
      ),
      body: Obx(() {
        final order = controller.order;
        if (order.isEmpty) {
          return const Center(child: Text('Data tidak tersedia'));
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // ── Status Banner ─────────────────────────────
              _buildStatusBanner(),

              const SizedBox(height: 12),

              // ── Info Produk ───────────────────────────────
              _sectionCard(
                title: 'Produk yang Dipesan',
                icon: Icons.shopping_bag_outlined,
                child: _buildProductInfo(order),
              ),

              const SizedBox(height: 12),

              // ── Info Pengiriman ───────────────────────────
              _sectionCard(
                title: 'Informasi Pengiriman',
                icon: Icons.local_shipping_outlined,
                child: _buildShippingInfo(order),
              ),

              const SizedBox(height: 12),

              // ── Rincian Pembayaran ────────────────────────
              _sectionCard(
                title: 'Rincian Pembayaran',
                icon: Icons.receipt_long_outlined,
                child: _buildPaymentInfo(order),
              ),

              // ── Bukti Bayar (jika ada) ────────────────────
              if (order['payment_proof_url'] != null &&
                  order['payment_proof_url'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Bukti Pembayaran',
                  icon: Icons.image_outlined,
                  child: _buildProofImage(order['payment_proof_url'].toString()),
                ),
              ],

              const SizedBox(height: 12),

              // ── Tombol Aksi ───────────────────────────────
              if (controller.isDipesan) _buildActionButtons(),

              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  // ── Status Banner ──────────────────────────────────────────
  Widget _buildStatusBanner() {
    return Obx(() {
      final diff = controller.timeRemaining;
      final showTimer = controller.isDipesan && diff != null;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: controller.statusColor,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Icon(controller.statusIcon, color: Colors.white, size: 42),
            const SizedBox(height: 8),
            Text(
              controller.statusLabel,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              controller.statusDesc,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (showTimer) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      controller.expiryText,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  // ── Produk Info ────────────────────────────────────────────
  Widget _buildProductInfo(Map order) {
    final imageUrl = order['product_image']?.toString() ?? '';
    final name     = order['product_name']?.toString() ?? 'Produk';
    final size     = order['ordered_size']?.toString() ?? '-';
    final qty      = order['ordered_quantity']?.toString() ?? '1';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl.isNotEmpty
              ? Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _imgPlaceholder())
              : _imgPlaceholder(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              _infoRow(Icons.straighten_rounded, 'Ukuran', size),
              _infoRow(Icons.format_list_numbered, 'Jumlah', '$qty pcs'),
            ],
          ),
        ),
      ],
    );
  }

  // ── Pengiriman Info ────────────────────────────────────────
  Widget _buildShippingInfo(Map order) {
    final address = order['shipping_address']?.toString() ?? '-';
    final notes   = order['address_notes']?.toString() ?? '';
    final dist    = order['distance'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoRow(Icons.home_outlined, 'Alamat Pengiriman', address),
        if (notes.isNotEmpty) _infoRow(Icons.pin_drop_outlined, 'Patokan', notes),
        if (dist != null) _infoRow(Icons.route_outlined, 'Jarak ke Toko',
            '${double.tryParse(dist.toString())?.toStringAsFixed(1) ?? "-"} km'),
      ],
    );
  }

  // ── Pembayaran Info ────────────────────────────────────────
  Widget _buildPaymentInfo(Map order) {
    final totalAmount = double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0;
    final shippingFee = double.tryParse(order['shipping_fee']?.toString() ?? '0') ?? 0.0;
    final itemsPrice  = totalAmount - shippingFee;

    return Column(
      children: [
        _payRow('Total Belanja', formatCurrency(itemsPrice)),
        const SizedBox(height: 6),
        _payRow('Ongkos Kirim', controller.shippingFeeFormatted),
        const Divider(height: 20),
        _payRow('Total Pembayaran', controller.totalFormatted,
            isBold: true, valueColor: Colors.redAccent),
        if (order['created_at'] != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Dibuat: ${_formatDate(order['created_at'].toString())}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ],
    );
  }

  // ── Bukti Bayar ────────────────────────────────────────────
  Widget _buildProofImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
      ),
    );
  }

  // ── Tombol Aksi ────────────────────────────────────────────
  Widget _buildActionButtons() {
    final orderId = controller.order['order_id'] ?? controller.order['id'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // Panggil cancelOrder dari PesananController
                final pesananCtrl = Get.find<PesananController>();
                await pesananCtrl.cancelOrder(orderId);
                // Update status di halaman ini
                controller.order['status'] = 'batal';
                controller.order.refresh();
              },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _yellow,
                foregroundColor: _dark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final pesananCtrl = Get.find<PesananController>();
                pesananCtrl.uploadProof(orderId);
              },
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Unggah Bukti Bayar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _sectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _yellow),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isBold ? _dark : Colors.grey)),
        Text(value, style: TextStyle(
          fontSize: isBold ? 14 : 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: valueColor ?? _dark,
        )),
      ],
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }
}
