import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Wajib Bab 5
import 'package:shared_preferences/shared_preferences.dart'; // Wajib Bab 4
import 'package:carousel_slider/carousel_slider.dart'; // Wajib Bab 4.2
import 'package:url_launcher/url_launcher.dart'; // Wajib Bab 4.2
import 'package:image_picker/image_picker.dart'; // Image Picker
import 'providers/product_provider.dart'; // File Provider yang baru dibuat
import 'providers/cart_provider.dart'; // Cart Provider untuk keranjang belanja
import 'providers/wishlist_provider.dart'; // Wishlist Provider
import 'providers/theme_provider.dart'; // Theme Provider untuk Dark Mode
import 'providers/user_provider.dart'; // User Provider untuk profil

// =======================================================
// BAGIAN 1: DATA MODEL & FORMATTER
// =======================================================
class Product {
  final int id;
  final String name;
  final String price;
  final String category;
  final String condition;
  final String description;
  final String imageUrl;
  final double rating;
  final int ratingCount;

  Product({
    int? id,
    required this.name,
    required this.price,
    required this.category,
    required this.condition,
    required this.description,
    this.imageUrl = 'https://upload.wikimedia.org/wikipedia/commons/1/14/Product_sample_icon_picture.png',
    this.rating = 0.0,
    this.ratingCount = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] is int ? json['id'] : DateTime.now().millisecondsSinceEpoch,
      name: json['title'] ?? json['name'] ?? 'Tanpa Nama',
      price: json['price'].toString().contains("Rp")
          ? json['price']
          : "Rp ${(double.parse(json['price'].toString()) * 15000).toInt()}",
      category: json['category'] ?? 'Elektronik',
      condition: json['condition'] ?? 'Baru',
      description: json['description'] ?? '-',
      imageUrl: json['image'] ?? json['imageUrl'] ?? '',
      rating: (json['rating'] is Map) 
          ? (json['rating']['rate'] ?? 0.0).toDouble() 
          : (json['rating'] ?? 0.0).toDouble(),
      ratingCount: (json['rating'] is Map) 
          ? (json['rating']['count'] ?? 0) 
          : (json['ratingCount'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name, 'price': price, 'category': category,
      'condition': condition, 'description': description, 'imageUrl': imageUrl,
      'rating': rating, 'ratingCount': ratingCount,
    };
  }

  // Create copy with updated rating
  Product copyWithRating(double newRating, int newCount) {
    return Product(
      id: id,
      name: name,
      price: price,
      category: category,
      condition: condition,
      description: description,
      imageUrl: imageUrl,
      rating: newRating,
      ratingCount: newCount,
    );
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MyGadget Store',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: isLoggedIn ? const LandingPage() : const LoginPage(),
        );
      },
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

