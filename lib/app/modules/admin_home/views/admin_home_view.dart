import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/admin_home_controller.dart';

class AdminHomeView extends GetView<AdminHomeController> {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFFFB800);
    const Color darkText = Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
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
        onRefresh: () async => controller.fetchAdminDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Sistem Store',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 12),

              // Summary Stat Cards
              Obx(() => Row(
                    children: [
                      _buildStatCard('Produk', '${controller.productsList.length}', Icons.inventory_2, brandYellow),
                      const SizedBox(width: 8),
                      _buildStatCard('Pesanan', '${controller.adminOrdersList.length}', Icons.shopping_cart, Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatCard('Pengguna', '${controller.usersList.length}', Icons.people, Colors.amber),
                    ],
                  )),
              const SizedBox(height: 24),

              const Text(
                'Daftar Transaksi Masuk (Admin)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText),
              ),
              const SizedBox(height: 10),

              // List Transaksi Masuk
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }
                if (controller.adminOrdersList.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Belum ada transaksi masuk dari pelanggan.'),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.adminOrdersList.length,
                  itemBuilder: (context, index) {
                    final order = controller.adminOrdersList[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: brandYellow,
                          child: Icon(Icons.receipt, color: darkText),
                        ),
                        title: Text('Order ID #${order['order_id'] ?? order['id'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Customer: ${order['customer_name'] ?? 'Budi'} | Jarak: ${order['distance'] ?? '-'} km'),
                        trailing: Text(
                          'Rp ${order['total_amount'] ?? 0}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
        onPressed: () {
          Get.snackbar('Tambah Sepatu', 'Fitur Tambah Produk Cloudinary (Admin)');
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}