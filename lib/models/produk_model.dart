// lib/models/produk_model.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// ===== GLOBAL CURRENCY STATE (global kecil, disimpan di sini) =====
class GlobalCurrency {
  /// code like 'IDR', 'USD', etc.
  static String selected = 'IDR';

  /// multiplier: 1 IDR -> rate in selected currency (default 1.0)
  static double rate = 1.0;
}

/// MODEL
class ProdukModel {
  final String kategori;
  final String nama;
  final String deskripsi;
  final String foto; // path ke assets/images/...
  final int harga;
  final String link;

  ProdukModel({
    required this.kategori,
    required this.nama,
    required this.deskripsi,
    required this.foto,
    required this.harga,
    required this.link,
  });
}

// DAFTAR PRODUK (dummy)
final List<ProdukModel> daftarProduk = [
  ProdukModel(
    kategori: 'Masker',
    nama: 'Masker N95 Premium',
    deskripsi:
        'Masker N95 dengan 5 lapisan filter untuk perlindungan maksimal terhadap polusi udara dan debu halus.',
    foto: 'assets/images/masker_n95.jpeg',
    harga: 25000,
    link: 'https://www.tokopedia.com/search?st=product&q=masker%20n95',
  ),
  ProdukModel(
    kategori: 'Masker',
    nama: 'Masker KF94 Putih',
    deskripsi:
        'Masker 3D yang nyaman digunakan dan efektif menyaring partikel mikro.',
    foto: 'assets/images/masker_kf94.jpg',
    harga: 20000,
    link: 'https://www.tokopedia.com/search?st=product&q=masker%20kf94',
  ),
  ProdukModel(
    kategori: 'Obat-obatan',
    nama: 'Inhaler Herbal Mint',
    deskripsi: 'Inhaler dengan aroma mint segar untuk melegakan pernapasan.',
    foto: 'assets/images/inhaler_herbal.jpg',
    harga: 30000,
    link:
        'https://www.tokopedia.com/search?st=product&q=inhaler%20herbal%20mint',
  ),
  ProdukModel(
    kategori: 'Obat-obatan',
    nama: 'Obat Batuk Herbal Jahe',
    deskripsi: 'Obat batuk herbal dengan kandungan jahe & madu.',
    foto: 'assets/images/obat_batuk.png',
    harga: 35000,
    link:
        'https://www.tokopedia.com/search?st=product&q=obat%20batuk%20herbal%20jahe',
  ),
  ProdukModel(
    kategori: 'Suplemen',
    nama: 'Vitamin C 1000mg',
    deskripsi: 'Vitamin C dosis tinggi untuk daya tahan tubuh.',
    foto: 'assets/images/vitamin_c.jpeg',
    harga: 50000,
    link: 'https://www.tokopedia.com/search?st=product&q=vitamin%20c%201000mg',
  ),
  ProdukModel(
    kategori: 'Suplemen',
    nama: 'Madu Murni 250ml',
    deskripsi: 'Madu alami yang baik untuk imunitas & kesehatan paru.',
    foto: 'assets/images/madu.png',
    harga: 60000,
    link: 'https://www.tokopedia.com/search?st=product&q=madu%20murni',
  ),
];

// Helper: buka link external (robust)
Future<void> openExternalLink(String rawUrl, BuildContext context) async {
  try {
    if (rawUrl.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link kosong.')));
      return;
    }
    Uri? uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || uri.scheme.isEmpty) {
      uri = Uri.tryParse('https://${rawUrl.trim()}');
    }
    if (uri == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('URL tidak valid.')));
      return;
    }

    if (await canLaunchUrl(uri)) {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } else {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error membuka link: $e')));
  }
}
