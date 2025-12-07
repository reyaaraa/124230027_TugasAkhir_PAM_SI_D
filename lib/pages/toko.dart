// lib/pages/toko.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/produk_model.dart';
import '../services/currency_service.dart';
import 'detail_page.dart';

class TokoPage extends StatefulWidget {
  const TokoPage({super.key});

  @override
  State<TokoPage> createState() => _TokoPageState();
}

class _TokoPageState extends State<TokoPage> {
  final List<String> currencies = ['IDR', 'USD', 'EUR', 'JPY', 'SGD'];
  final CurrencyService api = CurrencyService(apiMode: true);

  bool loading = false;

  Future<void> changeCurrency(String newCur) async {
    setState(() => loading = true);
    try {
      if (newCur == "IDR") {
        GlobalCurrency.selected = "IDR";
        GlobalCurrency.rate = 1.0;
      } else {
        final r = await api.convert("IDR", newCur, 1.0);
        GlobalCurrency.selected = newCur;
        GlobalCurrency.rate = r;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil kurs: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFB),
      appBar: AppBar(
        title: Text("Toko", style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF2BB5A3),
        centerTitle: true,
        actions: [
          loading
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: GlobalCurrency.selected,
                    dropdownColor: Colors.white,
                    items: currencies
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      if (v == GlobalCurrency.selected) return;
                      changeCurrency(v);
                    },
                    iconEnabledColor: Colors.white,
                  ),
                ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: daftarProduk.length,
        itemBuilder: (context, i) {
          final p = daftarProduk[i];

          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailPage(produk: p)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        p.foto,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nama,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.deskripsi,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                conv(p.harga),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    openExternalLink(p.link, context),
                                icon: const Icon(Icons.shopping_cart_outlined),
                                label: const Text('Beli'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  backgroundColor: const Color(0xFF2BB5A3),
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
        },
      ),
    );
  }
}
