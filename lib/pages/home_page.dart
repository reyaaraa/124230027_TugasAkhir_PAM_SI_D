// lib/pages/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';

import '../services/air_services.dart';
import '../models/air_quality.dart';
import '../widgets/info_card.dart';
import '../services/notification_service.dart';
import '../services/secure_store.dart';
import 'login_page.dart';
import '../pages/navbar.dart';
import 'about_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  void dispose() {
    _cariKota.dispose();
    super.dispose();
  }

  // =======================
  // Ambil data berdasar lokasi GPS (menggunakan Geolocator)
  // =======================
  Future<void> _ambilDenganLokasi() async {
    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    try {
      // 1) Pastikan service lokasi aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Layanan lokasi (GPS) tidak aktif. Silakan aktifkan GPS dan coba lagi.',
        );
      }

      // 2) Cek & minta permission lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Izin lokasi ditolak. Mohon izinkan lokasi agar aplikasi bekerja.',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Buka pengaturan aplikasi untuk mengaktifkan izin lokasi.',
        );
      }

      // 3) Ambil posisi dengan timeout agar tidak menggantung
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 12),
      );

      // 4) Panggil API AirVisual berdasarkan koordinat
      final json = await _udara.fetchNearestCity(
        lat: pos.latitude,
        lon: pos.longitude,
      );

      // 5) Parse dan update UI (validasi sebelum parse)
      if (json == null || json.isEmpty) {
        throw Exception('Response dari server kosong.');
      }

      _dataAqi = AirQuality.fromJson(json);

      // 6) Notifikasi jika perlu
      if (_dataAqi != null && _dataAqi!.aqi > 20) {
        await NotificationService.showNotification(
          title: '⚠️ Peringatan Polusi!',
          body: 'AQI ${_dataAqi!.aqi} — Hindari keluar rumah!',
          aqi: _dataAqi!.aqi,
        );
      }

      // 7) Jika sangat tidak sehat, tampilkan dialog & arahkan ke toko
      if (_dataAqi != null && _dataAqi!.aqi >= 110) {
        Future.delayed(const Duration(milliseconds: 600), () {
          _tampilkanDialogAqi(_dataAqi!.aqi);
        });
      }
    } on TimeoutException {
      _pesanError =
          'Timeout: gagal mengambil lokasi atau data AQI. Periksa koneksi dan coba lagi.';
    } on Exception catch (e) {
      final raw = e.toString();
      if (raw.toLowerCase().contains('permission') ||
          raw.toLowerCase().contains('izin')) {
        _pesanError =
            'Izin lokasi diperlukan. Buka pengaturan aplikasi dan aktifkan izin lokasi.';
      } else if (raw.toLowerCase().contains('gps') ||
          raw.toLowerCase().contains('lokasi')) {
        _pesanError = raw; // pesan layanan lokasi nonaktif
      } else if (raw.toLowerCase().contains('socket') ||
          raw.toLowerCase().contains('koneksi')) {
        _pesanError = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      } else {
        _pesanError =
            'Gagal mengambil data: ${raw.replaceAll("Exception:", "").trim()}';
      }
    } catch (e) {
      _pesanError = 'Terjadi kesalahan: $e';
    } finally {
      if (mounted) setState(() => _sedangMemuat = false);
    }
  }

  // =======================
  // Ambil data berdasar nama kota (manual search)
  // =======================
  Future<void> _ambilBerdasarkanKota(String kota) async {
    kota = kota.trim();
    if (kota.isEmpty) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _sedangMemuat = true;
      _pesanError = null;
    });

    try {
      final json = await _udara.fetchByCity(kota);

      if (json == null || json.isEmpty) {
        throw Exception("Tidak ada data dari server untuk kota '$kota'.");
      }

      _dataAqi = AirQuality.fromJson(json);
    } on TimeoutException {
      _pesanError = 'Timeout saat mengambil data. Periksa koneksi.';
    } on Exception catch (e) {
      final raw = e.toString();
      if (raw.toLowerCase().contains('socket') ||
          raw.toLowerCase().contains('koneksi')) {
        _pesanError = 'Tidak ada koneksi internet. Periksa jaringan Anda.';
      } else if (raw.toLowerCase().contains('tidak ditemukan') ||
          raw.toLowerCase().contains('kota')) {
        _pesanError = "Gagal menemukan data untuk kota '$kota'";
      } else {
        _pesanError = raw.replaceAll('Exception:', '').trim();
      }
    } catch (e) {
      _pesanError = 'Terjadi kesalahan: $e';
    } finally {
      if (mounted) setState(() => _sedangMemuat = false);
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _pesanError!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _ambilDenganLokasi,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _dataAqi == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Belum ada data. Silakan cari kota atau gunakan lokasi.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _ambilDenganLokasi,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Ambil Lokasi Saya'),
                  ),
                ],
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
                        hintText: "Cari kota (contoh: Jakarta, Pekanbaru, dll)",
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
