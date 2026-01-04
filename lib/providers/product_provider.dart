import 'mqtt_service.dart'; // Sesuaikan path-nya
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Import main.dart agar "class Product" terbaca
import '../main.dart';

class ProductProvider with ChangeNotifier {
  // --- VARIABEL UTAMA (STATE) ---
  List<Product> _allProducts = [];      // Menyimpan data asli dari API/Lokal
  List<Product> _filteredProducts = []; // Menyimpan data yang sedang ditampilkan (hasil search)
  bool _isLoading = false;              // Status loading
  String _currentCategory = 'Semua';    // Filter kategori aktif
  String _currentSort = 'default';      // Sort aktif

  // --- GETTER (Agar UI bisa baca data) ---
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String get currentCategory => _currentCategory;
  String get currentSort => _currentSort;

  // Daftar kategori yang tersedia
  List<String> get categories => ['Semua', 'Smartphone', 'Laptop', 'Tablet', 'Aksesoris', 'electronics', 'Lainnya'];

  // --- FUNGSI 1: CARI BARANG (SEARCH) ---
  void search(String query) {
    if (query.isEmpty) {
      _applyFiltersAndSort();
    } else {
      _filteredProducts = _allProducts.where((product) {
        bool matchesSearch = product.name.toLowerCase().contains(query.toLowerCase());
        bool matchesCategory = _currentCategory == 'Semua' || product.category == _currentCategory;
        return matchesSearch && matchesCategory;
      }).toList();
      _applySortOnly();
    }
    notifyListeners();
  }

  // --- FUNGSI 2: FILTER BY CATEGORY ---
  void filterByCategory(String category) {
    _currentCategory = category;
    _applyFiltersAndSort();
    notifyListeners();
  }

  // --- FUNGSI 3: SORT PRODUCTS ---
  void sortProducts(String sortType) {
    _currentSort = sortType;
    _applySortOnly();
    notifyListeners();
  }

  // --- FUNGSI HELPER: Apply filters and sort ---
  void _applyFiltersAndSort() {
    if (_currentCategory == 'Semua') {
      _filteredProducts = List.from(_allProducts);
    } else {
      _filteredProducts = _allProducts.where((p) => p.category == _currentCategory).toList();
    }
    _applySortOnly();
  }

  // --- FUNGSI HELPER: Apply sort only ---
  void _applySortOnly() {
    switch (_currentSort) {
      case 'price_asc':
        _filteredProducts.sort((a, b) {
          int priceA = int.tryParse(a.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          int priceB = int.tryParse(b.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_desc':
        _filteredProducts.sort((a, b) {
          int priceA = int.tryParse(a.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          int priceB = int.tryParse(b.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'name_asc':
        _filteredProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      default:
        // Default: no sorting
        break;
    }
  }

  // --- FUNGSI 4: RESET FILTERS ---
  void resetFilters() {
    _currentCategory = 'Semua';
    _currentSort = 'default';
    _filteredProducts = List.from(_allProducts);
    notifyListeners();
  }

  // --- FUNGSI 5: LOAD DATA AWAL ---
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners(); // Tampilkan loading muter-muter

    final prefs = await SharedPreferences.getInstance();
    final String? localData = prefs.getString('products_data');

    if (localData != null && localData.isNotEmpty) {
      // Prioritas 1: Ambil dari Memory HP (Offline)
      List<dynamic> jsonList = jsonDecode(localData);
      _allProducts = jsonList.map((e) => Product.fromJson(e)).toList();
      _filteredProducts = _allProducts;
      _isLoading = false;
      notifyListeners();
    } else {
      // Prioritas 2: Ambil dari Internet (Online)
      await fetchFromApi();
    }
  }

  // --- FUNGSI 6: AMBIL DARI API ---
  Future<void> fetchFromApi() async {
    try {
      final response = await http.get(Uri.parse('https://fakestoreapi.com/products/category/electronics'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _allProducts = data.map((json) => Product.fromJson(json)).toList();
        _filteredProducts = _allProducts;
        _saveToLocal(); // Langsung simpan biar besok gak perlu download lagi
      }
    } catch (e) {
      debugPrint("Error ambil data: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- FUNGSI 7: TAMBAH DATA ---
  void addProduct(Product product) {
    _allProducts.add(product);
    _applyFiltersAndSort();
    _saveToLocal();
    notifyListeners();
  }

  // --- FUNGSI 8: HAPUS DATA ---
  void removeProduct(Product product) {
    _allProducts.removeWhere((p) => p.id == product.id);
    _filteredProducts.removeWhere((p) => p.id == product.id);
    _saveToLocal();
    notifyListeners();
  }

  // --- FUNGSI 9: UPDATE/EDIT DATA ---
  void updateProduct(int productId, Product updatedProduct) {
    int index = _allProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _allProducts[index] = updatedProduct;
      _applyFiltersAndSort();
      _saveToLocal();
      notifyListeners();
    }
  }

  // --- FUNGSI 10: SIMPAN KE MEMORY HP ---
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List jadi Teks JSON agar bisa disimpan
    String jsonString = jsonEncode(_allProducts.map((p) => p.toJson()).toList());
    await prefs.setString('products_data', jsonString);
  }
}