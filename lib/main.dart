import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Wajib Bab 5
import 'package:shared_preferences/shared_preferences.dart'; // Wajib Bab 4
import 'package:carousel_slider/carousel_slider.dart'; // Wajib Bab 4.2
import 'package:url_launcher/url_launcher.dart'; // Wajib Bab 4.2
import 'providers/product_provider.dart'; // File Provider yang baru dibuat

// =======================================================
// BAGIAN 1: DATA MODEL & FORMATTER
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
      'name': name, 'price': price, 'category': category,
      'condition': condition, 'description': description, 'imageUrl': imageUrl,
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
// BAGIAN 2: UTAMA APLIKASI (SETUP PROVIDER)
// =======================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: MyGadgetApp(isLoggedIn: isLoggedIn),
    ),
  );
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
// BAGIAN 3: HALAMAN LOGIN (FITUR LAMA: PERSISTENT)
// =======================================================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
                  validator: (value) => (value == null || value.length < 6) ? 'Min 6 karakter' : null,
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
// BAGIAN 4: LANDING PAGE (FITUR LAMA: SLIDER & PROFILE)
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
          // FITUR BARU BAB 5: TOMBOL ABOUT
          IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: "Tentang Aplikasi",
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutPage()));
              }
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout), tooltip: "Logout"),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // FITUR BAB 4.2: CAROUSEL SLIDER (DIPERTAHANKAN)
            CarouselSlider(
              options: CarouselOptions(
                height: 180.0,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16/9,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
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

            const SizedBox(height: 20),
            const Text("Selamat Datang", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Halo, $_username!", style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            const Text("Temukan gadget impianmu di sini.", style: TextStyle(color: Colors.grey, fontSize: 16)),

            const SizedBox(height: 30),
            // FITUR LAMA: PROFILE CARD
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

// WIDGET PROFILE CARD (DIPERTAHANKAN)
class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  const ProfileCard({super.key, required this.name, required this.role});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://flutter.dev');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

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
      child: Column(
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
              onPressed: _launchURL,
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
// BAGIAN 5: KATALOG (FITUR BARU: SEARCH & PROVIDER)
// =======================================================
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  @override
  void initState() {
    super.initState();
    // Memanggil fungsi loadData dari Provider saat halaman dibuka
    Provider.of<ProductProvider>(context, listen: false).loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Katalog Produk")),
      body: Column(
        children: [
          // --- FITUR SEARCH (PENCARIAN) ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Cari Gadget...",
                hintText: "Contoh: Monitor",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                // LOGIKA SEARCH DARI PROVIDER
                Provider.of<ProductProvider>(context, listen: false).search(value);
              },
            ),
          ),

          // --- LIST PRODUK (DARI PROVIDER) ---
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.products.isEmpty) {
                  return const Center(child: Text("Produk tidak ditemukan / Kosong"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return Dismissible(
                      key: Key(product.name + index.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      confirmDismiss: (direction) async {
                        return await showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Hapus?"), actions: [TextButton(onPressed: ()=>Navigator.pop(c,false), child:const Text("Batal")), TextButton(onPressed: ()=>Navigator.pop(c,true), child:const Text("Hapus",style: TextStyle(color:Colors.red)))]));
                      },
                      onDismissed: (_) => provider.removeProduct(product),

                      // KARTU PRODUK
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        elevation: 3,
                        child: ListTile(
                          leading: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: Image.network(product.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.error)),
                          ),
                          title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${product.category} • ${product.price}"),
                          isThreeLine: true,
                          onTap: () {
                            // --- FITUR BARU: NAVIGASI KE DETAIL ---
                            Navigator.push(context, MaterialPageRoute(builder: (context) => DetailPage(product: product)));
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddProductPage()));
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// =======================================================
// BAGIAN 6: FORM TAMBAH PRODUK (DIPERTAHANKAN)
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
  String _selectedCategory = "Smartphone";
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
              onChanged: (v) => setState(() => _selectedCategory = v.toString()),
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
                    category: _selectedCategory,
                    condition: _selectedCondition,
                    description: _descController.text,
                  );
                  // PANGGIL PROVIDER UNTUK SIMPAN DATA
                  Provider.of<ProductProvider>(context, listen: false).addProduct(newProduct);
                  Navigator.pop(context);
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

// =======================================================
// BAGIAN 7: DETAIL PAGE (FITUR BARU BAB 5)
// =======================================================
class DetailPage extends StatelessWidget {
  final Product product;
  const DetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 250,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Image.network(product.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 100)),
              ),
            ),
            const SizedBox(height: 20),
            Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(product.price, style: const TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              children: [
                Chip(label: Text(product.category), backgroundColor: Colors.blue.shade100),
                const SizedBox(width: 10),
                Chip(label: Text(product.condition), backgroundColor: Colors.green.shade100),
              ],
            ),
            const Divider(height: 30),
            const Text("Deskripsi Produk:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(product.description, style: const TextStyle(fontSize: 16, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// BAGIAN 8: ABOUT PAGE (FITUR BARU BAB 5)
// =======================================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Aplikasi")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircleAvatar(radius: 60, backgroundColor: Colors.blueAccent, child: Icon(Icons.code, size: 60, color: Colors.white)),
              SizedBox(height: 20),
              Text("MyGadget Store v1.0", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Aplikasi Katalog Toko Elektronik", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 30),
              Divider(),
              SizedBox(height: 20),
              Text("Developed by:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Fajri Maulana Yusuf", style: TextStyle(fontSize: 18)),
              SizedBox(height: 30),
              Text("Teknologi:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Flutter • Provider • REST API • SharedPrefs"),
            ],
          ),
        ),
      ),
    );
  }
}