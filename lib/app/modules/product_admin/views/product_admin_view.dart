import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_admin_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class ProductAdminView extends GetView<ProductAdminController> {
  const ProductAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Obx(() => Text(
              controller.isEditMode.value ? 'Detail & Edit Produk' : 'Tambah Produk Baru',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Image Picker Box
            _buildImagePickerBox(),
            const SizedBox(height: 24),

            // Form Informasi Dasar Produk
            _buildSectionHeader('Informasi Produk', Icons.info_outline),
            const SizedBox(height: 12),

            _buildTextField(
              controller: controller.nameController,
              label: 'Nama Sepatu/Produk',
              hint: 'Contoh: Ventela Public Low Black',
              icon: Icons.title,
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.brandController,
                    label: 'Brand',
                    hint: 'Contoh: Ventela',
                    icon: Icons.branding_watermark_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: controller.priceController,
                    label: 'Harga (Rp)',
                    hint: 'Contoh: 289000',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildTextField(
              controller: controller.descriptionController,
              label: 'Deskripsi Produk',
              hint: 'Masukkan deskripsi keunggulan & material sepatu...',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Informasi Terjual (Jika Edit Mode)
            Obx(() {
              if (!controller.isEditMode.value) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_mall_outlined, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jumlah Terjual', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          '${controller.currentSoldCount.value} pasang sepatu terjual',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkText),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            // Form Manajemen Stok Per Ukuran
            _buildSectionHeader('Manajemen Stok per Ukuran', Icons.format_list_numbered),
            const SizedBox(height: 6),
            Text(
              'Masukkan jumlah stok fisik yang tersedia untuk tiap nomor sepatu:',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),

            _buildSizeStockGrid(),
            const SizedBox(height: 24),

            // URL Gambar Opsional
            _buildTextField(
              controller: controller.imageUrlController,
              label: 'URL Gambar (Opsional)',
              hint: 'https://res.cloudinary.com/...',
              icon: Icons.link_outlined,
            ),
            const SizedBox(height: 32),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandYellow,
                  foregroundColor: darkText,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => controller.saveProduct(),
                icon: const Icon(Icons.save_rounded),
                label: Obx(() => Text(
                      controller.isEditMode.value ? 'Simpan Perubahan Produk' : 'Tambah Produk Ke Katalog',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    )),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: brandYellow),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkText),
        ),
      ],
    );
  }

  Widget _buildImagePickerBox() {
    return Obx(() {
      final selectedPath = controller.selectedImagePath.value;
      final url = controller.imageUrlController.text.trim();

      Widget imageWidget;
      if (selectedPath.isNotEmpty) {
        imageWidget = Image.file(File(selectedPath), fit: BoxFit.cover, width: double.infinity);
      } else if (url.isNotEmpty) {
        imageWidget = Image.network(url, fit: BoxFit.cover, width: double.infinity,
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50, color: Colors.grey));
      } else {
        imageWidget = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 44, color: Colors.grey[500]),
            const SizedBox(height: 8),
            Text('Pilih Foto Sepatu Dari Galeri', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Foto akan otomatis diunggah ke Cloudinary', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        );
      }

      return GestureDetector(
        onTap: () => controller.pickImage(),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brandYellow, width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: imageWidget,
          ),
        ),
      );
    });
  }

  Widget _buildSizeStockGrid() {
    final sizes = controller.sizeStockControllers.keys.toList();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: sizes.map((size) {
              final c = controller.sizeStockControllers[size]!;
              return SizedBox(
                width: 90,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: brandYellow.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Size $size', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: c,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandYellow, width: 2),
        ),
      ),
    );
  }
}
