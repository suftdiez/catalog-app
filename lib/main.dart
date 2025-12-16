import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// --- IMPORT PACKAGE BARU (BAB 4.2) ---
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

// =======================================================
// BAGIAN 1: DATA MODEL
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

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['title'] ?? json['name'] ?? 'Tanpa Nama',
      price: json['price'].toString().contains("Rp")
          ? json['price']
          : "Rp ${(double.parse(json['price'].toString()) * 15000).toInt()}",
      category: json['category'] ?? 'Elektronik',
      condition: json['condition'] ?? 'Baru',
      description: json['description'] ?? '-',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
    );
  }

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
// BAGIAN 2: UTAMA APLIKASI
// =======================================================

Future<void> main() async {
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
      home: isLoggedIn ? const LandingPage() : const LoginPage(),
    );
  }
}

// =======================================================
// BAGIAN 3: HALAMAN LOGIN
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('username', _emailController.text);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingPage()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login Berhasil!"), backgroundColor: Colors.green));
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
                  validator: (value) => (value == null || !value.contains('@')) ? 'Email tidak valid' : null,
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
// BAGIAN 4: HALAMAN DEPAN (Update: Carousel Slider)
// =======================================================

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  String _username = "Pengguna";

  // List gambar banner (URL placeholder)
  final List<String> imgList = [
    'https://img.freepik.com/free-vector/flat-horizontal-banner-template-black-friday-sales_23-2150867493.jpg',
    'https://img.freepik.com/free-psd/black-friday-super-sale-social-media-banner-template_120329-2128.jpg',
    'https://img.freepik.com/free-vector/cyber-monday-sale-banner-template_23-2148747625.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? "Pengguna";
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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
      body: SingleChildScrollView( // Pakai SingleChildScrollView agar tidak overflow
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- IMPLEMENTASI PACKAGE 1: CAROUSEL SLIDER ---
            CarouselSlider(
              options: CarouselOptions(
                height: 180.0,
                autoPlay: true, // Gambar gerak sendiri
                enlargeCenterPage: true,
                aspectRatio: 16/9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                viewportFraction: 0.8,
              ),
              items: imgList.map((item) => Container(
                margin: const EdgeInsets.all(5.0),
                child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                    child: Image.network(item, fit: BoxFit.cover, width: 1000.0)
                ),
              )).toList(),
            ),
            // -----------------------------------------------

            const SizedBox(height: 20),
            const Text("Selamat Datang", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Halo, $_username!", style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text("Temukan gadget impianmu di sini.", style: TextStyle(color: Colors.grey, fontSize: 16)),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ProfileCard(name: _username, role: "Member Gold"),
            ),

            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
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
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// WIDGET PROFILE CARD (Update: URL Launcher)
// =======================================================

class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  const ProfileCard({super.key, required this.name, required this.role});

  // --- IMPLEMENTASI PACKAGE 2: URL LAUNCHER ---
  Future<void> _launchURL() async {
    // Ganti URL ini dengan link apa saja (Web / WA)
    final Uri url = Uri.parse('https://flutter.dev');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
  // --------------------------------------------

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
      child: Column( // Ubah ke Column agar tombol ada di bawah
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 25, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, color: Colors.white)),
              const SizedBox(width: 15),
              Expanded(
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
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: OutlinedButton.icon(
              onPressed: _launchURL, // Panggil fungsi buka link
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text("Hubungi CS (Web)"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// =======================================================
// BAGIAN 5: KATALOG (Sama seperti sebelumnya)
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
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? localData = prefs.getString('products_data');

    if (localData != null && localData.isNotEmpty) {
      List<dynamic> jsonList = jsonDecode(localData);
      setState(() {
        productList = jsonList.map((e) => Product.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      await fetchProductsFromApi();
    }
  }

  Future<void> fetchProductsFromApi() async {
    try {
      final response = await http.get(Uri.parse('https://fakestoreapi.com/products/category/electronics'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<Product> fetchedProducts = data.map((json) => Product.fromJson(json)).toList();
        setState(() { productList = fetchedProducts; isLoading = false; });
        _saveToLocal();
      } else { throw Exception('Gagal load data'); }
    } catch (e) { setState(() => isLoading = false); }
  }

  Future<void> _saveToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(productList.map((p) => p.toJson()).toList());
    await prefs.setString('products_data', jsonString);
  }

  void _addProduct(Product newProduct) {
    setState(() { productList.add(newProduct); });
    _saveToLocal();
  }

  void _removeProduct(int index) {
    setState(() { productList.removeAt(index); });
    _saveToLocal();
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk ditambahkan!"), backgroundColor: Colors.green));
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
            key: Key(product.name + index.toString()),
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
// BAGIAN 6: FORM TAMBAH PRODUK (Sama)
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