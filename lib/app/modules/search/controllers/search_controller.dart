import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/providers/api_provider.dart';

class SearchController extends GetxController {
  final ApiProvider _apiProvider = ApiProvider();

  final searchController = TextEditingController();
  var products = [].obs;
  var isLoading = false.obs;

  // Filters State
  var searchQuery = ''.obs;
  var selectedBrand = 'Semua'.obs;
  var sortBy = 'Default'.obs; // Default, Termurah, Termahal

  List<String> get brandsList {
    final list = <String>['Semua'];
    for (var p in products) {
      final brand = p['brand']?.toString();
      if (brand != null && brand.isNotEmpty && !list.contains(brand)) {
        list.add(brand);
      }
    }
    return list;
  }

  List<dynamic> get filteredProducts {
    var list = List.from(products);

    // 1. Search Query Filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final brand = (p['brand'] ?? '').toString().toLowerCase();
        final desc = (p['description'] ?? '').toString().toLowerCase();
        return name.contains(query) || brand.contains(query) || desc.contains(query);
      }).toList();
    }

    // 2. Brand Filter
    if (selectedBrand.value != 'Semua') {
      list = list.where((p) => p['brand'] == selectedBrand.value).toList();
    }

    // 3. Sorting
    if (sortBy.value == 'Termurah') {
      list.sort((a, b) {
        final aPrice = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
        final bPrice = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
        return aPrice.compareTo(bPrice);
      });
    } else if (sortBy.value == 'Termahal') {
      list.sort((a, b) {
        final aPrice = double.tryParse(a['price']?.toString() ?? '0') ?? 0.0;
        final bPrice = double.tryParse(b['price']?.toString() ?? '0') ?? 0.0;
        return bPrice.compareTo(aPrice);
      });
    }

    return list;
  }

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    searchController.addListener(() {
      searchQuery.value = searchController.text;
    });
  }

  Future<void> loadProducts() async {
    try {
      isLoading.value = true;
      final list = await _apiProvider.getProducts();
      products.value = list;
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void resetFilters() {
    searchController.clear();
    searchQuery.value = '';
    selectedBrand.value = 'Semua';
    sortBy.value = 'Default';
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
