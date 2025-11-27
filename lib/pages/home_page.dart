// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/location_service.dart';
import '../services/air_services.dart';
import '../models/air_quality.dart';
import '../widgets/info_card.dart';
import '../widgets/converter_card.dart';
import '../services/notification_service.dart';
import '../services/secure_store.dart';
import 'login_page.dart';
import '../pages/toko.dart';
import '../pages/navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LocationService _lokasi = LocationService();
  final AirService _udara = AirService();

  AirQuality? _dataAqi;
  bool _sedangMemuat = true;
  String? _pesanError;

  final TextEditingController _cariKota = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ambilDenganLokasi();
  }

  // =======================
  // Ambil data berdasar lokasi GPS
  // =======================
  Future<void> _ambilDenganLokasi() async {
    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    try {
      final posisi = await _lokasi.getCurrentPosition();
      final json = await _udara.fetchNearestCity(
        lat: posisi.latitude,
        lon: posisi.longitude,
      );

      _dataAqi = AirQuality.fromJson(json);

      // Jika udara berbahaya, kirim notifikasi dengan waktu
      if (_dataAqi!.aqi > 20) {
        await NotificationService.showNotification(
          title: '⚠️ Peringatan Polusi!',
          body: 'AQI ${_dataAqi!.aqi} — Hindari keluar rumah!',
          aqi: _dataAqi!.aqi,
        );
      }

      // Jika udara tidak sehat, tampilkan toko
      if (_dataAqi!.aqi >= 110) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _tampilkanDialogAqi(_dataAqi!.aqi);
        });
      }
    } catch (e) {
      _pesanError = e.toString();
    } finally {
      setState(() => _sedangMemuat = false);
    }
  }

  // =======================
  // Ambil data berdasar nama kota (manual search)
  // =======================
  Future<void> _ambilBerdasarkanKota(String kota) async {
    if (kota.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    try {
      final json = await _udara.fetchByCity(kota);
      _dataAqi = AirQuality.fromJson(json);
    } catch (e) {
      _pesanError = "Gagal menemukan data untuk kota '$kota'";
    } finally {
      setState(() => _sedangMemuat = false);
    }
  }

  // =======================
  // Warna & status AQI
  // =======================
  Color _warnaAqi(int aqi) {
    if (aqi <= 50) return const Color(0xFF2BB5A3);
    if (aqi <= 100) return Colors.amber;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }

  String _statusAqi(int aqi) {
    if (aqi <= 50) return 'Udara Baik 🌿 – Aman';
    if (aqi <= 100) return 'Sedang 😐 – Waspada';
    if (aqi <= 150) return 'Tidak Sehat 😷 – Kurangi aktivitas luar';
    if (aqi <= 200) return 'Buruk 😫 – Gunakan masker';
    return 'Sangat Berbahaya ☠️ – Hindari keluar rumah';
  }

  // =======================
  // Logout
  // =======================
  Future<void> _logout() async {
    await SecureStore.delete('session_user');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  // =======================
  // Dialog konfirmasi logout
  // =======================
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi Logout"),
          content: const Text("Apakah Anda yakin ingin keluar dari akun ini?"),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _logout(); // Lanjutkan logout
              },
            ),
          ],
        );
      },
    );
  }

  // =======================
  // Dialog peringatan
  // =======================
  void _tampilkanDialogAqi(int aqi) {
    final status = _statusAqi(aqi);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF9FCFB),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Peringatan Kualitas Udara!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF00796B),
          ),
        ),
        content: Text(
          'Kualitas udara sedang buruk.\n\n'
          '$status\n\n'
          'Gunakan masker dan konsumsi suplemen untuk menjaga daya tahan tubuh.',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2BB5A3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Cari state Navbar terdekat dan pindah tab ke Toko (indeks 1)
              context.findAncestorStateOfType<NavbarState>()?.onItemTapped(1);
            },
            icon: const Icon(Icons.store_mall_directory_outlined),
            label: const Text('Kunjungi Toko'),
          ),
        ],
      ),
    );
  }

  // =======================
  // UI
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFB),
      body: _sedangMemuat
          ? Center(child: Lottie.asset('assets/loading.json', width: 140))
          : _pesanError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _pesanError!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header dan Tombol Logout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ParuGuard',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: _showLogoutConfirmation,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        tooltip: "Logout",
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // =======================
                  // Pencarian cepat di Home
                  // =======================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _cariKota,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) => _ambilBerdasarkanKota(value),
                      decoration: InputDecoration(
                        hintText: "Cari kota (contoh: Jakarta, Tokyo, London)",
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () =>
                              _ambilBerdasarkanKota(_cariKota.text),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // =======================
                  // Tampilan hasil AQI
                  // =======================
                  Lottie.asset('assets/breathing_exercise.json', width: 180),
                  const SizedBox(height: 8),
                  Text(
                    '${_dataAqi!.city}, ${_dataAqi!.state}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A3C40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InfoCard(
                    aqi: _dataAqi!.aqi,
                    status: _statusAqi(_dataAqi!.aqi),
                    color: _warnaAqi(_dataAqi!.aqi),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _ambilDenganLokasi,
                        icon: const Icon(Icons.my_location),
                        label: const Text("Lokasi Saya"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
