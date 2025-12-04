// lib/pages/detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/produk_model.dart';

class DetailPage extends StatelessWidget {
  final ProdukModel produk;
  const DetailPage({super.key, required this.produk});

  String conv(int harga) {
    if (GlobalCurrency.selected == "IDR") {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(harga);
    }

    final h = harga * GlobalCurrency.rate;

    switch (GlobalCurrency.selected) {
      case "USD":
        return "\$${h.toStringAsFixed(2)}";
      case "EUR":
        return "€${h.toStringAsFixed(2)}";
      case "JPY":
        return "¥${h.toStringAsFixed(0)}";
      case "SGD":
        return "S\$${h.toStringAsFixed(2)}";
      default:
        return "${h.toStringAsFixed(2)} ${GlobalCurrency.selected}";
    }
  }

  Future<void> _bukaLink(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka link: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFB),
      appBar: AppBar(
        title: Text(produk.nama),
        backgroundColor: const Color(0xFF2BB5A3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                produk.foto,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),

            // Nama produk
            Text(
              produk.nama,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Harga (terkonversi)
            Text(
              conv(produk.harga),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),

            // Deskripsi
            Text(
              produk.deskripsi,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),

            // Tombol beli
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2BB5A3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _bukaLink(produk.link, context),
                child: const Text(
                  "Beli Sekarang",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
