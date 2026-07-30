import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

class MapPickerController extends GetxController {
  final MapController mapController = MapController();

  var selectedLatLng = const LatLng(-6.1953, 106.8203).obs; // Default Jakarta
  var addressText = 'Mencari alamat...'.obs;
  var isGeocoding = false.obs;

  @override
  void onInit() {
    super.onInit();
    getUserLocation();
  }

  Future<void> getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      selectedLatLng.value = LatLng(pos.latitude, pos.longitude);
      mapController.move(selectedLatLng.value, 15.0);
      reverseGeocode();
    } catch (_) {
      reverseGeocode();
    }
  }

  void updateLocation(LatLng latLng) {
    selectedLatLng.value = latLng;
    reverseGeocode();
  }

  Future<void> reverseGeocode() async {
    try {
      isGeocoding.value = true;
      List<Placemark> placemarks = await placemarkFromCoordinates(
        selectedLatLng.value.latitude,
        selectedLatLng.value.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subLocality != null && place.subLocality!.isNotEmpty) place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty) place.locality,
          if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) place.subAdministrativeArea,
        ];
        addressText.value = parts.join(', ');
      } else {
        addressText.value = 'Lat: ${selectedLatLng.value.latitude.toStringAsFixed(4)}, Lng: ${selectedLatLng.value.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      addressText.value = 'Lat: ${selectedLatLng.value.latitude.toStringAsFixed(4)}, Lng: ${selectedLatLng.value.longitude.toStringAsFixed(4)}';
    } finally {
      isGeocoding.value = false;
    }
  }

  void confirmLocation() {
    Get.back(result: {
      'address': addressText.value,
      'latitude': selectedLatLng.value.latitude,
      'longitude': selectedLatLng.value.longitude,
    });
  }
}
