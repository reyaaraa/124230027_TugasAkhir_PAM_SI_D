import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

// =============================
// MODEL
// =============================
class ProdukModel {
  final String kategori;
  final String nama;
  final String deskripsi;
  final String foto; // path dari assets/images
  final int harga; // dalam Rupiah
  final String link; // link ke Shopee atau marketplace lain

  ProdukModel({
    required this.kategori,
    required this.nama,
    required this.deskripsi,
    required this.foto,
    required this.harga,
    required this.link,
  });
}

// =============================
// DAFTAR PRODUK (dummy)
// =============================
final List<ProdukModel> daftarProduk = [
  ProdukModel(
    kategori: 'Masker',
    nama: 'Masker N95 Premium',
    deskripsi:
        'Masker N95 dengan 5 lapisan filter untuk perlindungan maksimal terhadap polusi udara dan debu halus.',
    foto: 'assets/images/masker_n95.jpeg',
    harga: 25000,
    link: 'https://shopee.co.id/search?keyword=masker%20n95',
  ),
  ProdukModel(
    kategori: 'Masker',
    nama: 'Masker KF94 Putih',
    deskripsi:
        'Masker dengan desain 3D yang nyaman digunakan dan mampu menyaring partikel mikro dengan efisiensi tinggi.',
    foto: 'assets/images/masker_kf94.jpg',
    harga: 20000,
    link: 'https://shopee.co.id/search?keyword=masker%20kf94',
  ),
  ProdukModel(
    kategori: 'Obat-obatan',
    nama: 'Inhaler Herbal Mint',
    deskripsi:
        'Inhaler dengan kandungan mint alami untuk membantu melegakan hidung tersumbat dan menyegarkan pernapasan.',
    foto: 'assets/images/inhaler_herbal.jpg',
    harga: 30000,
    link: 'https://shopee.co.id/search?keyword=inhaler%20herbal',
  ),
  ProdukModel(
    kategori: 'Obat-obatan',
    nama: 'Obat Batuk Herbal Jahe',
    deskripsi:
        'Obat batuk cair dengan ekstrak jahe dan madu yang membantu meredakan batuk serta menghangatkan tenggorokan.',
    foto: 'assets/images/obat_batuk.png',
    harga: 35000,
    link: 'https://shopee.co.id/search?keyword=obat%20batuk%20herbal',
  ),
  ProdukModel(
    kategori: 'Suplemen',
    nama: 'Vitamin C 1000mg',
    deskripsi:
        'Suplemen vitamin C dosis tinggi untuk menjaga daya tahan tubuh, terutama di kondisi udara buruk.',
    foto: 'assets/images/vitamin_c.jpeg',
    harga: 50000,
    link: 'https://shopee.co.id/search?keyword=vitamin%20c%201000mg',
  ),
  ProdukModel(
    kategori: 'Suplemen',
    nama: 'Madu Murni 250ml',
    deskripsi:
        'Madu alami kaya enzim dan mineral yang membantu meningkatkan stamina dan menjaga kesehatan paru-paru.',
    foto: 'assets/images/madu.png',
    harga: 60000,
    link: 'https://shopee.co.id/search?keyword=madu%20murni',
  ),
];

// =============================
// APLIKASI UTAMA
// =============================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Contoh',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const ProductListPage(),
    );
  }
}

// =============================
// HALAMAN LIST PRODUK
// =============================
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Produk')),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: daftarProduk.length,
        itemBuilder: (context, index) {
          final produk = daftarProduk[index];
          return ProductCard(produk: produk);
        },
      ),
    );
  }
}

// =============================
// KARTU PRODUK
// =============================
class ProductCard extends StatelessWidget {
  final ProdukModel produk;
  const ProductCard({required this.produk, super.key});

  String formatRupiah(int value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Future<void> _bukaLink(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // fallback: tampilkan snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // buka detail
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(produk: produk),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Gambar produk (assets)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    produk.foto,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Info produk
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      produk.deskripsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatRupiah(produk.harga),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () => _bukaLink(produk.link, context),
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: const Text('Beli di Shopee'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================
// HALAMAN DETAIL PRODUK
// =============================
class ProductDetailPage extends StatelessWidget {
  final ProdukModel produk;
  const ProductDetailPage({required this.produk, super.key});

  String formatRupiah(int value) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  Future<void> _bukaLink(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(produk.nama)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // gambar besar
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    produk.foto,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 220,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 48),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                produk.kategori.toUpperCase(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Text(
                produk.nama,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatRupiah(produk.harga),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(produk.deskripsi, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _bukaLink(produk.link, context),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Beli di Shopee'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
