import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- BAGIAN 1: DATA MODEL ---
class Product {
  final String name;
  final String price;
  final String category;
  final String condition; // FIELD BARU: Kondisi Barang (Baru/Bekas)
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

// --- BAGIAN 4: HALAMAN DEPAN ---
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
              const Text("MyGadget Store", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Temukan gadget impianmu di sini.", style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              const ProfileCard(name: "Nama Mahasiswa", role: "App Developer"),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CatalogPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

// WIDGET PROFILE CARD
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
          Column(
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
    Product(name: "MacBook Air M2", price: "Rp 18.999.000", category: "Laptop", condition: "Baru", description: "Chip M2 super cepat."),
    Product(name: "iPhone 15 Pro", price: "Rp 20.999.000", category: "Smartphone", condition: "Baru", description: "Titanium design."),
  ];

  void _addProduct(Product newProduct) {
    setState(() { productList.add(newProduct); });
  }

  void _removeProduct(int index) {
    setState(() { productList.removeAt(index); });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk dihapus")));
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
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Produk berhasil ditambahkan!"), backgroundColor: Colors.green));
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
          return Dismissible(
            key: Key(product.name + index.toString()),
            direction: DismissDirection.endToStart,
            // INTERAKSI: Dialog Konfirmasi Hapus (Materi Bab 3)
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Konfirmasi"),
                    content: const Text("Yakin ingin menghapus produk ini?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Batal")),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Hapus", style: TextStyle(color: Colors.red))),
                    ],
                  );
                },
              );
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) { _removeProduct(index); },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(15),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                      product.category == "Laptop" ? Icons.computer : product.category == "Smartphone" ? Icons.smartphone : Icons.headphones,
                      color: Colors.blueAccent, size: 30),
                ),
                title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        // Badge Kategori
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(5)),
                          child: Text(product.category, style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 5),
                        // Badge Kondisi (BARU!)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: product.condition == "Baru" ? Colors.green.shade100 : Colors.grey.shade300, borderRadius: BorderRadius.circular(5)),
                          child: Text(product.condition, style: TextStyle(fontSize: 10, color: product.condition == "Baru" ? Colors.green.shade800 : Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(product.price, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- BAGIAN 6: FORM INPUT (MAX VERSION) ---
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

  // VARIABEL BARU: RADIO BUTTON
  String _selectedCondition = "Baru"; // Default pilih Baru

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

            // DROPDOWN (Poin 3.1)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Kategori Produk", prefixIcon: Icon(Icons.category)),
              value: _selectedCategory,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Pilih salah satu kategori' : null,
            ),
            const SizedBox(height: 15),

            // RADIO BUTTON: KONDISI BARANG (Fitur Maksimal Bab 3!)
            const Text("Kondisi Barang:", style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Baru"),
                    value: "Baru",
                    groupValue: _selectedCondition,
                    onChanged: (value) => setState(() => _selectedCondition = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text("Bekas"),
                    value: "Bekas",
                    groupValue: _selectedCondition,
                    onChanged: (value) => setState(() => _selectedCondition = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
              decoration: const InputDecoration(labelText: "Harga (Rp)", hintText: "Contoh: 5.000.000", prefixIcon: Icon(Icons.attach_money), prefixText: "Rp "),
              validator: (value) => value!.isEmpty ? 'Harga wajib diisi' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Deskripsi Singkat", prefixIcon: Icon(Icons.description)),
              validator: (value) => value!.isEmpty ? 'Deskripsi wajib diisi' : null,
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
                      condition: _selectedCondition, // Kirim data kondisi
                      description: _descController.text,
                    );
                    Navigator.pop(context, newProduct);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("Simpan Produk", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}