import 'mqtt_service.dart'; // Sesuaikan path-nya
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

// =======================================================
// CART ITEM MODEL
// =======================================================
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product']),
    quantity: json['quantity'] ?? 1,
  );
}

// =======================================================
// CART PROVIDER (STATE MANAGEMENT)
// =======================================================
class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;
  
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  
  int get totalPrice {
    int total = 0;
    for (var item in _cartItems) {
      // Extract angka dari string harga "Rp 150.000"
      String priceStr = item.product.price.replaceAll(RegExp(r'[^0-9]'), '');
      int price = int.tryParse(priceStr) ?? 0;
      total += price * item.quantity;
    }
    return total;
  }

  // Format total price to Rupiah string
  String get formattedTotal {
    String total = totalPrice.toString();
    String formatted = total.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  CartProvider() {
    _loadFromLocal();
  }

  // --- TAMBAH KE KERANJANG ---
  void addToCart(Product product) {
    int index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      // Produk sudah ada, tambah quantity
      _cartItems[index].quantity++;
    } else {
      // Produk baru, tambahkan ke cart
      _cartItems.add(CartItem(product: product));
    }
    _saveToLocal();
    notifyListeners();
  }

  // --- HAPUS DARI KERANJANG ---
  void removeFromCart(Product product) {
    _cartItems.removeWhere((item) => item.product.id == product.id);
    _saveToLocal();
    notifyListeners();
  }

  // --- UPDATE QUANTITY ---
  void updateQuantity(int productId, int quantity) {
    int index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      _saveToLocal();
      notifyListeners();
    }
  }

  // --- KOSONGKAN KERANJANG ---
  void clearCart() {
    _cartItems.clear();
    _saveToLocal();
    notifyListeners();
  }

  // --- SIMPAN KE LOCAL STORAGE ---
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(_cartItems.map((item) => item.toJson()).toList());
    await prefs.setString('cart_data', jsonString);
  }

  // --- LOAD DARI LOCAL STORAGE ---
  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartData = prefs.getString('cart_data');
    if (cartData != null && cartData.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(cartData);
      _cartItems = jsonList.map((e) => CartItem.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
