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

  // --- GETTER (Agar UI bisa baca data) ---
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;

  // --- FUNGSI 1: CARI BARANG (SEARCH) ---
  void search(String query) {
    if (query.isEmpty) {
      _filteredProducts = _allProducts; // Kalau search kosong, tampilkan semua
    } else {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners(); // Kabari UI: "Woy, data berubah nih, update layar dong!"
  }

  // --- FUNGSI 2: LOAD DATA AWAL ---
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

  // --- FUNGSI 3: AMBIL DARI API ---
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
      print("Error ambil data: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- FUNGSI 4: TAMBAH DATA ---
  void addProduct(Product product) {
    _allProducts.add(product);
    _filteredProducts = _allProducts; // Reset search
    _saveToLocal();
    notifyListeners();
  }

  // --- FUNGSI 5: HAPUS DATA ---
  void removeProduct(Product product) {
    _allProducts.remove(product);
    _filteredProducts.remove(product); // Hapus juga dari tampilan search
    _saveToLocal();
    notifyListeners();
  }

  // --- FUNGSI 6: SIMPAN KE MEMORY HP ---
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List jadi Teks JSON agar bisa disimpan
    String jsonString = jsonEncode(_allProducts.map((p) => p.toJson()).toList());
    await prefs.setString('products_data', jsonString);
  }
}