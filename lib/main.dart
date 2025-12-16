import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert'; // Untuk encode/decode JSON
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // IMPORT WAJIB BAB 4

// =======================================================
// BAGIAN 1: DATA MODEL (Update: Tambah toJson)
// =======================================================

class Product {
  final String name;
  final String price;
  final String category;
  final String condition;
  final String description;
  final String imageUrl;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    this.imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/1/14/Product_sample_icon_picture.png',
  });

  // Digunakan untuk mengubah data JSON dari Internet/Local menjadi Object Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['title'] ?? json['name'] ?? 'Tanpa Nama', // Support key 'title' (API) atau 'name' (Lokal)
      price: json['price'].toString().contains("Rp")
          ? json['price'] // Jika sudah format Rupiah (Lokal)
          : "Rp ${(double.parse(json['price'].toString()) * 15000).toInt()}", // Jika dari API (Dolar)
      category: json['category'] ?? 'Elektronik',
      condition: json['condition'] ?? 'Baru',
      description: json['description'] ?? '-',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
    );
  }

  // SYARAT BAB 4: Method untuk mengubah Object Product menjadi JSON (agar bisa disimpan text-nya)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'category': category,
      'condition': condition,
      'description': description,
      'imageUrl': imageUrl,
    };
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    int value = int.parse(newText);
    newText = value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

// =======================================================
// BAGIAN 2: UTAMA APLIKASI (Cek Login di Awal)
// =======================================================

Future<void> main() async {
  // SYARAT BAB 4: Cek status login sebelum aplikasi jalan
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(MyGadgetApp(isLoggedIn: isLoggedIn));
}

class MyGadgetApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyGadgetApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyGadget Store',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
      // Jika sudah login, langsung ke LandingPage. Jika belum, ke LoginPage.
      home: isLoggedIn ? const LandingPage() : const LoginPage(),
    );
  }
}

// =======================================================
// BAGIAN 3: HALAMAN LOGIN (Simpan Data Login)
// =======================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      // SYARAT BAB 4: Simpan status login & username ke Memory HP
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _emailController.text); // Simpan email sebagai username

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingPage()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Berhasil & Data Disimpan!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.blueAccent),
                const SizedBox(height: 20),
                const Text("Silakan Login", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email), hintText: "contoh@email.com"),
                  validator: (value) => (value == null || !value.contains('@')) ? 'Email tidak valid (harus ada @)' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(Icons.lock)),
                  validator: (value) => (value == null || value.length < 6) ? 'Password minimal 6 karakter' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("MASUK", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// BAGIAN 4: HALAMAN DEPAN (Baca Data Username)
// =======================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String _username = "Pengguna"; // Default name

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  // SYARAT BAB 4: Ambil nama user yang tersimpan
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Pengguna";
    });
  }

  // Fungsi Logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Hapus semua data (login & list)
    // Atau prefs.remove('isLoggedIn'); jika ingin hapus login saja
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MyGadget Store"),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: "Logout"),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.devices, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text("Selamat Datang", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Katalog Gadget Online Terlengkap", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),

              // Tampilkan Username yang diambil dari Shared Preferences
              ProfileCard(name: _username, role: "App Developer"),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogPage()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("Lihat Katalog", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  const ProfileCard({super.key, required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 25, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded( // Pakai Expanded agar teks panjang tidak error
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// BAGIAN 5: KATALOG (Challenge: Simpan List Lokal)
// =======================================================

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Product> productList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Load data saat halaman dibuka
  }

  // LOGIKA UTAMA: Cek Lokal dulu, kalau kosong baru ambil API
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localData = prefs.getString('products_data');

    if (localData != null && localData.isNotEmpty) {
      // 1. Jika ada data lokal, pakai itu (Offline Mode)
      print("Mengambil data dari LOKAL");
      List<dynamic> jsonList = jsonDecode(localData);
      setState(() {
        productList = jsonList.map((e) => Product.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      // 2. Jika tidak ada, ambil dari API
      print("Mengambil data dari API");
      await fetchProductsFromApi();
    }
  }

  Future<void> fetchProductsFromApi() async {
    try {
      final response = await http.get(Uri.parse('https://fakestoreapi.com/products/category/electronics'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Product> fetchedProducts = data.map((json) => Product.fromJson(json)).toList();

        setState(() {
          productList = fetchedProducts;
          isLoading = false;
        });

        // Simpan hasil API ke lokal agar besok tidak perlu download lagi
        _saveToLocal();
      } else {
        throw Exception('Gagal load data');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error: $e");
    }
  }

  // Fungsi untuk menyimpan List ke Memory HP
  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List<Product> menjadi JSON String
    String jsonString = jsonEncode(productList.map((p) => p.toJson()).toList());
    await prefs.setString('products_data', jsonString);
    print("Data berhasil disimpan ke LOKAL");
  }

  void _addProduct(Product newProduct) {
    setState(() {
      productList.add(newProduct);
    });
    _saveToLocal(); // Simpan otomatis setiap tambah data
  }

  void _removeProduct(int index) {
    setState(() {
      productList.removeAt(index);
    });
    _saveToLocal(); // Simpan otomatis setiap hapus data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Katalog Produk")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
          if (result != null && result is Product) {
            _addProduct(result);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk ditambahkan & Disimpan!"), backgroundColor: Colors.green));
          }
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : productList.isEmpty
          ? const Center(child: Text("Data Kosong"))
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: productList.length,
        itemBuilder: (context, index) {
          final product = productList[index];
          return Dismissible(
            key: Key(product.name + index.toString()), // Key unik
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Hapus Produk?"),
                  content: Text("Yakin ingin menghapus ${product.name}?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (_) => _removeProduct(index),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 3,
              child: ListTile(
                leading: Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: product.imageUrl.isNotEmpty
                      ? Image.network(product.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.error))
                      : const Icon(Icons.devices),
                ),
                title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${product.category} • ${product.condition}\n${product.price}"),
                isThreeLine: true,
              ),
            ),
          );
        },
      ),
    );
  }
}

// =======================================================
// BAGIAN 6: FORM TAMBAH PRODUK
// =======================================================

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});
  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategory;
  String _selectedCondition = "Baru";
  final List<String> _categories = ["Smartphone", "Laptop", "Tablet", "Aksesoris", "Lainnya"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Produk Baru")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Produk", prefixIcon: Icon(Icons.edit)),
              validator: (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Kategori", prefixIcon: Icon(Icons.category)),
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Pilih kategori' : null,
            ),
            const SizedBox(height: 15),
            Row(children: [
              const Text("Kondisi: ", style: TextStyle(fontWeight: FontWeight.bold)),
              Radio(value: "Baru", groupValue: _selectedCondition, onChanged: (v) => setState(() => _selectedCondition = v.toString())),
              const Text("Baru"),
              Radio(value: "Bekas", groupValue: _selectedCondition, onChanged: (v) => setState(() => _selectedCondition = v.toString())),
              const Text("Bekas"),
            ]),
            const SizedBox(height: 15),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: "Harga", prefixIcon: Icon(Icons.attach_money), prefixText: "Rp "),
              validator: (value) => value!.isEmpty ? 'Harga wajib diisi' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: "Deskripsi", prefixIcon: Icon(Icons.description)),
              validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final newProduct = Product(
                    name: _nameController.text,
                    price: "Rp ${_priceController.text}",
                    category: _selectedCategory!,
                    condition: _selectedCondition,
                    description: _descController.text,
                  );
                  Navigator.pop(context, newProduct);
                }
              },
              child: const Text("Simpan Produk"),
            ),
          ],
        ),
      ),
    );
  }
}