  // List gambar banner (Promo Gadget)
  final List<String> imgList = [
    'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&q=80', // Tech laptop setup
    'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=800&q=80', // Smartphone
    'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800&q=80', // MacBook
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
          // FITUR BARU: KERANJANG BELANJA
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: "Keranjang",
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // FITUR BAB 5: TOMBOL ABOUT
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

// WIDGET PROFILE CARD (UPDATED WITH PROFILE NAVIGATION)
class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  const ProfileCard({super.key, required this.name, required this.role});

  Future<void> _launchURL() async {
    final Uri url = Uri.parse('https://wa.me/6282223397728');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withAlpha(50)),
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(25), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          // Tappable profile row
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            borderRadius: BorderRadius.circular(10),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final profile = userProvider.profile;
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        profile.name.isNotEmpty ? profile.name[0].toUpperCase() : "P",
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(profile.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(profile.memberType, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 35,
            child: OutlinedButton.icon(
              onPressed: _launchURL,
              icon: const Icon(Icons.support_agent, size: 18),
              label: const Text("Hubungi CS (WA)"),
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
// BAGIAN 5: KATALOG (FITUR BARU: SEARCH, FILTER & SORT)
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
    Provider.of<ProductProvider>(context, listen: false).loadData();
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer<ProductProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Urutkan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  ListTile(
                    leading: const Icon(Icons.sort),
                    title: const Text("Default"),
                    trailing: provider.currentSort == 'default' ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () { provider.sortProducts('default'); Navigator.pop(ctx); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_upward),
                    title: const Text("Harga Terendah"),
                    trailing: provider.currentSort == 'price_asc' ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () { provider.sortProducts('price_asc'); Navigator.pop(ctx); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.arrow_downward),
                    title: const Text("Harga Tertinggi"),
                    trailing: provider.currentSort == 'price_desc' ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () { provider.sortProducts('price_desc'); Navigator.pop(ctx); },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sort_by_alpha),
                    title: const Text("Nama A-Z"),
                    trailing: provider.currentSort == 'name_asc' ? const Icon(Icons.check, color: Colors.blue) : null,
                    onTap: () { provider.sortProducts('name_asc'); Navigator.pop(ctx); },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Katalog Produk"),
        actions: [
          // Wishlist Button
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: "Wishlist",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage())),
          ),
          // Sort Button
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: "Urutkan",
            onPressed: () => _showSortOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: "Cari Gadget...",
                hintText: "Contoh: Monitor",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                Provider.of<ProductProvider>(context, listen: false).search(value);
              },
            ),
          ),

          // --- FILTER CHIPS ---
          Consumer<ProductProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: provider.categories.length,
                  itemBuilder: (context, index) {
                    final category = provider.categories[index];
                    final isSelected = provider.currentCategory == category;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => provider.filterByCategory(category),
                        selectedColor: Colors.blueAccent.shade100,
                        checkmarkColor: Colors.blue,
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // --- LIST PRODUK ---
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.products.isEmpty) {
                  return const Center(child: Text("Produk tidak ditemukan"));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: provider.products.length,
                  itemBuilder: (context, index) {
                    final product = provider.products[index];
                    return Dismissible(
                      key: Key(product.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                      confirmDismiss: (direction) async {
                        return await showDialog(context: context, builder: (c) => AlertDialog(title: const Text("Hapus?"), actions: [TextButton(onPressed: ()=>Navigator.pop(c,false), child:const Text("Batal")), TextButton(onPressed: ()=>Navigator.pop(c,true), child:const Text("Hapus",style: TextStyle(color:Colors.red)))]));
                      },
                      onDismissed: (_) => provider.removeProduct(product),
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
                          trailing: Consumer<WishlistProvider>(
                            builder: (context, wishlist, child) {
                              return IconButton(
                                icon: Icon(
                                  wishlist.isInWishlist(product.id) ? Icons.favorite : Icons.favorite_border,
                                  color: wishlist.isInWishlist(product.id) ? Colors.red : Colors.grey,
                                ),
                                onPressed: () => wishlist.toggleWishlist(product),
                              );
                            },
                          ),
                          onTap: () {
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
// BAGIAN 6: FORM TAMBAH PRODUK (WITH IMAGE PICKER)
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
  
  // Image picker
  String _imageUrl = '';
  String? _localImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
      if (image != null) {
        setState(() {
          _localImagePath = image.path;
          _imageUrl = '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showUrlInputDialog() {
    final urlController = TextEditingController(text: _imageUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("URL Gambar"),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: "https://example.com/image.jpg",
            prefixIcon: Icon(Icons.link),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _imageUrl = urlController.text;
                _localImagePath = null;
              });
              Navigator.pop(ctx);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Produk Baru")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Picker Section
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _localImagePath != null || _imageUrl.isNotEmpty
                  ? Stack(
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _localImagePath != null
                                ? Image.file(File(_localImagePath!), fit: BoxFit.contain, height: 170)
                                : Image.network(_imageUrl, fit: BoxFit.contain, height: 170, 
                                    errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 60)),
                          ),
                        ),
                        Positioned(
                          top: 5, right: 5,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() { _localImagePath = null; _imageUrl = ''; }),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text("Tambah Gambar Produk", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),
            const SizedBox(height: 10),
            
            // Image Picker Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Galeri"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showUrlInputDialog,
                    icon: const Icon(Icons.link),
                    label: const Text("URL"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
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
                  // Determine image URL to use
                  String finalImageUrl = _imageUrl.isNotEmpty 
                      ? _imageUrl 
                      : (_localImagePath != null 
                          ? 'file://$_localImagePath' 
                          : 'https://upload.wikimedia.org/wikipedia/commons/1/14/Product_sample_icon_picture.png');
                  
                  final newProduct = Product(
                    name: _nameController.text,
                    price: "Rp ${_priceController.text}",
                    category: _selectedCategory,
                    condition: _selectedCondition,
                    description: _descController.text,
                    imageUrl: finalImageUrl,
                  );
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
// BAGIAN 6.1: FORM EDIT PRODUK (FITUR BARU)
// =======================================================
class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});
  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late String _selectedCondition;
  final List<String> _categories = ["Smartphone", "Laptop", "Tablet", "Aksesoris", "Lainnya", "electronics"];

  @override
  void initState() {
    super.initState();
    // Pre-fill form dengan data produk yang ada
    _nameController = TextEditingController(text: widget.product.name);
    // Extract angka dari harga (hilangkan "Rp " dan titik)
    String priceNum = widget.product.price.replaceAll(RegExp(r'[^0-9]'), '');
    _priceController = TextEditingController(text: priceNum);
    _descController = TextEditingController(text: widget.product.description);
    _selectedCategory = _categories.contains(widget.product.category) 
        ? widget.product.category 
        : "Lainnya";
    _selectedCondition = widget.product.condition;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Produk")),
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
              maxLines: 3,
              validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final updatedProduct = Product(
                    id: widget.product.id, // Retain same ID
                    name: _nameController.text,
                    price: "Rp ${_priceController.text}",
                    category: _selectedCategory,
                    condition: _selectedCondition,
                    description: _descController.text,
                    imageUrl: widget.product.imageUrl, // Keep original image
                  );
                  Provider.of<ProductProvider>(context, listen: false)
                      .updateProduct(widget.product.id, updatedProduct);
                  Navigator.pop(context); // Back to detail
                  Navigator.pop(context); // Back to catalog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Produk berhasil diupdate!"), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
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
class DetailPage extends StatefulWidget {
  final Product product;
  const DetailPage({super.key, required this.product});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Product _product;
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
  }

  void _showRatingDialog() {
    int tempRating = _userRating;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Beri Rating"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Bagaimana penilaian Anda?"),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < tempRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () {
                        setDialogState(() => tempRating = index + 1);
                      },
                    );
                  }),
                ),
                Text("$tempRating / 5", style: const TextStyle(fontSize: 16)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
              ElevatedButton(
                onPressed: tempRating > 0 ? () {
                  // Calculate new rating
                  double newRating = ((_product.rating * _product.ratingCount) + tempRating) / (_product.ratingCount + 1);
                  int newCount = _product.ratingCount + 1;
                  
                  // Update product
                  Product updatedProduct = _product.copyWithRating(newRating, newCount);
                  Provider.of<ProductProvider>(context, listen: false).updateProduct(_product.id, updatedProduct);
                  
                  setState(() {
                    _product = updatedProduct;
                    _userRating = tempRating;
                  });
                  
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Terima kasih! Rating $tempRating bintang tersimpan."), backgroundColor: Colors.green),
                  );
                } : null,
                child: const Text("Kirim"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else if (index < rating) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              return IconButton(
                icon: Icon(
                  wishlist.isInWishlist(_product.id) ? Icons.favorite : Icons.favorite_border,
                  color: wishlist.isInWishlist(_product.id) ? Colors.red : Colors.white,
                ),
                onPressed: () => wishlist.toggleWishlist(_product),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Produk",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProductPage(product: _product)),
              );
            },
          ),
        ],
      ),
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
                child: Image.network(_product.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, size: 100)),
              ),
            ),
            const SizedBox(height: 20),
            Text(_product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Rating Display
            Row(
              children: [
                _buildStarRating(_product.rating),
                const SizedBox(width: 10),
                Text(
                  "${_product.rating.toStringAsFixed(1)} (${_product.ratingCount} ulasan)",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            Text(_product.price, style: const TextStyle(fontSize: 22, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              children: [
                Chip(label: Text(_product.category), backgroundColor: Colors.blue.shade100),
                const SizedBox(width: 10),
                Chip(label: Text(_product.condition), backgroundColor: Colors.green.shade100),
              ],
            ),
            const Divider(height: 30),
            const Text("Deskripsi Produk:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_product.description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 20),
            
            // Rating Button
            SizedBox(
              width: double.infinity,
              height: 45,
              child: OutlinedButton.icon(
                onPressed: _showRatingDialog,
                icon: Icon(_userRating > 0 ? Icons.star : Icons.star_border, color: Colors.amber),
                label: Text(_userRating > 0 ? "Rating Anda: $_userRating ⭐" : "Beri Rating"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade700,
                  side: BorderSide(color: Colors.amber.shade700),
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // Tombol Tambah ke Keranjang
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).addToCart(_product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${_product.name} ditambahkan ke keranjang!"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text("Tambah ke Keranjang", style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =======================================================
// BAGIAN 8: PROFILE PAGE (FITUR BARU)
// =======================================================
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Saya"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit Profil",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final profile = userProvider.profile;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar Section
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.blueAccent,
                  child: profile.avatarUrl.isNotEmpty
                      ? ClipOval(child: Image.network(profile.avatarUrl, fit: BoxFit.cover, width: 120, height: 120))
                      : Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : "P",
                          style: const TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 15),
                Text(profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(profile.email, style: const TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(profile.memberType, style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 30),
                
                // Info Cards
                _buildInfoCard(context, Icons.phone, "Telepon", profile.phone.isNotEmpty ? profile.phone : "Belum diisi"),
                _buildInfoCard(context, Icons.location_on, "Alamat", profile.address.isNotEmpty ? profile.address : "Belum diisi"),
                
                const SizedBox(height: 20),
                
                // Statistics Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Statistik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(),
                        Consumer<WishlistProvider>(
                          builder: (context, wishlist, child) {
                            return _buildStatRow(Icons.favorite, "Wishlist", "${wishlist.itemCount} produk");
                          },
                        ),
                        Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            return _buildStatRow(Icons.shopping_cart, "Keranjang", "${cart.itemCount} item");
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Edit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Profil", style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 10),
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// =======================================================
// BAGIAN 9: EDIT PROFILE PAGE
// =======================================================
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final profile = Provider.of<UserProvider>(context, listen: false).profile;
    _nameController = TextEditingController(text: profile.name);
    _phoneController = TextEditingController(text: profile.phone);
    _addressController = TextEditingController(text: profile.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentProfile = userProvider.profile;
      
      final updatedProfile = currentProfile.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
      );
      
      userProvider.updateProfile(updatedProfile);
      
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil berhasil diupdate!"), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar Preview
            Center(
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : "P",
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            
            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Nama Lengkap",
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Nama wajib diisi' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 15),
            
            // Phone Field
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "No. Telepon",
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: "Contoh: 081234567890",
              ),
            ),
            const SizedBox(height: 15),
            
            // Address Field
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Alamat Pengiriman",
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                hintText: "Masukkan alamat lengkap...",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 30),
            
            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Simpan Perubahan", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// BAGIAN 10: ABOUT PAGE (FITUR BARU BAB 5)
// =======================================================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang Aplikasi")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const CircleAvatar(radius: 60, backgroundColor: Colors.blueAccent, child: Icon(Icons.code, size: 60, color: Colors.white)),
              const SizedBox(height: 20),
              const Text("MyGadget Store v1.1", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Aplikasi Katalog Toko Elektronik", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              const Divider(),
              
              // --- DARK MODE TOGGLE ---
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: themeProvider.isDarkMode ? Colors.amber : Colors.blueAccent,
                      ),
                      title: const Text("Mode Gelap", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(themeProvider.isDarkMode ? "Aktif" : "Nonaktif"),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeColor: Colors.blueAccent,
                      ),
                    ),
                  );
                },
              ),
              
              const Divider(),
              const SizedBox(height: 20),
              const Text("Developed by:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Fajri Maulana Yusuf", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              const Text("Teknologi:", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Flutter • Provider • REST API • SharedPrefs"),
              const SizedBox(height: 30),
              
              // Features list
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Fitur Utama:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 10),
                      Text("✓ Katalog Produk dengan Filter & Sort"),
                      Text("✓ Keranjang Belanja"),
                      Text("✓ Wishlist / Favorit"),
                      Text("✓ Edit & Hapus Produk"),
                      Text("✓ Mode Gelap"),
                      Text("✓ Penyimpanan Lokal"),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =======================================================
// BAGIAN 9: WISHLIST PAGE (FITUR BARU)
// =======================================================
class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wishlist"),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlist, child) {
              if (wishlist.wishlist.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: "Hapus Semua",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Hapus Semua Wishlist?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
                        TextButton(
                          onPressed: () { wishlist.clearWishlist(); Navigator.pop(c); },
                          child: const Text("Hapus", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlist, child) {
          if (wishlist.wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text("Wishlist Kosong", style: TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text("Tap ❤️ pada produk untuk menambahkan", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: wishlist.wishlist.length,
            itemBuilder: (context, index) {
              final product = wishlist.wishlist[index];
              return Dismissible(
                key: Key(product.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => wishlist.removeFromWishlist(product),
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Image.network(product.imageUrl, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.error)),
                    ),
                    title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(product.price),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => wishlist.removeFromWishlist(product),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(product: product))),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// =======================================================
// BAGIAN 10: CART PAGE (KERANJANG BELANJA)
// =======================================================
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang Belanja"),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              if (cart.cartItems.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_forever),
                tooltip: "Kosongkan Keranjang",
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text("Kosongkan Keranjang?"),
                      content: const Text("Semua item akan dihapus dari keranjang."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Batal")),
                        TextButton(
                          onPressed: () {
                            cart.clearCart();
                            Navigator.pop(c);
                          },
                          child: const Text("Hapus Semua", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text("Keranjang Kosong", style: TextStyle(fontSize: 20, color: Colors.grey)),
                  const SizedBox(height: 10),
                  const Text("Tambahkan produk dari katalog", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Kembali"),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // List Cart Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: cart.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cart.cartItems[index];
                    return Dismissible(
                      key: Key(item.product.id.toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => cart.removeFromCart(item.product),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              // Gambar Produk
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Image.network(
                                  item.product.imageUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (c, e, s) => const Icon(Icons.image, size: 40),
                                ),
                              ),
                              const SizedBox(width: 15),
                              // Info Produk
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      item.product.price,
                                      style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
                                  ),
                                  Text(
                                    item.quantity.toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Total & Checkout Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(50),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total:", style: TextStyle(fontSize: 18)),
                        Text(
                          cart.formattedTotal,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showPaymentDialog(context, cart),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Checkout", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, CartProvider cart) {
    String? selectedMethod;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Pilih Metode Pembayaran", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // Payment Options
                _buildPaymentOption(
                  icon: Icons.account_balance,
                  title: "Transfer Bank",
                  subtitle: "BCA, BNI, Mandiri, BRI",
                  isSelected: selectedMethod == 'transfer',
                  onTap: () => setModalState(() => selectedMethod = 'transfer'),
                ),
                _buildPaymentOption(
                  icon: Icons.local_shipping,
                  title: "Cash on Delivery (COD)",
                  subtitle: "Bayar saat barang sampai",
                  isSelected: selectedMethod == 'cod',
                  onTap: () => setModalState(() => selectedMethod = 'cod'),
                ),
                _buildPaymentOption(
                  icon: Icons.wallet,
                  title: "E-Wallet",
                  subtitle: "GoPay, OVO, Dana, ShopeePay",
                  isSelected: selectedMethod == 'ewallet',
                  onTap: () => setModalState(() => selectedMethod = 'ewallet'),
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Order Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Item:", style: TextStyle(color: Colors.grey)),
                    Text("${cart.itemCount} item"),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Pembayaran:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(cart.formattedTotal, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 18)),
                  ],
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: selectedMethod != null ? () {
                      Navigator.pop(ctx);
                      _showConfirmationDialog(context, cart, selectedMethod!);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text("Lanjutkan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? Colors.blueAccent : Colors.grey.shade300, width: isSelected ? 2 : 1),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
        title: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
        onTap: onTap,
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, CartProvider cart, String method) {
    String methodName = method == 'transfer' ? 'Transfer Bank' : method == 'cod' ? 'COD' : 'E-Wallet';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Pesanan"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Metode: $methodName"),
            const SizedBox(height: 10),
            Text("Total: ${cart.formattedTotal}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            const Text("Pesanan Anda akan segera diproses."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () {
              cart.clearCart();
              Navigator.pop(ctx);
              Navigator.pop(context); // Back to landing
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(child: Text("Pesanan berhasil dibuat via $methodName!")),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}