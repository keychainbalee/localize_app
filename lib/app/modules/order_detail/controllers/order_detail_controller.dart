import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/currency_formatter.dart';

class OrderDetailController extends GetxController {

  var order = {}.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Terima data order dari argument navigasi
    final args = Get.arguments;
    if (args != null && args is Map) {
      order.value = Map<String, dynamic>.from(args);
    }
  }

  String get status => (order['status'] ?? 'dipesan').toString().toLowerCase();
  String get statusLabel => status.toUpperCase();

  Color get statusColor {
    switch (status) {
      case 'dibayar':return const Color(0xFF1565C0);
      case 'dikirim':return const Color(0xFFE65100);
      case 'selesai':return const Color(0xFF2E7D32);
      case 'batal':return const Color(0xFFC62828);
      default:return const Color(0xFFFFB800);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'dibayar':return Icons.payment_rounded;
      case 'dikirim':return Icons.local_shipping_rounded;
      case 'selesai':return Icons.check_circle_rounded;
      case 'batal':return Icons.cancel_rounded;
      default:return Icons.receipt_long_rounded;
    }
  }

  String get statusDesc {
    switch (status) {
      case 'dipesan':return 'Pesanan menunggu konfirmasi pembayaran';
      case 'dibayar':return 'Bukti bayar diterima, sedang diverifikasi admin';
      case 'dikirim':return 'Pesanan sedang dalam perjalanan';
      case 'selesai':return 'Pesanan telah diterima. Terima kasih!';
      case 'batal':return 'Pesanan telah dibatalkan';
      default:return '';
    }
  }

  String get totalFormatted =>
      formatCurrency(double.tryParse(order['total_amount']?.toString() ?? '0') ?? 0.0);

  String get shippingFeeFormatted =>
      formatCurrency(double.tryParse(order['shipping_fee']?.toString() ?? '0') ?? 0.0);

  bool get isDipesan => status == 'dipesan';

  // Sisa waktu pembayaran
  Duration? get timeRemaining {
    if (order['expires_at'] == null) return null;
    final exp = DateTime.tryParse(order['expires_at'].toString());
    if (exp == null) return null;
    return exp.difference(DateTime.now());
  }

  String get expiryText {
    final diff = timeRemaining;
    if (diff == null) return '';
    if (diff.isNegative) return 'Waktu pembayaran telah habis';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return 'Bayar sebelum $h jam $m menit lagi';
  }
}
