import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import '../controllers/map_picker_controller.dart';

const Color brandYellow = Color(0xFFFFB800);
const Color darkText = Color(0xFF2D2D2D);

class MapPickerView extends GetView<MapPickerController> {
  const MapPickerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Maps', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: brandYellow,
        foregroundColor: darkText,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. FlutterMap menggunakan openstreetmap
          Obx(() => FlutterMap(
                mapController: controller.mapController,
                options: MapOptions(
                  initialCenter: controller.selectedLatLng.value,
                  initialZoom: 15.0,
                  onTap: (tapPosition, point) => controller.updateLocation(point),
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture && position.center != null) {
                      controller.selectedLatLng.value = position.center!;
                    }
                  },
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) {
                      controller.reverseGeocode();
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.localize.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: controller.selectedLatLng.value,
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              )),

          // 2. Tombol Floating GPS center kembali ke posisi asli
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: darkText,
              onPressed: () => controller.getUserLocation(),
              child: const Icon(Icons.my_location),
            ),
          ),

          // 3. Floating Bottom Selector Info Card
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: brandYellow, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Lokasi Terpilih',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          controller.addressText.value,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        )),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          'Koordinat: ${controller.selectedLatLng.value.latitude.toStringAsFixed(5)}, ${controller.selectedLatLng.value.longitude.toStringAsFixed(5)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brandYellow,
                          foregroundColor: darkText,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        ),
                        onPressed: () => controller.confirmLocation(),
                        child: const Text(
                          'Gunakan Lokasi Ini',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
