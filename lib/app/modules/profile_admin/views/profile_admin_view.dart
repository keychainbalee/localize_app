import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_admin_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class ProfileAdminView extends GetView<ProfileAdminController> {
  const ProfileAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadAdminProfile();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Profil Admin Store', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.userId.value == 0) {
          return const _AdminProfileSkeleton();
        }

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge Status Role Admin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: brandYellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.admin_panel_settings, size: 16, color: darkText),
                    SizedBox(width: 6),
                    Text('ADMINISTRATOR TOKO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: darkText)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Avatar Section
              GestureDetector(
                onTap: () => controller.changeProfilePhoto(),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: controller.userAvatarUrl.value.isNotEmpty
                          ? NetworkImage(controller.userAvatarUrl.value)
                          : null,
                      child: controller.userAvatarUrl.value.isEmpty
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: brandYellow, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 18, color: darkText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                controller.userName.value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
              ),
              Text(
                controller.userEmail.value,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),

              _buildProfileItem(Icons.phone, 'Nomor Telepon Admin', controller.userPhone.value),
              const SizedBox(height: 16),

              // Lokasi Admin Toko yang diambil dari Endpoint /users/locations
              _buildProfileItem(
                Icons.location_on,
                'Lokasi Toko Terdaftar (/users/locations)',
                controller.userAddress.value,
              ),

              // Daftar Lokasi Terdaftar jika ada lebih dari 1
              if (controller.adminLocations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storefront, size: 16, color: Colors.amber),
                          const SizedBox(width: 6),
                          Text(
                            'Lokasi Terdaftar Admin (${controller.adminLocations.length} titik):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: darkText),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Column(
                        children: controller.adminLocations.map((loc) {
                          final label = loc['label']?.toString() ?? 'Toko';
                          final addr = loc['address_text'] ?? loc['addressText'] ?? '-';
                          final isPrimary = (loc['is_primary'] == 1 || loc['isPrimary'] == 1);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                            child: Row(
                              children: [
                                Icon(
                                  isPrimary ? Icons.star : Icons.circle_outlined,
                                  size: 12,
                                  color: isPrimary ? Colors.amber[900] : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '[$label] $addr',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandYellow,
                    foregroundColor: darkText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => Get.toNamed(Routes.EDIT_PROFILE),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profil & Lokasi Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () => controller.logout(),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Keluar Akun Admin', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Skeleton Loading Shimmer Admin Profile ───────────────────────────────

class _AdminProfileSkeleton extends StatefulWidget {
  const _AdminProfileSkeleton();

  @override
  State<_AdminProfileSkeleton> createState() => _AdminProfileSkeletonState();
}

class _AdminProfileSkeletonState extends State<_AdminProfileSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ShimmerBox(width: 140, height: 24, borderRadius: 12, shimmerValue: _animation.value),
              const SizedBox(height: 16),
              _ShimmerBox(width: 100, height: 100, borderRadius: 50, shimmerValue: _animation.value),
              const SizedBox(height: 16),
              _ShimmerBox(width: 160, height: 18, borderRadius: 8, shimmerValue: _animation.value),
              const SizedBox(height: 8),
              _ShimmerBox(width: 220, height: 14, borderRadius: 8, shimmerValue: _animation.value),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),
              _buildSkeletonInfoRow(_animation.value),
              const SizedBox(height: 24),
              _buildSkeletonInfoRow(_animation.value),
              const SizedBox(height: 36),
              _ShimmerBox(width: double.infinity, height: 48, borderRadius: 24, shimmerValue: _animation.value),
              const SizedBox(height: 12),
              _ShimmerBox(width: double.infinity, height: 48, borderRadius: 24, shimmerValue: _animation.value, baseColor: Colors.grey[200]!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeletonInfoRow(double shimmerValue) {
    return Row(
      children: [
        _ShimmerBox(width: 24, height: 24, borderRadius: 6, shimmerValue: shimmerValue),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 80, height: 11, borderRadius: 6, shimmerValue: shimmerValue),
              const SizedBox(height: 6),
              _ShimmerBox(width: double.infinity, height: 14, borderRadius: 6, shimmerValue: shimmerValue),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.shimmerValue,
    this.baseColor,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double shimmerValue;
  final Color? baseColor;

  @override
  Widget build(BuildContext context) {
    final base = baseColor ?? Colors.grey[300]!;
    final highlight = Colors.grey[100]!;

    return Container(
      width: width == double.infinity ? null : width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          stops: const [0.0, 0.5, 1.0],
          colors: [base, highlight, base],
          transform: _SlidingGradientTransform(shimmerValue),
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
