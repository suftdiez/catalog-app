import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- BAGIAN 1: DATA MODEL ---
class Product {
  final String name;
  final String price;
  final String category;
  final String description;
  final String imageUrl;

  Product({
    required this.name,
    required this.price,
    required this.category,
    required this.description,
    this.imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/1/14/Product_sample_icon_picture.png',
  });
}

// --- BAGIAN 2: LOGIC FORMAT RUPIAH ---
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

// --- BAGIAN 3: UTAMA APLIKASI ---
void main() {
  runApp(const MyGadgetApp());
}

class MyGadgetApp extends StatelessWidget {
  const MyGadgetApp({super.key});

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
      home: const LandingPage(),
    );
  }
}

// --- BAGIAN 4: HALAMAN DEPAN (LANDING PAGE) ---
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.devices, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text(
                "MyGadget Store",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "Temukan gadget impianmu di sini.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 40),

              // --- TAMBAHAN BAB 1: PROFILE CARD ---
              // Memenuhi syarat: Custom Stateless Widget, Row, Container Styling
              const ProfileCard(
                name: "Nama Mahasiswa", // GANTI DENGAN NAMAMU
                role: "App Developer",
              ),
              // ------------------------------------

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CatalogPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Masuk ke Katalog", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET PROFILE CARD (SYARAT BAB 1) ---
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
        borderRadius: BorderRadius.circular(15), // Styling: Rounded Corner
        border: Border.all(color: Colors.blue.withOpacity(0.2)), // Styling: Border
        boxShadow: [ // Styling: Shadow
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row( // Layout: Row (Horizontal)
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column( // Layout: Column (Vertikal) inside Row
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// --- BAGIAN 5: HALAMAN KATALOG ---
class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  List<Product> productList = [
    Product(name: "MacBook Air M2", price: "Rp 18.999.000", category: "Laptop", description: "Chip M2 super cepat."),
    Product(name: "iPhone 15 Pro", price: "Rp 20.999.000", category: "Smartphone", description: "Titanium design."),
    Product(name: "Sony WH-1000XM5", price: "Rp 5.999.000", category: "Aksesoris", description: "Headphone noise cancelling."),
  ];

  void _addProduct(Product newProduct) {
    setState(() {
      productList.add(newProduct);
    });
  }

  // Fungsi Hapus Data (Untuk Swipe to Dismiss)
  void _removeProduct(int index) {
    setState(() {
      productList.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Produk dihapus dari list")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Katalog Produk")),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductPage()),
          );
          if (result != null && result is Product) {
            _addProduct(result);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Produk berhasil ditambahkan!"), backgroundColor: Colors.green),
            );
          }
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: productList.isEmpty
          ? const Center(child: Text("Belum ada produk"))
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: productList.length,
        itemBuilder: (context, index) {
          final product = productList[index];

          // --- TAMBAHAN BAB 2: SWIPE TO DISMISS ---
          // Memenuhi syarat: Mengimplementasikan Swipe to Dismiss pada item ListView
          return Dismissible(
            key: Key(product.name + index.toString()), // Key unik
            direction: DismissDirection.endToStart, // Geser Kanan ke Kiri
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _removeProduct(index);
            },
            // ----------------------------------------

            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                      product.category == "Laptop" ? Icons.computer :
                      product.category == "Smartphone" ? Icons.smartphone : Icons.headphones,
                      color: Colors.blueAccent, size: 30
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      product.price,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- BAGIAN 6: FORM INPUT (TIDAK ADA PERUBAHAN) ---
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
              decoration: const InputDecoration(labelText: "Nama Produk", hintText: "Contoh: Xiaomi 14", prefixIcon: Icon(Icons.edit)),
              validator: (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Kategori Produk", prefixIcon: Icon(Icons.category)),
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Pilih salah satu kategori' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: "Harga (Rp)", hintText: "Contoh: 5.000.000", prefixIcon: Icon(Icons.attach_money), prefixText: "Rp "),
              validator: (v) => v!.isEmpty ? 'Harga wajib diisi' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Deskripsi Singkat", prefixIcon: Icon(Icons.description)),
              validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null,
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final newProduct = Product(
                      name: _nameController.text,
                      price: "Rp ${_priceController.text}",
                      category: _selectedCategory!,
                      description: _descController.text,
                    );
                    Navigator.pop(context, newProduct);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Simpan Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}