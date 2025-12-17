import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// =======================================================
// WISHLIST PROVIDER (STATE MANAGEMENT)
// =======================================================
class WishlistProvider with ChangeNotifier {
  List<Product> _wishlist = [];

  List<Product> get wishlist => _wishlist;
  int get itemCount => _wishlist.length;

  WishlistProvider() {
    _loadFromLocal();
  }

  // Cek apakah produk ada di wishlist
  bool isInWishlist(int productId) {
    return _wishlist.any((p) => p.id == productId);
  }

  // Toggle wishlist (tambah jika belum ada, hapus jika sudah ada)
  void toggleWishlist(Product product) {
    if (isInWishlist(product.id)) {
      removeFromWishlist(product);
    } else {
      addToWishlist(product);
    }
  }

  // Tambah ke wishlist
  void addToWishlist(Product product) {
    if (!isInWishlist(product.id)) {
      _wishlist.add(product);
      _saveToLocal();
      notifyListeners();
    }
  }

  // Hapus dari wishlist
  void removeFromWishlist(Product product) {
    _wishlist.removeWhere((p) => p.id == product.id);
    _saveToLocal();
    notifyListeners();
  }

  // Kosongkan wishlist
  void clearWishlist() {
    _wishlist.clear();
    _saveToLocal();
    notifyListeners();
  }

  // Simpan ke local storage
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_wishlist.map((p) => p.toJson()).toList());
    await prefs.setString('wishlist_data', jsonString);
  }

  // Load dari local storage
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('wishlist_data');
    if (data != null && data.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(data);
      _wishlist = jsonList.map((e) => Product.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
